function new_info_algebraic(_model,_args)
    _args[1] isa Symbol ? throw(error("Make sure to include the independent variable in paranthesis")) : nothing
    sym,val = check_alge_var_input(_args[1])

    info = [sym]
    if length(_args) == 1
        return add_new_algebraic(_model,info,val)
    elseif length(_args) in [2,3]
        [push!(info,_args[i]) for i in 2:length(_args)]
        return add_new_algebraic(_model,info,val)
    else
        throw(error("Incorrect use of the keyword argument"))
    end
end

##############################################################################################################

function kw_at_rhs(left,right,sym,_kw_collection)

    if sym == :>=
        (right in _kw_collection) && (eval(left) isa Real) ? (_val = [-Inf,eval(left)]) : error("The keyword provided is not in the collection")
    else
        (right in _kw_collection) && (eval(left) isa Real) ? (_val = [eval(left),Inf]) : error("The keyword provided is not in the collection")
    end
        
    return _val,right
end

function kw_at_lhs(left,right,sym,_kw_collection)

    if sym == :>=
        left in _kw_collection ? (_val = [eval(right),Inf]) : error("The keyword provided is not in the collection")
    else
        left in _kw_collection ? (_val = [-Inf,eval(right)]) : error("The keyword provided is not in the collection")
    end
        
    return _val,left
end

function one_side_diff(_expr)
    kw_collection = [:Initial_bound,:Final_bound,:Trajectory_bound]
    operator = _expr.args[1]
    left_val = _expr.args[2]
    right_val = _expr.args[3]

    #check the operator is >= or <=, otherwise throw error
    (operator == :>= || operator == :<=) ? nothing : error("The operator is not >= or <=")

    #add eval to the element? for dealing with [a,10] and a is previously defined
    left_val in kw_collection ? ((val,name) = kw_at_lhs(left_val,right_val,operator,kw_collection)) : ((val,name) = kw_at_rhs(left_val,right_val,operator,kw_collection))
    
    return name,val
end

function two_sides_diff(_expr)
    kw_collection = [:Initial_bound,:Final_bound,:Trajectory_bound]
    operator = [ _expr.args[2],_expr.args[4]]
    left_val = _expr.args[1]
    right_val = _expr.args[5]
    kw = _expr.args[3]

    #check the operator is >= or <=, otherwise throw error
    operator[1] == :<= && (operator[1] == operator[2]) ? nothing : error("Incorrect use of the operator")

    #add eval to the element? for dealing with [a,10] and a is previously defined
    kw in kw_collection ? ((val,name) = ([left_val,right_val],kw)) : error("The keyword provided is not in the collection")

    return name,val
end

function equality(_expr)
    kw_collection = [:Initial_guess,:Interpolant]
    left_val = _expr.args[1]
    right_val = _expr.args[2]

    left_val in kw_collection ? ((val,name) = (right_val,left_val)) : error("The keyword provided is not in the collection")
    
    return name,val
end

function decide_bound(__model,__sym,_i,__val,_add_new)
    println("now deciding the bound...")
    __val[1] > __val[2] ? error("The lower bound is larger than the upper bound") : nothing
    if _add_new 
         println("adding new var, with new bound...")
        return __val
    end

    exist_field = getfield(__model.Differential_var_index[__sym],_i+1)
    #add exist, but the field is empty, so add as normal
    exist_field == [[-Inf,Inf]] ? (return [__val]) : nothing

    #add exist, but the field is not empty, so check the relation of the new value and the existing value
    #throw error if the new bound is not compatible with the existing bound
    for i in eachindex(exist_field)
        __val[1] > exist_field[i][2] || __val[2] < exist_field[i][1] ? error("The new bound is not compatible with the existing bound") : nothing

        #give user a choice to decide whether to add the new bound or not, based on whether the new bound is inside the existing bound
        if __val[1] >= exist_field[i][1] && __val[2] <= exist_field[i][2]
            @warn ("The new bound $__val is inside one of the existing bounds $(exist_field[i]), do you want to add it? (y/n)")

        end
    end

    return push!(exist_field,__val)
