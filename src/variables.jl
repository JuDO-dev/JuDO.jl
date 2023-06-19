function construct_differential_variable(_sym,_info::Vector)

    diff_var_data = Differential_Var_data(_sym,_info[1],_info[2],_info[3],_info[4],_info[5],_info[6])

    return diff_var_data
end

function construct_independent_variable(_name, _bounds)
     
    indep_var_data = Independent_Var_data(_name, _bounds)

    return indep_var_data
    
end

"""
DynamicModel = DOI.DynamicModel

function add_independent_var(model::DynamicModel,name::Union{String,Char},var::AbstractFloat)
     
    var_index = DOI.add_independent_variable(model.doi_backend,name,var)

    return model, var_index
end
"""
