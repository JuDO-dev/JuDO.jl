"""
    Phase

A sentinel type used to tag a JuDO phase object. It carries no data and is
used internally to distinguish phase-related dispatch.
"""
struct Phase end

"""
    PhaseVar <: JuMP.AbstractVariable

Stores the user-specified bounds for a phase (the independent variable domain,
usually time). The `Initial` and `Final` fields hold the start and end values of
the domain, which may be fixed numbers or free `JuMP.VariableRef`s.

# Fields
- `Initial`: lower bound of the phase domain (`-Inf` if unbounded).
- `Final`: upper bound of the phase domain (`Inf` if unbounded).
"""
mutable struct PhaseVar <: JuMP.AbstractVariable
    #Jumpinfo::JuMP.VariableInfo{Float64,Float64,Float64,Float64}


    Initial::Union{Real, JuMP.VariableRef, Nothing}
    Final::Union{Real, JuMP.VariableRef, Nothing}
end

"""
    PhaseVarRef{M<:JuMP.AbstractModel} <: JuMP.AbstractVariableRef

A reference to a phase that has been registered in a `DynModel`. Holds a
pointer to the parent model, an integer index, and the symbolic name assigned
by the `@phase` macro.

# Fields
- `model`: the `DynModel` that owns this phase.
- `Index`: integer position of the phase in the model's internal registry.
- `name`: the `Symbol` used as the phase identifier (e.g. `:t`).
"""
struct PhaseVarRef{M<:JuMP.AbstractModel} <: JuMP.AbstractVariableRef
    model::M
    Index::Int64
    name::Symbol
end

"""
    DynamicVar <: JuMP.AbstractVariable

Represents a single dynamic (state or control) variable that evolves
continuously over a given phase. Stores JuMP-level bound information plus
JuDO-specific fields for initial/final point values and trajectory bounds.

# Fields
- `Jumpinfo`: standard JuMP `VariableInfo` carrying lower/upper bounds.
- `Phase`: integer index of the phase this variable belongs to.
- `Initial_value`: optional fixed value at the start of the phase.
- `Final_value`: optional fixed value at the end of the phase.
- `Trajectory_bound`: two-element vector `[lb, ub]` bounding the trajectory.
"""
struct DynamicVar <: JuMP.AbstractVariable
    Jumpinfo::JuMP.VariableInfo{<:Real,<:Real,<:Real,<:Real}

    Phase::PhaseVarRef
    Initial_value::Union{Real,Nothing}
    Final_value::Union{Real,Nothing}
    Trajectory_bound::Vector{Real}
end


"""
    DynModel(args...; kwargs...) -> JuMP.Model

Construct a dynamic optimization model. `DynModel` wraps a standard
`JuMP.Model` and initialises the internal data structures required for
dynamic optimization:

- `:Phases` / `:Phasenum` — registry of phases and their count.
- `:variables` / `:varnum` — registry of dynamic variables and their count.
- `:phase_name_to_idx` / `:var_name_to_idx` — name-to-index lookup dictionaries.

Any positional or keyword arguments are forwarded to `JuMP.Model`, so an
optimizer can be attached at construction time:

```julia
using JuDO, Interesso
model = DynModel(Interesso.Optimizer)
```
"""
function DynModel(args...; kwargs...)
    model = JuMP.Model(args...; kwargs...)

    # Register DOI bridges if an optimizer is already attached
    if model.moi_backend.state != MOI.Utilities.NO_OPTIMIZER
        DOI.Bridges.add_all_bridges(model.moi_backend.optimizer, Float64)
    end

    model.ext[:Phasenum] = Dict(:phase=>0)
    model.ext[:Phases] = OrderedDict{Int,PhaseVar}()
    model.ext[:phase_name_to_idx] = Dict{Symbol, Int}()

    model.ext[:varnum] = Dict(:var=>0)
    model.ext[:variables] = OrderedDict{Int,DynamicVar}()
    model.ext[:var_name_to_idx] = Dict{Symbol, Int}()

    #create the option for creating the exact same struct as above when a new phase is desinged 

    return model
end