end

# check the input style of the differential variables, return the keyword and value for both '=' and 'in' style
function check_diff_var_input(_raw_expr)

    names_vals=[]

    for i in eachindex(_raw_expr) 
        if _raw_expr[i].head == :call && length(_raw_expr[i].args) == 3 
            name,val = one_side_diff(_raw_expr[i])
            push!( names_vals,name,val)

        elseif _raw_expr[i].head == :comparison && length(_raw_expr[i].args) == 5
            name,val = two_sides_diff(_raw_expr[i])
            push!( names_vals,name,val)

        elseif _raw_expr[i].head == :(=) && length(_raw_expr[i].args) == 2
            name,val = equality(_raw_expr[i])
            push!( names_vals,name,val)

        else
            error("The input of the differential variable is not in the correct format")
        end

    end

    return names_vals
end

# identify the keyword in the user input and its value
function identify_kw(__model,__sym,_kws,_vals,add_new=true)
    kw_collection = [:Initial_guess,:Initial_bound,:Final_bound,:Trajectory_bound,:Interpolant]
    default_info = [nothing, [-Inf,Inf], [-Inf,Inf],[-Inf,Inf],nothing]

    #return the indices of user-input keywords in kw_collection
    index_matches=[]
    [push!(index_matches,findfirst(isequal(_kws[i]),kw_collection)) for i in eachindex(_kws)]

    full_info=[]
    for i in eachindex(kw_collection)
        
        if i in index_matches
            (i == 1) || (i == 5) ? push!(full_info,_vals[index_matches .== i][1]) : push!(full_info,decide_bound(__model,__sym,i,_vals[index_matches .== i][1],add_new))
            #push!(full_info,_vals[index_matches .== i][1]) 
        else
            add_new ? push!(full_info,default_info[i]) : push!(full_info,getfield(__model.Differential_var_index[__sym],i+1))
        end
         
    end
    
    return full_info

end

#called when the user is specifying information about the differential variable
function construct_diff_info(_model,_sym,_args)
    kw_val_vect = check_diff_var_input(_args)
    kws = kw_val_vect[1:2:end]
    vals = kw_val_vect[2:2:end]

    var_info = identify_kw(_model,_sym,kws,vals)
    pushfirst!(var_info,_sym)

    return var_info
end

function add_new_vector(_model,_args)
    diff_var_data = Differential_Var_data(_args[1],_args[2],_args[3],_args[4],_args[5],_args[6])
    _model.Differential_var_index[diff_var_data.Run_sym] = diff_var_data

    return add_diff_variable(_model,diff_var_data)
end

#called when the user is not specifying any information about the differential variable
function add_new(_model,_args,extra_args=false)
    _args[1] isa Symbol ? throw(error("The differential variable is not a symbol")) : nothing
    (_args[1].args[2] == collect(keys(_model.Independent_var_index))[1]) ? nothing : throw(error("The independent variable is not defined yet"))

    ## to do
    same_var_error(_model,_args[1].args[1])

    if extra_args == false
        diff_var_data = Differential_Var_data(_args[1],nothing,[[-Inf,Inf]],[[-Inf,Inf]],[[-Inf,Inf]],nothing)
    else
        var_info = construct_diff_info(_model,_args[1],_args[2:end])

        diff_var_data = Differential_Var_data(var_info[1],var_info[2],[var_info[3]],[var_info[4]],[var_info[5]],var_info[6])
    end

    _model.Differential_var_index[diff_var_data.Run_sym] = diff_var_data

    return add_diff_variable(_model,diff_var_data)

end

##############################################################################################################
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
#t, 0<=t<=10
function add_independent(_model,_expr)
    length(_model.Independent_var_index) == 0 ? nothing : multiple_independent_var_error()

    sym,bound = check_inde_var_input(_expr[1])

    i = _model.Initial_Independent_var_index
    f = _model.Final_Independent_var_index
    if length(i) != 0
        if bound[1] != collect(values(i))[1]
            throw(error("The initial value is not consistent with the initial value in the initial condition"))
        end
    end
    if length(f) != 0
        if bound[2] != collect(values(f))[1]
            throw(error("The final value is not consistent with the final value in the final condition"))
        end
    end

    same_var_error(_model,sym)
    bound_lower_upper(bound)
    indep_var_data = Independent_Var_data(sym,bound)
    _model.Independent_var_index[indep_var_data.Sym] = indep_var_data

    return add_inde_variable(_model,bound,:Trajectory)

