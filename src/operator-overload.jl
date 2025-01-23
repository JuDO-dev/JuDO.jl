# macro outer_macro(m,args...)
#     a=collect(args)

#     quote
#         JuMP.@variable $(esc(m)), :x, $(esc(a[2]))
#     end
# end


struct DynamicVarIndex
    value::Int64
    phase::PhaseVar
end

struct DynamicVarRef{M<:JuMP.AbstractModel} <: JuMP.AbstractVariableRef
    model::M
    Index::DynamicVarIndex
end


#get_dyvar(v::DynamicVar) = v.variable

"""

Extending Jump.build_variable
"""
function JuMP.build_variable(
    _err::Function,
    jumpinfo::JuMP.VariableInfo,
    dy_var::Dynamic;
    kwargs...
)
    #check for wrong keywords

    #based on keyword, assign the dynamic variable-related fields to var 

    #initialize the variable
    var = DynamicVar(jumpinfo,dy_var.Phase.Index,[-Inf,Inf],[-Inf,Inf],nothing)

    return var                                                                                      
end

function JuMP.add_variable(
    model::JuMP.Model,
    dy_var::DynamicVar,
    name::String = ""
)
    #check if the phase exists

    #dy_var.phase.Sym == model.phases[model.phasenum].Sym ? nothing : error("Phase with name $(dy_var.phase.Sym) is not defined.")

    varnum = get_varnum(model)
    varnum[:var] += 1

    data = DynamicVarData(dy_var, name)
    vars = get_var(model)
    vars[get_varnum(model)[:var]] = data

    #calles DOI add_variable
    #print(dy_var.phase.Sym)
    #print(model.phases[1].Sym)

    #get the index of the corresponding phase 
    p_index = DOI.PhaseIndex(dy_var.Phase.value)
    
    index = DOI.add_dynamic_variable(model.moi_backend.optimizer.model,p_index)

    #detect if jumpinfo has lower_bound or upper_bound fields non empty, then assign to the variable bound
    info = dy_var.Jumpinfo
    if info.has_ub == true && info.has_lb == true
        MOI.add_constraint(model.moi_backend.optimizer.model,index,MOI.Interval(info.lower_bound,info.upper_bound))
    elseif info.has_ub == true && info.has_lb == false
        MOI.add_constraint(model.moi_backend.optimizer.model,index,MOI.Interval(Inf,info.upper_bound))
    elseif info.has_ub == false && info.has_lb == true
        MOI.add_constraint(model.moi_backend.optimizer.model,index,MOI.Interval(info.lower_bound,Inf))
    else
        MOI.add_constraint(model.moi_backend.optimizer.model,index,MOI.Interval(-Inf,Inf))
    end

    #build the variable reference
    ref = DynamicVarRef(model,DynamicVarIndex(varnum[:var],dy_var.Phase.phase.variable))

    return ref
end

function find_key_by_value(dict::OrderedDict, value)
    syms = vec([collect(values(dict))[i].name for i in length(dict)])
    # print(syms)
    # print(value.Sym)
    if value.Sym in syms
        return findfirst(==(value.Sym), syms)
    end
    error("value not found in the dictionary")  # Return nothing if the value is not found
end

#check for valid dynamic variable
function JuMP.is_valid(model::JuMP.Model, variable_ref::DynamicVarRef)
    _m = variable_ref.model.ext[:variables]
    _v = variable_ref.Index.value 
    return model === variable_ref.model && (_v in keys(_m) ) && hasfield(typeof(_m[_v].variable),:Phase) 
    
end 

function JuMP.name(v::DynamicVarRef)
    model = v.model
    if !MOI.supports(JuMP.backend(model), MOI.VariableName(), MOI.VariableIndex)
        return ""
    end
    return MOI.get(model, MOI.VariableName(), v)::String
end

function MOI.get(model::JuMP.Model, n::MOI.VariableName, v::DynamicVarRef)
    # print("here")
    #print(v.Index.value)
    return model.ext[:variables][v.Index.value].name  
end

# function Base.show(io::IO, varref::DynamicVarRef)
#     print(io, "Dynamic Variable")
# end

