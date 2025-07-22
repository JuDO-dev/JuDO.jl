

"""
    MyConstraintRef{M} <: JuMP.AbstractConstraintRef

A reference that JuMP returns to the user when they do `@constraint(...)`.
We store:
 - The parent JuMP model
 - An integer index (key)
"""
# struct MyConstraintRef{M<:JuMP.Model} 
#     model :: M
#     idx   :: Int
# end

mutable struct DynamicAffExpr{Ctype,Vtype} <: JuMP.AbstractJuMPScalar
    constant::Ctype
    terms::OrderedDict{Vtype,Ctype}
end

mutable struct DynamicQuadExpr{Ctype,Vtype} <: JuMP.AbstractJuMPScalar
    aff::DynamicAffExpr{Ctype,Vtype}
    terms::OrderedDict{JuMP.UnorderedPair{Vtype}, Ctype}
end

# mutable struct AffConstraintData <: JuMP.AbstractConstraint
#     func :: DynamicAffExpr{Float64}
#     set  :: MOI.AbstractScalarSet
# end

# function JuMP.build_constraint(
#     error::Function,
#     func::DynamicAffExpr,
#     set::MOI.AbstractScalarSet
# )
#     #check the phase in all the terms in the DynamicAffExpr


#     print("here1")
#     return AffConstraintData(func, set)
# end

# function JuMP.add_constraint(
#     model::JuMP.Model,
#     data::AffConstraintData,
#     name::String = ""
# )
#     print("here2")

#     DOI.add_constraint()

#     # 2) Insert data with a new integer index
#     local i = length(model.ext[:myconstraints]) + 1
#     model.ext[:myconstraints][i] = data

#     # 3) Return a custom reference to the user
#     return MyConstraintRef(model, i)
# end