end

#called when the user is not specifying any information about a new differential variable
function add_independent(_model,_expr,kw)

    if (kw[1] isa Expr) && (kw[1].head == :(=)) && (length(kw[1].args) == 2)
        if kw[1].args[1] == :type
            kw[1].args[2] == :initial ? (type = :Initial) : (type = :Final)
        else
            throw(error("Incorrect input style of the independent variable"))
        end
    else
        throw(error("Incorrect input style of the independent variable"))
    end

    if type == :Initial 
        length(_model.Initial_Independent_var_index) == 0 ? nothing : multiple_independent_var_error()
    elseif type == :Final
        length(_model.Final_Independent_var_index) == 0 ? nothing : multiple_independent_var_error()
    end

    t = _model.Independent_var_index
    if (_expr[1] isa Expr) && (_expr[1].head == :(=)) && (length(_expr[1].args) == 2) && (_expr[1].args[2] isa Number)
        sym = _expr[1].args[1]
        val = _expr[1].args[2]
        same_var_error(_model,sym)

        if (length(t) != 0) && (type == :Initial) 
            if (val != collect(values(t))[1].Bound[1]) && (collect(values(t))[1].Bound[1] != -Inf)
                throw(error("The value is not consistent with the value in the trajectory"))
            end
            _model.Initial_Independent_var_index[sym] = val
            return IndependendRef(_model,:Initial)

        elseif (length(t) != 0) && (type == :Final)
            if (val != collect(values(t))[1].Bound[2]) && (collect(values(t))[1].Bound[2] != Inf)
                throw(error("The value is not consistent with the value in the trajectory"))
            end
            _model.Final_Independent_var_index[sym] = val
            return IndependendRef(_model,:Final)
        end
        
    elseif _expr[1] isa Symbol
        sym = _expr[1]
        same_var_error(_model,sym)
        if type == :Initial 
            _model.Initial_Independent_var_index[sym] = nothing
            return IndependendRef(_model,:Initial)
        elseif type == :Final
            _model.Final_Independent_var_index[sym] = nothing
            return IndependendRef(_model,:Final)
        end
    else
        throw(error("Incorrect input style of the independent variable"))
    end

end

##############################################################################################################
function one_side_alge(_expr)
    operator = _expr.args[1]
    left_val = _expr.args[2]
    right_val = _expr.args[3]

    #check the operator is >= or <=, otherwise throw error
    (operator == :>= || operator == :<= || operator == :(==)) ? nothing : throw(error("The operator is not recognized"))

    if operator == :(==)
        return left_val,eval(right_val)

    elseif left_val isa Expr
        operator == :>= ? (return left_val,[eval(right_val),Inf]) : (return left_val,[-Inf,eval(right_val)])

    elseif right_val isa Expr
        operator == :>= ? (return right_val,[-Inf,eval(left_val)]) : (return right_val,[eval(left_val),Inf])

    else
        throw(error("Incorrect input style of the algebraic variable"))
    end
end

function two_sides_alge(_expr)
    operator = [_expr.args[2],_expr.args[4]]
    left_val = _expr.args[1]
    right_val = _expr.args[5]
    name = _expr.args[3]

    name isa Expr ? nothing : throw(error("Incorrect input style of the algebraic variable"))

    operator[1] == :<= && (operator[1] == operator[2]) ? nothing : throw(error("Incorrect use of the operator"))

    return name,[eval(left_val),eval(right_val)]
end

function check_alge_var_input(_raw_expr)

    if _raw_expr.head == :call && length(_raw_expr.args) == 3
       name,val = one_side_alge(_raw_expr)

    elseif _raw_expr.head == :comparison && length(_raw_expr.args) == 5
       name,val = two_sides_alge(_raw_expr)

    else
        throw(error("Incorrect input style of the algebraic variable"))
    end

    return name,val
