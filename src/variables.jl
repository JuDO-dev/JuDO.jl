function new_or_exist(_model,_sym,_args)
    haskey(_model.Differential_var_index,_sym[1]) ? (return add_exist(_model,_sym[1],_args)) : (return add_new(_model,_sym[1],_args))
end

function new_or_exist_independent(_model,_args)
    sym,val = check_inde_var_input(_args[1])
    haskey(_model.Independent_var_index,sym) ? (return add_exist_independent(_model,sym,val)) : (return add_new_independent(_model,sym,val))
end

function new_or_exist_algebraic(_model,_args)
    sym,val = check_inde_var_input(_args[1])

    haskey(_model.Algebraic_var_index,sym) ? (return add_exist_algebraic(_model,sym,val)) : (return add_new_algebraic(_model,sym,val))
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
   
    ########################################## change, since there is one more layer of brackets
    #check_initial_guess(full_info)
    
    return full_info

end

#modify an exist differential variable
function add_exist(_model,_sym,_args)
     kw_val_vect = check_diff_var_input(_args)

    #collect all elements in kw_val_vect that has a odd index
    kws = kw_val_vect[1:2:end]
    vals = kw_val_vect[2:2:end]

    var_info = identify_kw(_model,_sym,kws,vals,false)
    pushfirst!(var_info,_sym)
    
    field_names = collect(fieldnames(Differential_Var_data))

    [setfield!(_model.Differential_var_index[_sym],field_names[i],var_info[i]) for i in eachindex(field_names)]  

    return _model.Differential_var_index

end

#called when the user is specifying information about the differential variable
function add_new(_model,_sym,_args)

    kw_val_vect = check_diff_var_input(_args)
    kws = kw_val_vect[1:2:end]
    vals = kw_val_vect[2:2:end]

    var_info = identify_kw(_model,_sym,kws,vals)
     pushfirst!(var_info,_sym)

    ##changed the bounds by adding square brackets
    diff_var_data = Differential_Var_data(var_info[1],var_info[2],[var_info[3]],[var_info[4]],[var_info[5]],var_info[6])
    _model.Differential_var_index[diff_var_data.Run_sym] = diff_var_data    

    return _model.Differential_var_index
end

#called when the user is not specifying any information about the differential variable
function add_new(_model,_args)

    ## to do
    haskey(_model.Differential_var_index,_args[1]) ? error("The differential variable already exists, to reset the information, please delete and create again") : nothing

    diff_var_data = Differential_Var_data(_args[1],_args[2],_args[3],_args[4],_args[5],_args[6])
    _model.Differential_var_index[diff_var_data.Run_sym] = diff_var_data

    return _model.Differential_var_index
end

##############################################################################################################
function one_side_inde(_expr)
    operator = _expr.args[1]
    left_val = _expr.args[2]
    right_val = _expr.args[3]

    #check the operator is >= or <=, otherwise throw error
    (operator == :>= || operator == :<=) ? nothing : error("The operator is not >= or <=")

    if left_val isa Symbol
        operator == :>= ? (return left_val,[eval(right_val),Inf]) : (return left_val,[-Inf,eval(right_val)])

    elseif right_val isa Symbol
        operator == :>= ? (return right_val,[-Inf,eval(left_val)]) : (return right_val,[eval(left_val),Inf])

    else
        error("No independent variable as a symbol is found")
    end
end

function two_sides_inde(_expr)
    operator = [_expr.args[2],_expr.args[4]]
    left_val = _expr.args[1]
    right_val = _expr.args[5]
    name = _expr.args[3]

    name isa Symbol ? nothing : error("No independent variable as a symbol is found")

    operator[1] == :<= && (operator[1] == operator[2]) ? nothing : error("Incorrect use of the operator")

    return name,[eval(left_val),eval(right_val)]
end

# add new or add exist independent variable
function check_inde_var_input(_raw_expr)

     if _raw_expr.head == :call && length(_raw_expr.args) == 3
        name,val = one_side_inde(_raw_expr)

     elseif _raw_expr.head == :comparison && length(_raw_expr.args) == 5
        name,val = two_sides_inde(_raw_expr)

     else
        error("The input of the independent variable is not in the correct format")
     end

     return name,val
end

#called when the user is not specifying any information about a new differential variable
function add_new_independent(_model,_expr)

    haskey(_model.Independent_var_index,_expr[1]) || length(_model.Independent_var_index) == 0 ? nothing : multiple_independent_var_error()
    bound_lower_upper(_expr[2])
    indep_var_data = Independent_Var_data(_expr[1],_expr[2])
    _model.Independent_var_index[indep_var_data.Sym] = indep_var_data

    return _model.Independent_var_index 
       
end

#called when the user put a new differential variable in with information
function add_new_independent(_model,_sym,_val)
    length(_model.Independent_var_index) == 1 ? multiple_independent_var_error() : add_exist_independent(_model,_sym,_val)
       
end

function add_exist_independent(_model,_sym,_val)

    bound_lower_upper(_val)
    indep_var_data = Independent_Var_data(_sym,_val)
    _model.Independent_var_index[indep_var_data.Sym] = indep_var_data

    return _model.Independent_var_index
end

##############################################################################################################
# add new or modify exist algebraic variable
function check_alge_var_input(__sym,__args)
    
  
    __args isa Vector ? nothing : throw(algebraic_input_style_error())

    bound_lower_upper(__args)
end

function add_exist_algebraic(_model,_sym,_args)

    check_alge_var_input(_sym,_args)

    setfield!(_model.Algebraic_var_index[_sym],:Bound,_args)

    return _model.Algebraic_var_index
end

function add_new_algebraic(_model,_sym,_args)

    check_alge_var_input(_sym,_args)

    alge_var_data = Algebraic_Var_data(_sym,_args)

    _model.Algebraic_var_index[alge_var_data.Sym] = alge_var_data

    return _model.Algebraic_var_index
end

#called when the user is not specifying any information about a new algebraic variable
function add_new_algebraic(_model,_args)

    bound_lower_upper(eval(_args[2]))

    alge_var_data = Algebraic_Var_data(_args[1],eval(_args[2]))

    _model.Algebraic_var_index[alge_var_data.Sym] = alge_var_data

    return _model.Algebraic_var_index
    
end