"""
    Integral <: JuMP.AbstractJuMPScalar

Represents a definite integral of a dynamic expression over a phase, used to
express Lagrange (running-cost) objectives. Created via the `integral()`
function.

# Fields
- `expr`: the integrand as a JuMP scalar expression.
- `phase`: integer index of the phase over which the integral is taken.
"""
struct Integral <: JuMP.AbstractJuMPScalar
    expr::JuMP.AbstractJuMPScalar  # The expression being integrated
    phase::Int                     # Phase index for the integral
end

function Base.show(io::IO, integral::Integral) 
    #find the phase symbol

    print(io, "∫(", integral.expr,")")
end

"""
    JuMP.integral(expr::JuMP.AbstractJuMPScalar, phase::Int) -> Integral

Creates an integral representation for the given expression and phase.

"""
function integral(expr::Union{JuMP.AbstractVariableRef, JuMP.AbstractJuMPScalar})
    #get the phase from the expression if it exists
    phase = find_phase(expr)

    return Integral(expr, phase)
end

"""
    objective_has_measures(model::JuMP.Model) -> Bool

Returns true if the objective function contains any measure variables.
"""
function objective_has_measures(model::JuMP.Model)::Bool
    return get(model.ext, :objective_has_measures, false)
end

function create_zero_integral(model::JuMP.Model)
    dyn_funs = DOI.NonlinearDynamicFunction[]
    for (phase_idx, _) in model.ext[:Phases]
        zero_fun = DOI.NonlinearDynamicFunction(:+, [0.0], DOI.PhaseIndex(phase_idx))
        push!(dyn_funs, zero_fun)
    end
    return DOI.MultiPhaseIntegral(dyn_funs)
end

# --- Objective Setting Functions ---

function JuMP.set_objective_function(model::JuMP.Model, func::Real)::Nothing
    
    # Create constant Bolza objective
    boundary_fun = DOI.NonlinearBoundaryFunction(:+, [0.0])
    integral_part = create_zero_integral(model)
    bolza_obj = DOI.Bolza(boundary_fun, integral_part)
    
    # Store and set
    model.ext[:objective_function] = bolza_obj
    MOI.set(
        model.moi_backend.optimizer, 
        MOI.ObjectiveFunction{typeof(bolza_obj)}(), 
        bolza_obj
    )
    
    set_transformation_backend_ready(model, false)
    return nothing
end

function JuMP.set_objective_function(model::JuMP.Model, func::DOI.Bolza)::Nothing
   
    # Set in MOI
    MOI.set(
        model.moi_backend.optimizer, 
        MOI.ObjectiveFunction{typeof(func)}(), 
        func
    )
    
    set_transformation_backend_ready(model, false)
    return nothing
end

function JuMP.set_objective_function(model::JuMP.Model, func::DOI.NonlinearBoundaryFunction)::Nothing
    
    # Pass NBF directly to the optimizer. 
    MOI.set(
        model.moi_backend.optimizer, 
        MOI.ObjectiveFunction{typeof(func)}(), 
        func
    )
    return nothing
end

function JuMP.set_objective_sense(model::JuMP.Model, sense::MOI.OptimizationSense)::Nothing
    model.ext[:objective_sense] = sense
    MOI.set(model.moi_backend.optimizer, MOI.ObjectiveSense(), sense)
    set_transformation_backend_ready(model, false)
    return nothing
end

function JuMP.set_objective(
    model::JuMP.Model,
    sense::MOI.OptimizationSense,
    cost::Integral
)::Nothing

    JuMP.set_objective_sense(model, sense)

    func = toDOINonlinearFunction(cost.expr)
    phase_idx = cost.phase

    nonlin_func = to_NDF(func)

    bolza_obj = DOI.Bolza(
        DOI.NonlinearBoundaryFunction(:+, [0.0]),
        DOI.MultiPhaseIntegral([nonlin_func])
    )


    JuMP.set_objective_function(model, bolza_obj)
    return nothing
end

#for cost with boundary
function JuMP.set_objective(
    model::JuMP.Model,
    sense::MOI.OptimizationSense,
    cost::BoundaryOperator
)::Nothing

    JuMP.set_objective_sense(model, sense)

    # 1. REUSE LOGIC: Convert using the central converter
    # (Relies on the update to toDOINonlinearFunction we made earlier)
    doi_term = toDOINonlinearFunction(cost) 
    
    # 2. Get Phase Index
    # We can extract it from the variable inside the BoundaryOperator
    p_idx = find_phase(cost.arg)

    # 3. CONSTRUCT NBF: Create a NonlinearBoundaryFunction directly
    # Conceptually: Objective = 0 + term
    nbf = DOI.NonlinearBoundaryFunction(
        :+, 
        [doi_term]
    )

    # 4. Set as NBF (Not Bolza)
    JuMP.set_objective_function(model, nbf)
    return nothing
end

# to be speficied for the type of running cost:
function JuMP.set_objective(
    model::JuMP.Model,
    sense::MOI.OptimizationSense,
    running_cost::Function,
    phase::Int
)::Nothing
    JuMP.set_objective_sense(model, sense)
    JuMP.set_objective_function(model, running_cost, phase)
    return nothing
end

#to do: consider bolza cost with finall(theta) + u^2


# --- Placeholder Implementations ---

function _index_type(vref)
    # Return index type (e.g., :VariableIndex, :MeasureIndex)
    return :VariableIndex
end

function set_transformation_backend_ready(model, flag)
    # Update model state as needed
    return
end



