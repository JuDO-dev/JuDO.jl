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
    solutions::AbstractDict{String, <:DOI.AbstractDynamicSolution}
)

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
    JuMP.set_attribute(m::JuMP.Model, ::DOI.GeneralIntervals, value::DOI.AbstractIntervals)

Set the mesh interval structure. `value` must subtype `DOI.AbstractIntervals`.
Refer to the attached solver's documentation for supported concrete types
(e.g. `FixedIntervals(n)`, `FlexibleIntervals(n, flexibility)`).
"""
function JuMP.set_attribute(m::JuMP.Model, attr::DOI.GeneralIntervals, value)
    opt = m.moi_backend.optimizer.model
    
    MOI.set(opt, attr, value)
    return nothing
end

"""
    JuMP.set_attribute(m::JuMP.Model, ::DOI.GeneralPoints, value::DOI.AbstractPoints)

Set the collocation point scheme. `value` must subtype `DOI.AbstractPoints`.
Refer to the attached solver's documentation for supported concrete types
(e.g. `LGRPoints(n)`, `LGLPoints(n)`).
"""
function JuMP.set_attribute(m::JuMP.Model, attr::DOI.GeneralPoints, value)
    opt = m.moi_backend.optimizer.model
    
    MOI.set(opt, attr, value)
    return nothing
end

"""
    JuMP.set_attribute(m::JuMP.Model, ::DOI.GeneralMethod, value::DOI.AbstractMethod)

Set the discretization method. `value` must subtype `DOI.AbstractMethod`.
Refer to the attached solver's documentation for supported concrete types
(e.g. `Collocation()`, `DAIR(n)`).
"""
function JuMP.set_attribute(m::JuMP.Model, attr::DOI.GeneralMethod, value)
    opt = m.moi_backend.optimizer.model
    
    MOI.set(opt, attr, value)
    return nothing
end

"""
    JuMP.set_attribute(m::JuMP.Model, ::DOI.GeneralBounds, value::DOI.AbstractBounds)

Set the bounds enforcement strategy. `value` must subtype `DOI.AbstractBounds`.
Refer to the attached solver's documentation for supported concrete types
(e.g. `ExactBounds()`, `BernsteinBounds()`).
"""
function JuMP.set_attribute(m::JuMP.Model, attr::DOI.GeneralBounds, value)
    opt = m.moi_backend.optimizer.model
    
    MOI.set(opt, attr, value)
    return nothing
end


"""
    optimize!(m::JuMP.Model)

    Optimize the model. Keyword arguments are a convenience shorthand for calling
`JuMP.set_attribute` individually before optimizing.
"""
function optimize!(m::JuMP.Model; kwargs...)

    if haskey(kwargs, :solver)
        m.moi_backend.optimizer.model.inner = kwargs[:solver]
    end
    if haskey(kwargs, :intervals)
        m.moi_backend.optimizer.model.default_intervals = kwargs[:intervals]
        #MOI.set(m.moi_backend.optimizer.model, DOI.DefaultIntervals(), kwargs[:intervals])

    end
    if haskey(kwargs, :points)
        m.moi_backend.optimizer.model.default_points = kwargs[:points]
    end
    if haskey(kwargs, :method)
        m.moi_backend.optimizer.model.default_method = kwargs[:method]
    end
    if haskey(kwargs, :bounds)
        m.moi_backend.optimizer.model.default_bounds = kwargs[:bounds]
    end

    MOI.optimize!(m.moi_backend.optimizer.model)

    return nothing
end