"""
    value(m::JuMP.Model, var::DynamicVarRef)
    Get the value of a dynamic variable.
"""
function dyn_value(m::JuMP.Model, var::DynamicVarRef)
    var_index = DOI.DynamicVariableIndex(var.Index, DOI.PhaseIndex(find_phase(var)))

    return MOI.get(m.moi_backend.optimizer.model, DOI.DynamicVariableSolution(), var_index)
end

"""
    phase_initial(t::PhaseVarRef)

Returns the initial time of the phase `t` defined in the model.
"""
function phase_initial(t::PhaseVarRef)
    # 1. Access the underlying Interesso optimizer
    model = t.model
    optimizer = model.moi_backend.optimizer.model
    
    # 2. Get the DOI Phase Index
    p_idx = DOI.PhaseIndex(t.Index)

    # 3. Retrieve and return the value
    # [cite_start]Interesso stores fixed initial times in the phase_initials dictionary [cite: 18]
    if haskey(optimizer.phase_initials, p_idx)
        return optimizer.phase_initials[p_idx]
    else
        error("Initial time for phase $(t.Index) is not set.")
    end
end

"""
    phase_final(t::PhaseVarRef)

Returns the final time of the phase `t`. 
- If the final time is fixed (e.g., final(t) == 10), returns that value.
- If the final time is free/optimized (e.g., final(t) <= 10), queries the solver for the result.
"""
function phase_final(t::PhaseVarRef)
    # 1. Access the underlying Interesso optimizer
    model = t.model
    optimizer = model.moi_backend.optimizer.model
    
    # 2. Get the DOI Phase Index
    p_idx = DOI.PhaseIndex(t.Index)

    # 3. CASE A: Fixed Final Time (e.g., final(t) == 2500)
    if haskey(optimizer.phase_finals, p_idx)
        if optimizer.phase_finals[p_idx] isa MOI.EqualTo
            return optimizer.phase_finals[p_idx]
        end
    end

    # 4. CASE B: Free / Optimized Final Time
    # Get initial time
    t0 = optimizer.phase_initials[p_idx]

    # Get duration variable
    if !haskey(optimizer.time_vars, p_idx)
         error("Could not find time variable for phase $(t.Index). Ensure the problem has been transcribed/optimized.")
    end
    
    duration_ref = optimizer.time_vars[p_idx]

    # Check if duration is a variable or a number
    return MOI.get(optimizer.inner, MOI.VariablePrimal(), duration_ref)
    
end

"""
    get_solutions(m::JuMP.Model)

Return a dictionary mapping dynamic variable names to their solutions.
"""
function get_solutions(m::JuMP.Model)
    solutions = Dict{String, DOI.AbstractDynamicSolution}()
    for (name_sym, idx) in m.ext[:var_name_to_idx]
        dv = m.ext[:variables][idx]
        var_index = DOI.DynamicVariableIndex(idx, DOI.PhaseIndex(dv.Phase.Index))
        solutions[string(name_sym)] = MOI.get(
            m.moi_backend.optimizer.model,
            DOI.DynamicVariableSolution(),
            var_index,
        )
    end
    return solutions
end
