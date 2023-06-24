
# check the input style of the differential variables, return the keyword and value for both '=' and 'in' style
function check_diff_var_input(_raw_expr)
    kw_collection_eq = [:Initial_guess,:Interpolant]
    kw_collection_in = [:Initial_bound,:Final_bound,:Trajectory_bound]

    match_eq = filter(x -> x isa Expr && x.head == :(=), _raw_expr)
    val_eq = []
    [i.args[1] in kw_collection_eq ? push!(val_eq,i.args[2]) : throw(diff_var_input_style_error()) for i in match_eq]
    
    match_in = filter(x -> x isa Expr && (:in in x.args), _raw_expr)
    val_in = []
    [i.args[2] in kw_collection_in ? push!(val_in,i.args[3]) : throw(diff_var_input_style_error()) for i in match_in]
    
    #check if there is any other types of input argument
    length(match_eq) + length(match_in) == length(_raw_expr) ? nothing : throw(diff_var_input_style_error())
    
    #collect the keyword back
    match_eq = [i.args[1] for i in match_eq]
    match_in = [i.args[2] for i in match_in]
    return match_eq, val_eq, match_in, val_in
end

# identify the keyword in the user input and its value
function identify_kw(__model,__sym,_field_eq,_val_eq,_field_in,_val_in,add_new=true)
    kw_collection = [:Initial_guess,:Initial_bound,:Final_bound,:Trajectory_bound,:Interpolant]
    default_info = [nothing, [-Inf,Inf], [-Inf,Inf],[-Inf,Inf],nothing]

    #return the indices of user-input keywords in kw_collection
    eq_index_matches=[]
    [push!(eq_index_matches,findfirst(isequal(_field_eq[i]),kw_collection)) for i in eachindex(_field_eq)]

    in_index_matches=[]
    [push!(in_index_matches,findfirst(isequal(_field_in[i]),kw_collection)) for i in eachindex(_field_in)]
   
    full_info=[]
    for i in eachindex(kw_collection)
        
        if i in in_index_matches
            push!(full_info,eval(popfirst!(_val_in))) 
        elseif i in eq_index_matches
            push!(full_info,popfirst!(_val_eq)) 
        else
            add_new ? push!(full_info,default_info[i]) : push!(full_info,getfield(__model.Differential_var_index[__sym],i+1))
        end
         
    end
   
    check_initial_guess(full_info)
    
    return full_info

end

#modify an exist differential variable
function add_exist(_model,_sym,_args)
    field_eq,val_eq,field_in,val_in = check_diff_var_input(_args)

    var_info = identify_kw(_model,_sym,field_eq,val_eq,field_in,val_in,false)
    pushfirst!(var_info,_sym)
    
    field_names = collect(fieldnames(Differential_Var_data))

    [setfield!(_model.Differential_var_index[_sym],field_names[i],var_info[i]) for i in eachindex(field_names)]

    return _model.Differential_var_index

end

#called when the user is specifying information about the differential variable
function add_new(_model,_sym,_args)

    field_eq,val_eq,field_in,val_in = check_diff_var_input(_args)

    var_info = identify_kw(_model,_sym,field_eq,val_eq,field_in,val_in)
    pushfirst!(var_info,_sym)

    diff_var_data = Differential_Var_data(var_info[1],var_info[2],var_info[3],var_info[4],var_info[5],var_info[6])
    _model.Differential_var_index[diff_var_data.Run_sym] = diff_var_data  

    return _model.Differential_var_index
end

#called when the user is not specifying any information about the differential variable
function add_new(_model,_args)
    diff_var_data = Differential_Var_data(_args[1],_args[2],_args[3],_args[4],_args[5],_args[6])
    _model.Differential_var_index[diff_var_data.Run_sym] = diff_var_data

    return _model.Differential_var_index
end

# add new or add exist independent variable
function check_inde_var_input(__sym,__args)
    __sym isa Symbol ? nothing : throw(algebraic_input_style_error())
    __args isa Vector ? nothing : throw(algebraic_input_style_error())

    bound_lower_upper(__args)
end

function add_new_independent(_model,_args)
    #detect if the user is adding another independent variable
    length(_model.Independent_var_index) == 1 ? multiple_independent_var_error() : add_exist_independent(_model,_args)
       
end

function add_exist_independent(_model,_args)
    check_inde_var_input(_args[2],eval(_args[3]))
    indep_var_data = Independent_Var_data(_args[2],eval(_args[3]))
    _model.Independent_var_index[indep_var_data.Sym] = indep_var_data

    return _model.Independent_var_index
end

# add new or modify exist algebraic variable
function check_alge_var_input(__sym,__args)
    __sym isa Symbol ? nothing : throw(algebraic_input_style_error())
    __args isa Vector ? nothing : throw(algebraic_input_style_error())

    bound_lower_upper(__args)
end

function add_exist_algebraic(_model,_sym,_args)

    full_info = eval(_args)
    check_alge_var_input(_sym,_args)

    setfield!(_model.Algebraic_var_index[_sym],:Bound,full_info)

    return _model.Algebraic_var_index
end

function add_new_algebraic(_model,_sym,_args)

    full_info = eval(_args)
    check_alge_var_input(_sym,_args)

    alge_var_data = Algebraic_Var_data(_sym,full_info)

    _model.Algebraic_var_index[alge_var_data.Sym] = alge_var_data

    return _model.Algebraic_var_index
end

function add_new_algebraic(_model,_args)
    check_alge_var_input(_args[1],eval(_args[2]))

    alge_var_data = Algebraic_Var_data(_args[1],eval(_args[2]))

    _model.Algebraic_var_index[alge_var_data.Sym] = alge_var_data

    return _model.Algebraic_var_index
    
end