end

function add_new_algebraic(_model,_args,bound)
    (_args[1].args[2] == collect(keys(_model.Independent_var_index))[1]) ? nothing : throw(error("The independent variable is not defined yet"))
    same_var_error(_model,_args[1].args[1])
    bound_lower_upper(bound)

    if length(_args) == 1
        alge_var_data = Algebraic_Var_data(_args[1],bound,nothing,nothing)
        _model.Algebraic_var_index[alge_var_data.Sym] = alge_var_data

        return add_alge_variable(_model,alge_var_data)

    elseif (length(_args) in [2,3]) 
        val = nothing
        guess = nothing
        println(_args)
        for i in _args[2:end]
            if (i.args[1] == :Initial_guess) && (i.args[2] isa Number) && (i isa Expr) && (i.head == :(=)) && (length(i.args) == 2) 
                guess = i.args[2]
                
            elseif (i.args[1] == :Interpolant) && (i.args[2] isa Symbol) && (i isa Expr) && (i.head == :(=)) && (length(i.args) == 2)         
                val = i.args[2]

            else
                throw(error("Incorrect input style of the algebraic variable"))
            end
        end

        alge_var_data = Algebraic_Var_data(_args[1],bound,guess,val)
        _model.Algebraic_var_index[alge_var_data.Sym] = alge_var_data

        return add_alge_variable(_model,alge_var_data)
    else
        throw(error("Incorrect input style of the algebraic variable"))
    end

end

##############################################################################################################

# an abstract type for the return value of the macros
abstract type AbstractDynamicRef end

# the type of the return value of @differential
mutable struct DifferentialRef <: AbstractDynamicRef
    model::Abstract_Dynamic_Model
    index::DOI.DifferentialVariableIndex

end

mutable struct AlgebraicRef <: AbstractDynamicRef
    model::Abstract_Dynamic_Model
    index::DOI.AlgebraicVariableIndex

end

mutable struct IndependendRef <: AbstractDynamicRef
    model::Abstract_Dynamic_Model
    type::Symbol
end

function add_inde_variable(_model,_val,type)
    DOI.add_variable(_model.optimizer.inde_variables,_val)
 
    variable_ref = IndependendRef(_model,type)
    return variable_ref
end

function add_diff_variable(_model,_diff_var_data)
    index = DOI.add_variable(_model.optimizer.diff_variables,_diff_var_data)
    
    variable_ref = DifferentialRef(_model,index)
    
    return variable_ref

end

function add_alge_variable(_model,_alge_var_data)
    index = DOI.add_variable(_model.optimizer.alge_variables,_alge_var_data)
    
    variable_ref = AlgebraicRef(_model,index)
    
    return variable_ref
    
end

##############################################################################################################

function add_initial_guess(ref::DifferentialRef,guess::Real)
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    val.Initial_guess == nothing ? (val.Initial_guess = guess) : throw(error("An initial guess already exists, please use set_initial_guess to change it"))
    ref.model.optimizer.diff_variables.init_guess[ref.index.value] = guess
    return 0
    
end

## alge var need to be modified in model and optimizer
function add_initial_guess(ref::AlgebraicRef,guess::Real)
    val = collect(values(ref.model.Algebraic_var_index))[ref.index.value]
    check_alge_bound(guess,val.Bound)

    val.Initial_guess == nothing ? (val.Initial_guess = guess) : throw(error("An initial guess already exists, please use set_initial_guess to change it"))
    ref.model.optimizer.alge_variables.init_guess[ref.index.value] = guess
    return 0 
    
end

function add_initial_bound(ref::DifferentialRef,bound::Vector)
    
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    check_contradict(val.Initial_bound,bound)
    if val.Initial_guess != nothing
        if val.Initial_guess < bound[1] || val.Initial_guess > bound[2]
            throw(error("The initial guess is not within the initial bound"))
        end
    end

    delete_default(val.Initial_bound)

    push!(val.Initial_bound,bound)
    
    ref.model.optimizer.diff_variables.init_bound[ref.index.value] = val.Initial_bound

    
    return 0#var_name
