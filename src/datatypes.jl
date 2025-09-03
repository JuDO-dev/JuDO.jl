struct Phase end

mutable struct PhaseVar <: JuMP.AbstractVariable
    #Jumpinfo::JuMP.VariableInfo{Float64,Float64,Float64,Float64}
    
    Initial::Union{Real, JuMP.VariableRef, Nothing}
    Final::Union{Real, JuMP.VariableRef, Nothing}
end

struct PhaseVarRef{M<:JuMP.AbstractModel} <: JuMP.AbstractVariableRef
    model::M
    Index::Int64
    name::Symbol
end

struct DynamicVar <: JuMP.AbstractVariable
    Jumpinfo::JuMP.VariableInfo{<:Real,<:Real,<:Real,<:Real}
    
    Phase::Int64
    Initial_value::Union{Real,Nothing}
    Final_value::Union{Real,Nothing}
    Trajectory_bound::Vector{Real}
end

# mutable struct DynamicVarData 
#     variable::DynamicVar
#     name::String
# end

"""
    DynModel <: Abstract_Dynamic_Model

    Storing, displaying the information of the model
"""
function DynModel(args...; kwargs...)
    model = JuMP.Model(args...; kwargs...)

    model.ext[:Phasenum] = Dict(:phase=>0)
    model.ext[:Phases] = OrderedDict{Int,PhaseVar}()
    model.ext[:phase_name_to_idx] = Dict{Symbol, Int}()

    model.ext[:varnum] = Dict(:var=>0)
    model.ext[:variables] = OrderedDict{Int,DynamicVar}()
    model.ext[:var_name_to_idx] = Dict{Symbol, Int}()

    #create the option for creating the exact same struct as above when a new phase is desinged 

    return model
end

# macro phase(model, name, start, stop)
#     esc_model = esc(model)
#     quote
#         $esc_model.ext[:phases][$(Meta.quot(name))] = ($start, $stop)
#     end
# end

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

            # local init = DOI.Initial(DOI.PhaseIndex(i))
            # MOI.add_constraint($esc_model.moi_backend.optimizer.model, init, MOI.EqualTo(-Inf)) #need to change if no bound is specified
            # local final = DOI.Final(DOI.PhaseIndex(i))
            # MOI.add_constraint($esc_model.moi_backend.optimizer.model, final, MOI.EqualTo(Inf))

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

            #how to do, is there a bound in moi that combines less than and greater than 
            # local init = DOI.Initial(DOI.PhaseIndex(i))
            # MOI.add_constraint($esc_model.moi_backend.optimizer.model, init, MOI.Interval(_start[1],_start[2]))
            # local final = DOI.Final(DOI.PhaseIndex(i))
            # MOI.add_constraint($esc_model.moi_backend.optimizer.model, final, MOI.Interval(_stop[1],_stop[2]))

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

function MOI.get(model::JuMP.Model, ::MOI.VariableName, v::PhaseVarRef)
    # print("here")
    key = [k for (k, j) in model.ext[:phase_name_to_idx] if j == v.Index]
    return string(key[1])
end

function get_phase(model::JuMP.Model)
    return model.ext[:Phases]
end

function get_phasenum(model::JuMP.Model)
    return model.ext[:Phasenum]
end

function get_var(model::JuMP.Model)
    return model.ext[:variables]
end

function get_varnum(model::JuMP.Model)
    return model.ext[:varnum]
end
