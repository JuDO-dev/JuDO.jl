"""
    value(m::JuMP.Model, var::DynamicVarRef)
    Get the value of a dynamic variable.
"""
function dyn_value(m::JuMP.Model, var::DynamicVarRef)
    var_index = DOI.DynamicVariableIndex(var.Index, DOI.PhaseIndex(find_phase(var)))

    return MOI.get(m.moi_backend.optimizer.model, DOI.DynamicVariableSolution(), var_index)
end

"""
    get_solutions(m::JuMP.Model)

Return a dictionary mapping dynamic variable names to their solutions.
"""
function get_solutions(m::JuMP.Model)
    solutions = Dict{String, DOI.AbstractDynamicSolution}()
    for (name_sym, idx) in m.ext[:var_name_to_idx]
        dv = m.ext[:variables][idx]
        var_index = DOI.DynamicVariableIndex(idx, DOI.PhaseIndex(dv.Phase))
        solutions[string(name_sym)] = MOI.get(
            m.moi_backend.optimizer.model,
            DOI.DynamicVariableSolution(),
            var_index,
        )
    end
    return solutions
end
