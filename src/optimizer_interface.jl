"""
    set_interpolant(m::DynModel, interpolant::DOI.AbstractDynamicSolution, var::DynamicVarRef)
    set the interpolant for a dynamic variable in the model
"""
function set_interpolant(m::JuMP.Model,interpolant::DOI.AbstractDynamicSolution, var::DynamicVarRef)

    var_index = DOI.DynamicVariableIndex(var.Index, DOI.PhaseIndex(find_phase(var)))

    MOI.set(
        m.moi_backend.optimizer.model,
        DOI.DynamicVariableStart(),
        var_index,
        interpolant
    )
    return nothing
end


"""
    set_intervals(m::JuMP.Model, intervals::AbstractIntervals)
    Set the intervals for the model.
"""
function set_intervals(m::JuMP.Model, intervals)

    optimizer_type = typeof(m.moi_backend.optimizer.model)

        MOI.set(m.moi_backend.optimizer.model, DefaultIntervals(), intervals)
    return nothing
end

"""
    optimize!(m::JuMP.Model)
    Optimize the model.
"""
function optimize(m::JuMP.Model;kwargs...)

    #if there is interval in kwargs, or points in kwargs, set them in the model
    if haskey(kwargs, :intervals)
        m.moi_backend.optimizer.model.default_intervals = kwargs[:intervals]
    end
    if haskey(kwargs, :points)
        m.moi_backend.optimizer.model.default_points = kwargs[:points]
    end

    MOI.optimize!(m.moi_backend.optimizer.model)
end