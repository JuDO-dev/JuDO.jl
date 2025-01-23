mutable struct Optimizer{M<:AbstractMesh} <: MOI.AbstractOptimizer
    mesh::M
    transcription::Ipopt.Optimizer

    phase::Union{Nothing,DOI.PhaseIndex}
    phase_initial::Union{Nothing,Float64}
    phase_final::Union{Nothing,Float64}

    dyn_vars::OrderedSet{DYN_VAR}
    dyn_var_last_index::Int64
    dyn_var_bounds::OrderedDict{DYN_VAR,IV64}
    dyn_var_initials::OrderedDict{DYN_VAR,EQ64}
    dyn_var_finals::OrderedDict{DYN_VAR,EQ64}
    dyn_var_starts::Union{Nothing,OrderedDict{DYN_VAR,<:DOI.AbstractDynamicSolution}}
      
    residuals::OrderedDict{MOI.ConstraintIndex{DOI.NonlinearDynamicFunction,EQ64},DOI.NonlinearDynamicFunction}
    residuals_last_index::Int64

    objective::Union{Nothing,DOI.Bolza{DOI.NonlinearBoundaryFunction,DOI.NonlinearDynamicFunction}}

    differentiables::OrderedSet{DYN_VAR}
    dyn_var_map::OrderedDict{DYN_VAR,Vector{Vector{MOI.VariableIndex}}}

    function Optimizer(; mesh::M=EquispacedMesh(1, GLRCollocation(4), SampledBounds())) where {M<:AbstractMesh}
        return new{M}(
            mesh,
            Ipopt.Optimizer(),
            nothing,
            nothing,
            nothing,
            OrderedSet{DYN_VAR}(),
            0,
            OrderedDict{DYN_VAR,IV64}(),
            OrderedDict{DYN_VAR,EQ64}(),
            OrderedDict{DYN_VAR,EQ64}(),
            nothing,
            OrderedDict{MOI.ConstraintIndex{DOI.NonlinearDynamicFunction,EQ64},DOI.NonlinearDynamicFunction}(),
            0,
            nothing,
            OrderedSet{DYN_VAR}(),
            OrderedDict{DYN_VAR,Vector{Vector{MOI.VariableIndex}}}(),
        )
    end
end

MOI.add_variable(model::Optimizer) = MOI.add_variable(model.transcription)

function MOI.supports_constraint(
    model::Optimizer,
    fun::MOI.AbstractFunction,
    set::MOI.AbstractSet,
)
    return MOI.supports_constraint(model.transcription, fun, set)
end

function MOI.add_constraint(
    model::Optimizer,
    fun::MOI.AbstractFunction,
    set::MOI.AbstractSet,
)
    return MOI.add_constraint(model.transcription, fun, set)
end

DOI.supports_phase(::Optimizer) = true

function DOI.add_phase(model::Optimizer)

    if !isnothing(model.phase)
        throw(DOI.AddPhaseNotAllowed(""))
    else
        index = DOI.PhaseIndex(1)
        model.phase = index
        return index
    end
end

MOI.is_valid(model::Optimizer, index::DOI.PhaseIndex) = model.phase == index ? true : false

MOI.supports_constraint(::Optimizer, ::DOI.Initial{DOI.PhaseIndex}, ::EQ64) = true

function MOI.add_constraint(model::Optimizer, phase_initial::DOI.Initial{DOI.PhaseIndex}, set::EQ64)

    phase = phase_initial.dyn_fun
    
    if !MOI.is_valid(model, phase)
        throw(DOI.InvalidPhaseIndex(phase))
    elseif !isnothing(model.phase_initial)
        throw(MOI.AddConstraintNotAllowed{typeof(phase_initial),typeof(set)}("Initial phase already set."))
    else
        model.phase_initial = set.value
        return MOI.ConstraintIndex{DOI.Initial{DOI.PhaseIndex},EQ64}(phase.value)
    end
end

MOI.supports_constraint(::Optimizer, ::DOI.Final{DOI.PhaseIndex}, ::EQ64) = true

function MOI.add_constraint(model::Optimizer, phase_final::DOI.Final{DOI.PhaseIndex}, set::EQ64)

    phase = phase_final.dyn_fun
    
    if !MOI.is_valid(model, phase)
        throw(DOI.InvalidPhaseIndex(phase))
    elseif !isnothing(model.phase_final)
        throw(MOI.AddConstraintNotAllowed{typeof(phase_final),typeof(set)}("Final phase already set."))
    else
        model.phase_final = set.value
        return MOI.ConstraintIndex{DOI.Final{DOI.PhaseIndex},EQ64}(phase.value)
    end
end

DOI.supports_dynamic_variable(::Optimizer) = true

