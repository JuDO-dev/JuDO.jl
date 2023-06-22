kw_collection = [:Initial_guess,:Initial_bound,:Final_bound,:Trajectory_bound,:Interpolant]

# identify the keyword in the user input and its value
function identify_kw(raw_expr,_model,_sym)

    kws = filter(x -> x isa Expr && x.head == :(=) && x.args[1] in kw_collection, raw_expr)
    length(kws) == length(raw_expr) ? nothing : throw(input_style_error())

    #find which keyword the user is modifying
    key_matches = []
    val_matches = []
    for i in eachindex(kws)
        position = findfirst(isequal(kws[i].args[1]),kw_collection)
        push!(key_matches,kw_collection[position])
        kw_collection[position] == :Interpolant ? push!(val_matches,kws[i].args[2]) : push!(val_matches,eval(kws[i].args[2]))
    end
    
    return key_matches,val_matches
end 

function identify_kw(raw_expr)

    default_info = [nothing, [-Inf,Inf], [-Inf,Inf],[-Inf,Inf],nothing]

    kws = filter(x -> x isa Expr && x.head == :(=) && x.args[1] in kw_collection, raw_expr)
    length(kws) == length(raw_expr) ? nothing : throw(input_style_error())

    #return the indices of keywords in kw_collection
    key_matches=[]
    for i in eachindex(kws)
        push!(key_matches,findfirst(isequal(kws[i].args[1]),kw_collection))
    end

    full_info=[]
    for i in eachindex(kw_collection)
        i in key_matches ? push!(full_info,kws[findfirst(isequal(i),key_matches)].args[2]) : push!(full_info,default_info[i])

        #evaluate the expression apart from the interpolant
        i == length(kw_collection) ? nothing : full_info[i] = eval(full_info[i]) 
    end
   
    check_initial_guess(full_info)
    
    return full_info

end

# add new or modify exist differential variable
function add_exist(_model,_sym,_args)

    field_info,new_val = identify_kw(_args,_model,_sym)

    [setfield!(_model.Differential_var_index[_sym],field_info[i],new_val[i]) for i in eachindex(field_info)]

    #check for the potential errors after the modification
    full_info = []
    for i in eachindex(kw_collection)
        push!(full_info,getfield(_model.Differential_var_index[_sym],kw_collection[i]))
    end
    check_initial_guess(full_info)

    return _model.Differential_var_index
end

function add_new(_model,_sym,_args)

    var_info = identify_kw(_args)
    push!(var_info,_sym)

    diff_var_data = Differential_Var_data(var_info[6],var_info[1],var_info[2],var_info[3],var_info[4],var_info[5])
    _model.Differential_var_index[diff_var_data.Run_sym] = diff_var_data

    return _model.Differential_var_index
end

function add_new(_model,_args)
    diff_var_data = Differential_Var_data(_args[6],_args[1],_args[2],_args[3],_args[4],_args[5])
    _model.Differential_var_index[diff_var_data.Run_sym] = diff_var_data

    return _model.Differential_var_index
end

# add new or add exist independent variable
function add_new_independent(_model,_args)
    #detect if the user is adding another independent variable
    length(_model.Independent_var_index) == 1 ? multiple_independent_var_error() : add_exist_independent(_model,_args)
       
end

function add_exist_independent(_model,_args)
    indep_var_data = Independent_Var_data(_args[2],eval(_args[3]))
    _model.Independent_var_index[indep_var_data.Sym] = indep_var_data

    return _model.Independent_var_index
end

# add new or modify exist algebraic variable
function add_exist_algebraic(_model,_sym,_args,is_discrete=false)

    setfield!(_model.Algebraic_var_index[_sym],:Is_discrete,is_discrete)

    full_info = eval(_args)
    
    if is_discrete
        setfield!(_model.Algebraic_var_index[_sym],:Integer_val,full_info)
        setfield!(_model.Algebraic_var_index[_sym],:Bound,nothing)
    else
        setfield!(_model.Algebraic_var_index[_sym],:Bound,full_info)
        setfield!(_model.Algebraic_var_index[_sym],:Integer_val,nothing)
    end
    
    return _model.Algebraic_var_index
end

function add_new_algebraic(_model,_sym,_args,is_discrete=false)

    full_info = eval(_args)

    is_discrete ? (alge_var_data = Algebraic_Var_data(is_discrete,_sym,nothing,full_info)) : (alge_var_data = Algebraic_Var_data(is_discrete,_sym,full_info,nothing))

    _model.Algebraic_var_index[alge_var_data.Sym] = alge_var_data

    return _model.Algebraic_var_index
end

function cont_or_dis(_args)
    length(_args) == 0 || length(_args) > 2 ? multiple_independent_var_error() : nothing

    _args[1] isa Symbol ? (return _args[1], [-Inf,Inf], false) : nothing

    length(_args) == 2 && !(:discrete in _args[2].args) && !(:(=) in _args[2].args) ? input_style_error() : nothing 
    
    if :in in _args[1].args   

        is_discrete = false
        name = _args[1].args[2]
        val = _args[1].args[3]

        length(_args) == 2 && _args[2] == :(discrete=true) ? contradicted_input(:bound,true) : nothing

        return name,val,is_discrete

    elseif :(=) == _args[1].head

        is_discrete = true
        name = _args[1].args[1]
        val = _args[1].args[2]

        length(_args) == 1 ? contradicted_input(:(vector_of_integer),false) : nothing

        return name,val,is_discrete

    else
        algebraic_input_style_error()
    end

end
