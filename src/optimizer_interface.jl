"""
    warmstart!(m::DynModel, interpolant::DOI.AbstractDynamicSolution, var::DynamicVarRef)
    set the interpolant for a dynamic variable in the model
"""
function warmstart!(m::JuMP.Model, interpolant::DOI.AbstractDynamicSolution, var::DynamicVarRef)

    var_index = DOI.DynamicVariableIndex(var.Index, DOI.PhaseIndex(find_phase(var)))

    MOI.set(
        m.moi_backend.optimizer.model,
        DOI.DynamicVariableStart(),
        var_index,
        interpolant
    )
    return nothing
end

function warmstart!(
    m::JuMP.Model,
    solutions::AbstractDict{String, T}
) where {T<:DOI.AbstractDynamicSolution}

    for (name, sol) in solutions
        idx = get(m.ext[:var_name_to_idx], Symbol(name), nothing)
        if isnothing(idx)
            @warn "Warm-start supplied for variable '$name', but no matching variable found in the model."
        else
            var_ref = DynamicVarRef(m, idx, Symbol(name))
            warmstart!(m, sol, var_ref)
        end
    end
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
function optimize!(m::JuMP.Model; kwargs...)

    if haskey(kwargs, :solver)
        m.moi_backend.optimizer.model.inner = kwargs[:solver]
    end
    if haskey(kwargs, :intervals)
        m.moi_backend.optimizer.model.default_intervals = kwargs[:intervals]
    end
    if haskey(kwargs, :points)
        m.moi_backend.optimizer.model.default_points = kwargs[:points]
    end
    if haskey(kwargs, :method)
        m.moi_backend.optimizer.model.default_methods = kwargs[:method]
    end
    if haskey(kwargs, :bounds)
        m.moi_backend.optimizer.model.default_bounds = kwargs[:bounds]
    end

    MOI.optimize!(m.moi_backend.optimizer.model)

    return nothing
end