function DOI.add_dynamic_variable(model::Optimizer, phase::DOI.PhaseIndex)

    if !MOI.is_valid(model, phase)
        throw(DOI.InvalidPhaseIndex(phase))
    else
        index = DYN_VAR(model.dyn_var_last_index + 1, phase)
        push!(model.dyn_vars, index)
        model.dyn_var_last_index += 1
        return index
    end
end

MOI.is_valid(model::Optimizer, index::DYN_VAR) = index in model.dyn_vars

MOI.supports_constraint(::Optimizer, ::DYN_VAR, ::IV64) = true

function MOI.add_constraint(model::Optimizer, dyn_var::DYN_VAR, set::IV64)

    if !MOI.is_valid(model, dyn_var)
        throw(DOI.InvalidDynamicVariableIndex(dyn_var))
    elseif dyn_var in keys(model.dyn_var_bounds)
        throw(MOI.AddConstraintNotAllowed{typeof(dyn_var),IV64}("Bound already set."))
    else
        model.dyn_var_bounds[dyn_var] = set
        return MOI.ConstraintIndex{DYN_VAR,IV64}(dyn_var.value)
    end
end

MOI.supports_constraint(::Optimizer, ::DOI.Initial{DYN_VAR}, ::EQ64) = true

function MOI.add_constraint(model::Optimizer, dyn_var_initial::DOI.Initial{DYN_VAR}, set::EQ64)

    dyn_var = dyn_var_initial.dyn_fun
    
    if !MOI.is_valid(model, dyn_var)
        throw(DOI.InvalidDynamicVariableIndex(dyn_var))
    elseif dyn_var in keys(model.dyn_var_initials)
        throw(MOI.AddConstraintNotAllowed{typeof(dyn_var_initial),EQ64}("Initial value already set."))
    else
        model.dyn_var_initials[dyn_var] = set
        return MOI.ConstraintIndex{DOI.Initial{DYN_VAR},EQ64}(dyn_var.value)
    end
end

MOI.supports_constraint(::Optimizer, ::DOI.Final{DYN_VAR}, ::EQ64) = true

function MOI.add_constraint(model::Optimizer, dyn_var_final::DOI.Final{DYN_VAR}, set::EQ64)

    dyn_var = dyn_var_final.dyn_fun
    
    if !MOI.is_valid(model, dyn_var)
        throw(DOI.InvalidDynamicVariableIndex(dyn_var))
    elseif dyn_var in keys(model.dyn_var_finals)
        throw(MOI.AddConstraintNotAllowed{typeof(dyn_var_final),EQ64}("Final value already set."))
    else
        model.dyn_var_finals[dyn_var] = set
        return MOI.ConstraintIndex{DOI.Final{DYN_VAR},EQ64}(dyn_var.value)
    end
end

MOI.supports_constraint(::Optimizer, ::DOI.NonlinearDynamicFunction, ::EQ64) = true

function MOI.add_constraint(model::Optimizer, residual::DOI.NonlinearDynamicFunction, ::EQ64)

    #_throw_if_invalid(residual)

    index = MOI.ConstraintIndex{DOI.NonlinearDynamicFunction,EQ64}(model.residuals_last_index + 1)
    model.residuals[index] = residual
    model.residuals_last_index += 1
    return index
end


function MOI.optimize!(model::Optimizer)

    populate_mesh!(model.mesh, model.phase_initial, model.phase_final)

    add_differentiables!(model.differentiables, model.residuals)

    transcribe!(model)

    MOI.optimize!(model.transcription)

    # Recover the solution?

    return nothing
end

#=
function _throw_if_invalid_index(model::Optimizer, index::DOI.PhaseIndex)
    if !MOI.is_valid(model, index)
        throw(DOI.InvalidPhaseIndex(index))
    end
    return nothing
end

function _throw_if_invalid_index(model::Optimizer, index::DOI.DynamicVariableIndex)
    if !MOI.is_valid(model, index)
        throw(DOI.InvalidDynamicVariableIndex(index))
    end
    return nothing
end




#=

# Optimizer Attributes

MOI.get(::Optimizer, ::MOI.OptimizerName) = "Interesso"

MOI.get(::Optimizer, ::MOI.OptimizerVersion) = "v0.0.0"

MOI.supports(::Optimizer, ::MOI.Silent) = true
MOI.set(model::Optimizer, attr::MOI.Silent, value) = MOI.set(model.optimizer, attr, value)
MOI.get(model::Optimizer, attr::MOI.Silent)        = MOI.get(model.optimizer, attr)

struct NumberOfSubPhases <: MOI.AbstractOptimizerAttribute end
MOI.attribute_value_type(::NumberOfSubPhases) = Int
MOI.supports(::Optimizer, ::NumberOfSubPhases) = true
function MOI.set(model::Optimizer, ::NumberOfSubPhases, value::Int)
    model.number_of_sub_phases = value
    return nothing
end
MOI.get(model::Optimizer, ::NumberOfSubPhases) = model.optimizer

