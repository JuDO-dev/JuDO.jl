# abstract type variable_data end

# mutable struct Phase_data <: variable_data
#     Sym::Symbol
#     Initial::Union{Real,Nothing}
#     Final::Union{Real,Nothing}
# end


function JuMP.build_variable(
    _err::Function,
    jumpinfo::JuMP.VariableInfo,
    dy_var::Type{Phase};
    kwargs...
)
    #check for wrong keywords

    #based on keyword, assign the dynamic variable-related fields to var 
    
    #initialize the variable
    var = PhaseVar(jumpinfo,-Inf,Inf)

    return var                                                                                      
end

function JuMP.add_variable(
    model::JuMP.Model,
    dy_var::PhaseVar,
    name::String = ""
)
    #check if the phase exists

    #dy_var.phase.Sym == model.phases[model.phasenum].Sym ? nothing : error("Phase with name $(dy_var.phase.Sym) is not defined.")

    varnum = get_phasenum(model)
    varnum[:phase] += 1

    data = PhaseVarData(dy_var, name)
    vars = get_phase(model)
    vars[get_phasenum(model)[:phase]] = data

    p_index = DOI.add_phase(model.moi_backend.optimizer.model)

    #build the phase reference
    ref = PhaseVarRef(model,PhaseIndex(varnum[:phase],data))

    return ref
end

#check for valid phase
function JuMP.is_valid(model::JuMP.Model, variable_ref::PhaseVarRef)
    _m = variable_ref.model.ext[:Phases]
    _v = variable_ref.Index.value 
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
    #print(v.Index.value)
    return model.ext[:Phases][v.Index.value].name  
end

# function add_independent(_model,_expr::Array)

#     #check_repetitive_phase_def(_expr)   #a function to check if the phase var is used 
#     newphase = Phase_data(_expr[1],-Inf,Inf)
#     num = get_phasenum(_model)
#     num[:phase] +=1
#     phases = get_phase(_model)
#     phases[num[:phase]] = newphase

#     #DOI.add_phase(_model.Optimizer)   # no optimizer has been added yet
    
#     #returning a variable with all phase data inside
#     return  newphase
# end

# function Base.show(io::IO, x::Phase_data)
#     print(io,x.Sym)
# end