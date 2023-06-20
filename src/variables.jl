kw_collection = [:Initial_val,:Final_val,:Initial_bound,:Final_bound,:Trajectory_bound,:Interpolant]

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

    default_info = [nothing, nothing, [-Inf,Inf], [-Inf,Inf],[-Inf,Inf],nothing]

    kws = filter(x -> x isa Expr && x.head == :(=) && x.args[1] in kw_collection, raw_expr)
    length(kws) == length(raw_expr) ? nothing : throw(input_style_error())

    #return the indices of keywords in kw_collection
    key_matches=[]
    for i in eachindex(kws)
        push!(key_matches,findfirst(isequal(kws[i].args[1]),kw_collection))
    end

    full_info=[]
    for i in 1:6
        i in key_matches ? push!(full_info,kws[findfirst(isequal(i),key_matches)].args[2]) : push!(full_info,default_info[i])

        #evaluate the expression apart from the interpolant
        i == 6 ? nothing : full_info[i] = eval(full_info[i]) 
    end
   
    check_final_diff_var(full_info)
    
    return full_info

end

# add new or modify exist differential variable
function add_exist(_model,_sym,_args)

    field_info,new_val = identify_kw(_args,_model,_sym)

    [setfield!(_model.Differential_var_index[_sym],field_info[i],new_val[i]) for i in eachindex(field_info)]

    #check for the potential errors after the modification
    full_info = []
    for i in 1:6
        push!(full_info,getfield(_model.Differential_var_index[_sym],kw_collection[i]))
    end
    check_final_diff_var(full_info)

    return _model.Differential_var_index
end

function add_new(_model,_sym,_args)

    var_info = identify_kw(_args)
    push!(var_info,_sym)

    diff_var_data = Differential_Var_data(var_info[7],var_info[1],var_info[2],var_info[3],var_info[4],var_info[5],var_info[6])
    _model.Differential_var_index[diff_var_data.Run_sym] = diff_var_data

    return _model.Differential_var_index
end

function add_new(_model,_args)
    diff_var_data = Differential_Var_data(_args[7],_args[1],_args[2],_args[3],_args[4],_args[5],_args[6])
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

#= function construct_independent_variable(_model,_info::Vector)

    length(_model.Independent_var_index) == 1 ? throw(error("Only one independent variable is allowed")) : nothing
     
    indep_var_data = Independent_Var_data(_info[1], _info[2])

    _model.Independent_var_index[indep_var_data.sym] = indep_var_data

    return indep_var_data
    
end =#