struct SubPhaseFlexibility <: MOI.AbstractOptimizerAttribute end
MOI.attribute_value_type(::SubPhaseFlexibility) = Union{Nothing,Float64}
MOI.supports(::Optimizer, ::SubPhaseFlexibility) = true
function MOI.set(model::Optimizer, ::SubPhaseFlexibility, value::Union{Nothing,Float64})
    model.sub_phase_flexibility = value
    return nothing
end
MOI.get(model::Optimizer, ::SubPhaseFlexibility) = model.sub_phase_flexibility


# Model Attributes

MOI.supports(::Optimizer, ::MOI.Name) = true
function MOI.set(model::Optimizer, name::String)
    model.name = name
    return nothing
end
MOI.get(model::Optimizer, ::MOI.Name) = model.name

MOI.get(model::Optimizer, ::DOI.NumberOfPhases) = length(model.phase_indices)
MOI.get(model::Optimizer, ::DOI.NumberOfDynamicVariables) = length(model.dynamic_variable_indices)
MOI.get(model::Optimizer, ::MOI.NumberOfContraints) = length(model.constraint_indices)




MOI.supports(::Optimizer, ::MOI.ObjectiveSense) = true
function MOI.set(model::Optimizer, ::MOI.ObjectiveSense, sense::MOI.OptimizationSense)
    model.objective_sense = sense
    return nothing
end
MOI.get(model::Optimizer, ::MOI.ObjectiveSense) = model.objective_sense

MOI.get



## ObjectiveSense







## 

function MOI.empty!(model::Optimizer)

    model.objective_sense = 
    return nothing
end

function MOI.is_empty(::Optimizer)

    return true
end

function Base.show(io::IO, model::Optimizer)
    return print(io, "Interesso Optimizer")
end

MOI.get(::Optimizer, ::MOI.OptimizerName) = "Interesso"

MOI.get(::Optimizer, ::MOI.OptimizerVersion) = "0.0.0"


# MOI




# Phases



function DOI.add_phase(model::Optimizer)

    i = model.dfp.last_phase_index + 1
    t_i = DOI.PhaseIndex(i)
    push!(model.dfp.t, t_i)
    model.dfp.last_phase_index = i

    return t_i
end


# Dynamic Variables

DOI.supports_dynamic_variable(::Optimizer) = true

function DOI.add_dynamic_variable(model::Optimizer, t_i::PhaseIndex)

    j = model.dfp.last_dynamic_variable_index + 1
    y_j = DYN_VAR(j, t_i)
    push!(model.dfp.y, y_j)
    model.dfp.last_dynamic_variable_index = j

    return y_j
end


# Constraints

const _BOUNDARY_FUNCTIONS = Union{
    DOI.Initial{DOI.PhaseIndex},
    DOI.Final{DOI.PhaseIndex},
    DOI.Initial{DYN_VAR},
    DOI.Final{DYN_VAR},
}

MOI.supports_constraint(::Optimizer, ::Type{<:_BOUNDARY_FUNCTIONS}, ::MOI.EqualTo) = true

MOI.supports_constraint(::Optimizer, ::DYN_VAR, ::MOI.Interval) = true
MOI.supports_constraint(::Optimizer, ::DOI.NonlinearDynamicFunction, ::MOI.Zeros) = true

function add_constraint(model::Optimizer, t_0::DOI.Initial{DOI.PhaseIndex}, set::EqualTo)

    model.dfp.t_initial[t_0.evaluand] = set 

    k = model.dfp.last_constraint_index + 1
    c_k = MOI.ConstraintIndex(k)
    model.dfp.last_constraint_index = k

    return c_k
end








=#



function MOI.get(model::Optimizer, ::MOI.VariablePrimal, dyn_var::DYN_VAR)

    if dyn_var in model.differentiable
        polynomials = model.mesh.polynomials_d
    else
        polynomials = model.mesh.polynomials_a
    end
    
    return PiecewiseInterpolant([BarycentricInterpolant(
        model.mesh.subintervals[i],
        polynomials[i],
        MOI.get(model.transcription, MOI.VariablePrimal(), model.dyn_var_map[dyn_var][i]),
    ) for i in 1:model.mesh.h.n])
end

function MOI.get(model::Optimizer, ::MOI.ConstraintPrimal, dyn_eq::MOI.ConstraintIndex{}, t::Real)


    return PiecewiseInterpolant([BarycentricInterpolant(
        ...,
        model.mesh.polynomials_a,
        #Evaluate dyn
    )])
end

MOI.get(model::Optimizer, ::MOI.ConstraintPrimal, dyn_eq, t::Vector{<:Real})

MOI.get(model::Optimizer, ::MOI.ObjectiveValue)=#


m=JuDO.Dy_Model()
JuDO.@phase(m,t)
JuDO.@dynamic_variable(m,x,t)