"""
    @phase(model, name)
    @phase(model, name, start, stop)

Register a new phase (independent variable domain) in `model` under the
identifier `name`.

- **Unbounded form** — `@phase(model, t)`: creates a phase with bounds
  `[-Inf, Inf]`. Use this when the start or end time will be determined by the
  optimizer or set later via boundary constraints.
- **Bounded form** — `@phase(model, t, 0, 10)`: fixes the phase domain to
  `[start, stop]` and immediately adds the corresponding equality constraints
  to the backend.

Returns a `PhaseVarRef` that can be passed to `@variable`, `initial`,
`final`, and other JuDO functions.

# Examples
```julia
model = DynModel(Interesso.Optimizer)

@phase(model, t)           # free phase
@phase(model, t, 0.0, 1.0) # fixed phase from 0 to 1
```
"""
macro phase(model, name, kwargs...)
    esc_model = esc(model)
    phase_sym = esc(Meta.quot(name))  # the symbol used as the key
    name_assingment = esc(name)
    args = collect(kwargs)

    if length(args) == 0
        quote
            # Check for duplicate phase name
            if haskey($esc_model.ext[:phase_name_to_idx], $phase_sym)
                throw(ErrorException(
                    "Phase with name '$(string($phase_sym))' is already defined."
                ))
            end
            i = $esc_model.ext[:Phasenum][:phase] + 1
            $esc_model.ext[:Phasenum][:phase] = i

            
            $esc_model.ext[:phase_name_to_idx][$phase_sym] = i
            $esc_model.ext[:Phases][i] = PhaseVar(-Inf, Inf)

            DOI.add_phase($esc_model.moi_backend.optimizer.model)

            
            local ref = PhaseVarRef($esc_model, i, $phase_sym)
            $(name_assingment) = ref
            return ref
        end
        
        
    else 
        esc_start = esc(args[1])
        esc_stop = esc(args[2])
        quote
            # Check for duplicate phase name
            if haskey($esc_model.ext[:phase_name_to_idx], $phase_sym)
                throw(ErrorException(
                    "Phase with name '$(string($phase_sym))' is already defined."
                ))
            end

            # If both are numeric, check start <= stop
            local _start = $esc_start
            local _stop  = $esc_stop
            if _start isa Number && _stop isa Number
                if _start > _stop
                    throw(ArgumentError("Phase start cannot be greater than stop."))
                end

                i = $esc_model.ext[:Phasenum][:phase] + 1
                $esc_model.ext[:Phasenum][:phase] = i

                
                $esc_model.ext[:phase_name_to_idx][$phase_sym] = i
                $esc_model.ext[:Phases][i] = PhaseVar(_start, _stop)

                DOI.add_phase($esc_model.moi_backend.optimizer.model)
                
                local init = DOI.Initial(DOI.PhaseIndex(i))
                MOI.add_constraint($esc_model.moi_backend.optimizer.model, init, MOI.EqualTo(_start))
                local final = DOI.Final(DOI.PhaseIndex(i))
                MOI.add_constraint($esc_model.moi_backend.optimizer.model, final, MOI.EqualTo(_stop))

                local ref = PhaseVarRef($esc_model, i, $phase_sym)
                $(name_assingment) = ref
                return ref

            end
            
            i = $esc_model.ext[:Phasenum][:phase] + 1
            $esc_model.ext[:Phasenum][:phase] = i

            
            $esc_model.ext[:phase_name_to_idx][$phase_sym] = i
            $esc_model.ext[:Phases][i] = PhaseVar(_start, _stop)

            DOI.add_phase($esc_model.moi_backend.optimizer.model)

            
            local ref = PhaseVarRef($esc_model, i, $phase_sym)
            $(name_assingment) = ref
            return ref

        end
    
    end
end

function JuMP.is_valid(model::JuMP.Model, variable_ref::PhaseVarRef)
    _m = variable_ref.model.ext[:phase_name_to_idx]
    _v = variable_ref.name 
    return model === variable_ref.model && (_v in keys(_m) ) 
    
end 

function JuMP.name(v::PhaseVarRef)
    model = v.model
    if !MOI.supports(JuMP.backend(model), MOI.VariableName(), MOI.VariableIndex)
        return ""
    end
    return MOI.get(model, MOI.VariableName(), v)::String
end

function MOI.get(model::JuMP.Model, n::MOI.VariableName, v::PhaseVarRef)
    # print("here")
    key = [k for (k, j) in model.ext[:phase_name_to_idx] if j == v.Index]
    return string(key[1])
end

"""
    get_phase(model) -> OrderedDict{Int, PhaseVar}

Return the ordered dictionary mapping phase indices to their `PhaseVar` data
stored in `model`.
"""
function get_phase(model)
    return model.ext[:Phases]
end

"""
    get_phasenum(model) -> Dict{Symbol, Int}

Return the counter dictionary (key `:phase`) tracking how many phases have
been added to `model`.
"""
function get_phasenum(model)
    return model.ext[:Phasenum]
end

"""
    get_var(model) -> OrderedDict{Int, DynamicVar}

Return the ordered dictionary mapping variable indices to their `DynamicVar`
data stored in `model`.
"""
function get_var(model)
    return model.ext[:variables]
end

"""
    get_varnum(model) -> Dict{Symbol, Int}

Return the counter dictionary (key `:var`) tracking how many dynamic variables
have been added to `model`.
"""
function get_varnum(model)
    return model.ext[:varnum]
end