end

function add_trajectory_bound(ref::DifferentialRef,bound::Vector)

    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    check_contradict(val.Trajectory_bound,bound)
    delete_default(val.Trajectory_bound)

    push!(val.Trajectory_bound,bound)
    
    ref.model.optimizer.diff_variables.trajectory_bound[ref.index.value] = val.Trajectory_bound
    return 0#var_name
end

    
function add_trajectory_bound(ref::AlgebraicRef,bound::Vector)
        
    val = collect(values(ref.model.Algebraic_var_index))[ref.index.value]
    check_alge_bound(val.Initial_guess,bound)

    val.Bound == [-Inf,Inf] ? nothing : throw(error("A trajectory bound already exists, please use set_trajectory_bound to change it"))

    val.Bound = bound
    
    ref.model.optimizer.alge_variables.trajectory_bound[ref.index.value] = val.Bound
    return 0#var_name
end


    
function add_final_bound(ref::DifferentialRef,bound::Vector)
        
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    check_contradict(val.Final_bound,bound)
    delete_default(val.Final_bound)

    push!(val.Final_bound,bound)
    
    ref.model.optimizer.diff_variables.final_bound[ref.index.value] = val.Final_bound
    return 0

end


function add_interpolant(ref::DifferentialRef,interpolant::Symbol)
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    val.Interpolant == nothing ? (val.Interpolant = interpolant) : throw(error("An interpolant already exists, please use set_interpolant to change it"))
    ref.model.optimizer.diff_variables.interpolant[ref.index.value] = interpolant
    return 0
    
end

function add_interpolant(ref::AlgebraicRef,interpolant::Symbol)
    val = collect(values(ref.model.Algebraic_var_index))[ref.index.value]
    val.Interpolant == nothing ? (val.Interpolant = interpolant) : throw(error("An interpolant already exists, please use set_interpolant to change it"))
    ref.model.optimizer.alge_variables.interpolant[ref.index.value] = interpolant
    return 0
    
end

##############################################################################################################
function delete_default(bounds)
    #if there is [-Inf,Inf] in the final bound, then pop [-Inf,Inf] out of the bound
    if [-Inf,Inf] in bounds
        index = findfirst(isequal([-Inf,Inf]),bounds)
        popat!(bounds,index)
    end

end

function delete_independent(ref::IndependendRef)
    if ref.type == :Initial
        empty!(ref.model.Initial_Independent_var_index)

    elseif ref.type == :Final
        empty!(ref.model.Final_Independent_var_index)
    else
        empty!(ref.model.Independent_var_index)
    end
end

function delete_initial_guess(ref::DifferentialRef)
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    val.Initial_guess == nothing ? throw(error("An initial guess does not exist, please use add_initial_guess to add it")) : (val.Initial_guess = nothing)
    ref.model.optimizer.diff_variables.init_guess[ref.index.value] = nothing
    return 0
    
end

function delete_initial_guess(ref::AlgebraicRef)
    val = collect(values(ref.model.Algebraic_var_index))[ref.index.value]
    val.Initial_guess == nothing ? throw(error("An initial guess does not exist, please use add_initial_guess to add it")) : (val.Initial_guess = nothing)
    ref.model.optimizer.alge_variables.init_guess[ref.index.value] = nothing
    return 0
    
end

function delete_initial_bound(ref::DifferentialRef,place::Int64)
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    if length(val.Initial_bound) == 1 
        val.Initial_bound = [[-Inf,Inf]] 
        ref.model.optimizer.diff_variables.init_bound[ref.index.value] = val.Initial_bound
    else
        deleteat!(val.Initial_bound,place)
        ref.model.optimizer.diff_variables.init_bound[ref.index.value] = val.Initial_bound
    end
    return 0
end

