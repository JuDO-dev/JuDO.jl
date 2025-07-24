"""
    value(m::JuMP.Model, var::DynamicVarRef)
    Get the value of a dynamic variable.
"""
function dyn_value(m::JuMP.Model, var::DynamicVarRef)
    var_index = DOI.DynamicVariableIndex(var.Index, DOI.PhaseIndex(find_phase(var)))

    return MOI.get(m.moi_backend.optimizer.model, DOI.DynamicVariableSolution(), var_index)
end
