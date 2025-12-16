mutable struct DynamicAffExpr{Ctype,Vtype} <: JuMP.AbstractJuMPScalar
    constant::Ctype
    terms::OrderedDict{Vtype,Ctype}
end

mutable struct DynamicQuadExpr{Ctype,Vtype} <: JuMP.AbstractJuMPScalar
    aff::DynamicAffExpr{Ctype,Vtype}
    terms::OrderedDict{JuMP.UnorderedPair{Vtype}, Ctype}
end