function delete_trajectory_bound(ref::DifferentialRef,place::Int64)
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    if length(val.Trajectory_bound) == 1 
        val.Trajectory_bound = [[-Inf,Inf]]
        ref.model.optimizer.diff_variables.trajectory_bound[ref.index.value] = val.Trajectory_bound
    else
        deleteat!(val.Trajectory_bound,place)
        ref.model.optimizer.diff_variables.trajectory_bound[ref.index.value] = val.Trajectory_bound
    end
    return 0
end

function delete_trajectory_bound(ref::AlgebraicRef)
    val = collect(values(ref.model.Algebraic_var_index))[ref.index.value]
        val.Bound = [-Inf,Inf]

        ref.model.optimizer.alge_variables.trajectory_bound[ref.index.value] = val.Bound

    return 0
end

function delete_final_bound(ref::DifferentialRef,place::Int64)
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    if length(val.Final_bound) == 1 
        val.Final_bound = [[-Inf,Inf]] 
        ref.model.optimizer.diff_variables.final_bound[ref.index.value] = val.Final_bound
    else
        deleteat!(val.Final_bound,place)
        ref.model.optimizer.diff_variables.final_bound[ref.index.value] = val.Final_bound
    end
    return 0
end

function delete_interpolant(ref::DifferentialRef)
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    val.Interpolant == nothing ? throw(error("An interpolant does not exist, please use add_interpolant to add it")) : (val.Interpolant = nothing)
    ref.model.optimizer.diff_variables.interpolant[ref.index.value] = nothing
    return 0
    
end

function delete_interpolant(ref::AlgebraicRef)
    val = collect(values(ref.model.Algebraic_var_index))[ref.index.value]
    val.Interpolant == nothing ? throw(error("An interpolant does not exist, please use add_interpolant to add it")) : (val.Interpolant = nothing)
    ref.model.optimizer.alge_variables.interpolant[ref.index.value] = nothing
    return 0
    
end

##############################################################################################################
function set_independent(ref::IndependendRef,info)
    
    if ref.type == :Initial 
        collection_i = ref.model.Initial_Independent_var_index
        i = collect(values(collection_i))
        length(i) == 0 ? throw(error("The initial independent variable is empty, please use the macro to add the variable")) : nothing
        collection_i[collection_i.keys[1]] = info

    elseif ref.type == :Final
        collection_f = ref.model.Final_Independent_var_index
        f = collect(values(collection_f))
        length(f) == 0 ? throw(error("The final independent variable is empty, please use the macro to add the variable")) : nothing
        collection_f[collection_f.keys[1]] = info

    else
        bound_lower_upper(info)

        t = collect(values(ref.model.Independent_var_index))
        length(t) == 0 ? throw(error("The independent variable is empty, please use the macro to add the variable")) : nothing
        t[1].Bound = info

        ref.model.optimizer.inde_variables.traj_bound = info
    end
    return 0
end

function set_initial_guess(ref::DifferentialRef,guess::Real)
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    for i in eachindex(val.Initial_bound)
        guess < val.Initial_bound[i][1] || guess > val.Initial_bound[i][2] ? throw(error("The initial guess is not within the initial bound")) : nothing
    end
    
    val.Initial_guess == nothing ? throw(error("An initial guess does not exist, please use add_initial_guess to add it")) : (val.Initial_guess = guess)
    ref.model.optimizer.diff_variables.init_guess[ref.index.value] = guess
    return 0
    
end

function set_initial_guess(ref::AlgebraicRef,guess::Real)
    val = collect(values(ref.model.Algebraic_var_index))[ref.index.value]
    check_alge_bound(guess,val.Bound)

    val.Initial_guess == nothing ? throw(error("An initial guess does not exist, please use add_initial_guess to add it")) : (val.Initial_guess = guess)
    ref.model.optimizer.alge_variables.init_guess[ref.index.value] = guess
    return 0
    
end

function set_initial_bound(ref::DifferentialRef,bound::Vector,place::Int64)
        
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    check_contradict(val.Initial_bound,bound)
    length(val.Initial_bound) == 0 ? throw(error("The initial bound is empty")) : nothing

    val.Initial_bound[place] = bound
    
    ref.model.optimizer.diff_variables.init_bound[ref.index.value] = val.Initial_bound
    return 0
