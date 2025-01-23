mutable struct AlgeAffineExpr{CoefType,VarType} <: AbstractJuMPScalar
    constant::CoefType
    terms::OrderedDict{VarType,CoefType}
end

function _build_algeaff_expr(constant::V, coef::V, var::K) where {V,K}
    println(222)
    terms = OrderedDict{K,V}()
    terms[var] = coef
    return AlgeaffineExpr{V,K}(constant, terms)
end

function _build_aff_expr(
    constant::V,
    coef1::V,
    var1::K,
    coef2::V,
    var2::K,
) where {V,K}
    if isequal(var1, var2)
        return _build_algeaff_expr(constant, coef1 + coef2, var1)
    end
    terms = OrderedDict{K,V}()
    terms[var1] = coef1
    terms[var2] = coef2
    return AlgeaffineExpr{V,K}(constant, terms)
end