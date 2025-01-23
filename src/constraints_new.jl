
#define the own expr term type for f

# struct DynamicConIndex
#     value::Int64
# end

#define a subtype of AbstractConstraint of JuMP for the return of build()
struct DynConstraint{T<:MOI.AbstractScalarFunction} <: JuMP.AbstractConstraint
    #name::String
    f::JuMP.GenericAffExpr
    type::Type{T}
end

struct DynConstraintIndex
    value::Int64
end

struct DynamicConRef
    model::JuMP.Model
    index::DynConstraintIndex
end

function JuMP.build_constraint(
    error_fn::Function,
    f::JuMP.GenericAffExpr, 
    set::MOI.EqualTo,
    extra::Type{<:MOI.AbstractScalarFunction}
)
   
    #get the var of the highest order term (might be definitions of initial using t^2 == 4)

    #error if the terms contain more than one phase var
   
    return DynConstraint(f,extra)
end

#dispatch to add_constraint wih different types, initial, final, differential... 
function JuMP.add_constraint(
    model::JuMP.Model,
    con::DynConstraint,
    name::String,
)
    type = con.type

    ref = JuMP.add_constraint(model,type,name)

    return ref
end

#add initial phase constraints 
function JuMP.add_constraint(
    model::JuMP.Model,
    con::DynConstraint{DOI.Initial}, #use Type{}? but cannot use type, because the info will be lost, then use if else?
    name::String,
)

    #add the initial and final constraints to phase, call 

    #get the phase index
    p_index = DOI.PhaseIndex(collect(keys(con.f.terms))[1].Index.value)
    #print(con.f.constant)

    index = MOI.add_constraint(model.moi_backend.optimizer.model, DOI.Initial(p_index), MOI.EqualTo{Float64}(-con.f.constant))

    ref = DynamicConRef(model,DynConstraintIndex(index.value))
    return ref
end

#add final phase constraints 
function JuMP.add_constraint(
    model::JuMP.Model,
    con::DynConstraint{DOI.Final}, #use Type{}? but cannot use type, because the info will be lost, then use if else?
    name::String,
)

    #add the initial and final constraints to phase, call 

    #get the phase index
    p_index = DOI.PhaseIndex(collect(keys(con.f.terms))[1].Index.value)

    index = MOI.add_constraint(model.moi_backend.optimizer.model, DOI.Final(p_index), MOI.EqualTo{Float64}(-con.f.constant))

    ref = DynamicConRef(model,DynConstraintIndex(index.value))
    return ref
end

function Base.show(io::IO, varref::DynamicConRef)
    print(io, "Dynamic Constraint")
end

# index = ConstraintIndex(model.next_con_index)
#     cref = JuMP.ConstraintRef(model, index, JuMP.shape(c))
#     model.constraints[index] = c
#     JuMP.set_name(cref, name)
#     return cref