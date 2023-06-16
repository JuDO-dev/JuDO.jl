function construct_differential_variable(_initial_var, _bounds, _var_names)
     
    diff_var_data = Differential_Var_data( _var_names[1],_initial_var,[_bounds[1],_bounds[2]],_var_names[2],[_bounds[3],_bounds[4]],_var_names[3],[_bounds[5],_bounds[6]],)

    return diff_var_data
end



"""
DynamicModel = DOI.DynamicModel

function add_independent_var(model::DynamicModel,name::Union{String,Char},var::AbstractFloat)
     
    var_index = DOI.add_independent_variable(model.doi_backend,name,var)

    return model, var_index
end
"""