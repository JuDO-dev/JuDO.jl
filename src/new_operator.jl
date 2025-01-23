macro independent(model, args...)
    expr_of_args = collect(args)
    # separate the situation of initial/final value and trajectory bound
    if length(expr_of_args) == 1
        var_ref = :(add_independent($(esc(model)),$(expr_of_args)))
        sym,val = check_inde_var_input(args[1])   
        return macro_return(sym,var_ref)

    elseif length(expr_of_args) >= 2
        var_ref = :(add_independent($(esc(model)),$([expr_of_args[1]]),$(expr_of_args[2:end])))
        sym,val = check_inde_var_input(args[1])  
        return macro_return(sym,var_ref)

    else
        throw(error("Incorrect input style"))
    end

end

abstract type AbstractDynamicRef end
mutable struct IndependentRef <: AbstractDynamicRef
    model::Abstract_Dynamic_Model
end

function one_side_inde(_expr)
    operator = _expr.args[1]
    left_val = _expr.args[2]
    right_val = _expr.args[3]

    #check the operator is >= or <=, otherwise throw error
    (operator == :>= || operator == :<= || operator == :(==)) ? nothing : throw(error("The operator is not recognized"))

    if operator == :(==)
        return left_val,eval(right_val)

    elseif left_val isa Symbol
        operator == :>= ? (return left_val,[eval(right_val),Inf]) : (return left_val,[-Inf,eval(right_val)])

    elseif right_val isa Symbol
        operator == :>= ? (return right_val,[-Inf,eval(left_val)]) : (return right_val,[eval(left_val),Inf])

    else
        throw(error("No independent variable as a symbol is found"))
    end
end

function two_sides_inde(_expr)
    operator = [_expr.args[2],_expr.args[4]]
    left_val = _expr.args[1]
    right_val = _expr.args[5]
    name = _expr.args[3]

    name isa Symbol ? nothing : throw(error("The independent variable is not a symbol"))

    operator[1] == :<= && (operator[1] == operator[2]) ? nothing : throw(error("Incorrect use of the operator"))

    return name,[eval(left_val),eval(right_val)]
end

# add new or add exist independent variable
function check_inde_var_input(_raw_expr)

    _raw_expr isa Symbol ? (return _raw_expr,[-Inf,Inf]) : nothing

    if _raw_expr.head == :call && length(_raw_expr.args) == 3
        name,val = one_side_inde(_raw_expr)

    elseif _raw_expr.head == :comparison && length(_raw_expr.args) == 5
        name,val = two_sides_inde(_raw_expr)

    else
        error("The input of the independent variable is not in the correct format")
    end

    return name,val
end

function add_independent(_model,_expr)
    #length(_model.Independent_var_index) == 0 ? nothing : multiple_independent_var_error()

    sym,bound = check_inde_var_input(_expr[1])

    #same_var_error(_model,sym)
    #bound_lower_upper(bound)
    indep_var_data = Independent_Var_data(sym,bound)
    #_model.Independent_var_index[indep_var_data.Sym] = indep_var_data

    return indep_var_data#add_inde_variable(_model,bound,:Trajectory)

end

#define optimizer in DynOptInterface, add indep_var_data to the optimizer struct  

function add_inde_variable(_model,_val,type)
    DOI.add_variable(_model.optimizer.inde_variables,_val)
 
    variable_ref = IndependentRef(_model)
    return variable_ref
end

function macro_return(sym,ref)
    return :($(esc(sym)) = $ref;)
end