end

function set_trajectory_bound(ref::DifferentialRef,bound::Vector,place::Int64)
        
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    check_contradict(val.Trajectory_bound,bound)
    length(val.Trajectory_bound) == 0 ? throw(error("The trajectory bound is empty")) : nothing

    val.Trajectory_bound[place] = bound
    
    ref.model.optimizer.diff_variables.trajectory_bound[ref.index.value] = val.Trajectory_bound
    return 0
end

function set_trajectory_bound(ref::AlgebraicRef,bound::Vector)
   
    val = collect(values(ref.model.Algebraic_var_index))[ref.index.value]
    check_alge_bound(val.Initial_guess,bound)

    val.Bound = bound

    ref.model.optimizer.alge_variables.trajectory_bound[ref.index.value] = val.Bound
    return 0
end

function set_final_bound(ref::DifferentialRef,bound::Vector,place::Int64)
        
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    check_contradict(val.Final_bound,bound)
    length(val.Final_bound) == 0 ? throw(error("The final bound is empty")) : nothing

    val.Final_bound[place] = bound
    
    ref.model.optimizer.diff_variables.final_bound[ref.index.value] = val.Final_bound
    return 0
end

function set_interpolant(ref::DifferentialRef,interpolant::Symbol)
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    val.Interpolant == nothing ? throw(error("An interpolant does not exist, please use add_interpolant to add it")) : (val.Interpolant = interpolant)
    ref.model.optimizer.diff_variables.interpolant[ref.index.value] = interpolant
    return 0
    
end

function set_interpolant(ref::AlgebraicRef,interpolant::Symbol)
    val = collect(values(ref.model.Algebraic_var_index))[ref.index.value]
    val.Interpolant == nothing ? throw(error("An interpolant does not exist, please use add_interpolant to add it")) : (val.Interpolant = interpolant)
    ref.model.optimizer.alge_variables.interpolant[ref.index.value] = interpolant
    return 0
    
end

##############################################################################################################
function merge_intersect(b)
    lower_bounds = [bound[1] for bound in b]
    upper_bounds = [bound[2] for bound in b]

    intersected_bound = [maximum(lower_bounds), minimum(upper_bounds)]

    return [intersected_bound]
end

function merge_initial(ref::DifferentialRef)
    
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    length(val.Initial_bound) == 1 ? (return) : nothing
    
    val.Initial_bound = merge_intersect(val.Initial_bound)
    ref.model.optimizer.diff_variables.init_bound[ref.index.value] = val.Initial_bound
end

function merge_trajectory(ref::DifferentialRef)
    
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    length(val.Trajectory_bound) == 1 ? (return) : nothing
    
    val.Trajectory_bound = merge_intersect(val.Trajectory_bound)
    ref.model.optimizer.diff_variables.trajectory_bound[ref.index.value] = val.Trajectory_bound
end

function merge_final(ref::DifferentialRef)
    
    val = collect(values(ref.model.Differential_var_index))[ref.index.value]
    length(val.Final_bound) == 1 ? (return) : nothing
    
    val.Final_bound = merge_intersect(val.Final_bound)
    ref.model.optimizer.diff_variables.final_bound[ref.index.value] = val.Final_bound
end

##############################################################################################################
function assign_vector(_model,i,args,result,extra_args = false)
    if extra_args == false
        info = [Expr(:call,Symbol(string(args[1].args[1].args[1],"_vect_",i)),collect(keys(_model.Independent_var_index))[1]),nothing,[[-Inf,Inf]],[[-Inf,Inf]],[[-Inf,Inf]],nothing]
    else
        var_info = construct_diff_info(_model,args[1],args[2:end])
        info = [Expr(:call,Symbol(string(var_info[1].args[1].args[1],"_vect_",i)),collect(keys(_model.Independent_var_index))[1]),var_info[2],[var_info[3]],[var_info[4]],[var_info[5]],var_info[6]]
    end
    var_ref = add_new_vector(_model,info)
    return   quote push!($result,$var_ref) end
end