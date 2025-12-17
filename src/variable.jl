
struct DefinedOn
    Phase::PhaseVarRef
end

struct DynamicVarRef{T} <: JuMP.AbstractVariableRef
    model::JuMP.GenericModel{T}
    Index::Int64
    name::Symbol
end

"""

Extending Jump.build_variable
"""
function JuMP.build_variable(
    _err::Function,
    jumpinfo::JuMP.VariableInfo,
    dy_var::DefinedOn;
    kwargs...
)
    
    lb = jumpinfo.lower_bound  === NaN ? -Inf : jumpinfo.lower_bound
    ub = jumpinfo.upper_bound  === NaN ?  Inf : jumpinfo.upper_bound

    # Move them from the normal JuMP bounding system to your extended fields:
    # (This will effectively ignore them at the normal JuMP/MathOptInterface level,
    #  and store them in your custom data structure instead.)
    dv = DynamicVar(
        jumpinfo, 
        dy_var.Phase.Index, # The integer index from the PhaseVarRef
        nothing,            # Initial_value
        nothing,             # Final_value
        [lb, ub],         # Trajectory_bound 
    )

    return dv                                                                                   
end

function JuMP.add_variable(
    model::JuMP.Model,
    dv::DynamicVar,
    name::String = ""
)
    # phase_id = dv.Phase
    # if !haskey(model.ext[:Phases], phase_id)
    #     error("No such phase_id = $phase_id in model.ext[:Phases].")
    # end

    #get the index of the corresponding phase 
    p_index = DOI.PhaseIndex(dv.Phase)
    
    index = DOI.add_dynamic_variable(model.moi_backend.optimizer.model,p_index)

    #call the add_constraint
    MOI.add_constraint(model.moi_backend.optimizer.model, index, MOI.Interval(dv.Trajectory_bound[1],dv.Trajectory_bound[2]))

    local i = model.ext[:varnum][:var] + 1
    model.ext[:varnum][:var] = i

    # Store the dynamic var in your dictionary
    model.ext[:variables][i] = dv
    model.ext[:var_name_to_idx][Symbol(name)] = i

    # Create a name if the user didn't provide one
    local var_symbol = (name == "") ? Symbol("x_$i") : Symbol(name)

    # Return a DynamicVarRef so the user can reference this variable
    return DynamicVarRef(model, i, var_symbol)
end

function JuMP.is_valid(m::JuMP.Model, ref::DynamicVarRef)
    # Check that 'ref.Index' is in your dictionary of dynamic variables,
    # and that 'ref.model === m'.
    return ref.model === m && (ref.name in keys(m.ext[:var_name_to_idx]))
end

function JuMP.name(ref::DynamicVarRef)
    # If the backend doesn't store variable names, return ""
    if !MOI.supports(JuMP.backend(ref.model), MOI.VariableName(), MOI.VariableIndex)
        return ""
    end
    return MOI.get(ref.model, MOI.VariableName(), ref)
end

function MOI.get(m::JuMP.Model, ::MOI.VariableName, ref::DynamicVarRef)
    # The simplest approach: ref.name is a Symbol. Convert to string.
    return string(ref.name)
end
