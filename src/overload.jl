using JuMP

#JuMP._complex_convert_type()
#JuMP._complex_convert()
# Define custom type
struct algebraic_affine
    value::Float64
end

function Base.:+(lhs::_Const, rhs::algebraic_affine)
    println(666)
    constant = JuMP._complex_convert(value_type(typeof(rhs)), lhs)
    return _build_algeaff_expr(constant, one(constant), rhs)
end
function Base.:-(lhs::_Const, rhs::algebraic_affine)
    constant = JuMP._complex_convert(value_type(typeof(rhs)), lhs)
    return _build_algeaff_expr(constant, -one(constant), rhs)
end
function Base.:*(lhs::_Const, rhs::algebraic_affine)
    coef = JuMP._complex_convert(value_type(typeof(rhs)), lhs)
    if iszero(coef)
        return zero(GenericAffExpr{typeof(coef),typeof(rhs)})
    else
        return _build_algeaff_expr(zero(coef), coef, rhs)
    end
end



# Implement basic arithmetic operations
Base.:+(x::algebraic_affine, y::algebraic_affine) = algebraic_affine(x.value + y.value)
Base.:-(x::algebraic_affine, y::algebraic_affine) = algebraic_affine(x.value - y.value)
Base.:*(x::algebraic_affine, y::algebraic_affine) = algebraic_affine(x.value * y.value)
Base.:/(x::algebraic_affine, y::algebraic_affine) = algebraic_affine(x.value / y.value)

# Define conversion and promotion rules
Base.convert(::Type{T}, x::algebraic_affine) where {T<:AbstractFloat} = T(x.value)
Base.promote_rule(::Type{algebraic_affine}, ::Type{<:AbstractFloat}) = algebraic_affine

# Extend JuMP functions
function _complex_convert_type(::Type{T}, ::Type{<:algebraic_affine}) where {T}
    return T
end

function _complex_convert(::Type{T}, x::algebraic_affine) where {T}
    return convert(T, x.value)
end

# Extend arithmetic operations
function Base.:+(lhs::algebraic_affine, rhs::AbstractVariableRef)
    println(555)
    constant = _complex_convert(value_type(typeof(rhs)), lhs)
    return _build_algeaff_expr(constant, one(constant), rhs)
end

function Base.:-(lhs::algebraic_affine, rhs::AbstractVariableRef)
    constant = _complex_convert(value_type(typeof(rhs)), lhs)
    return _build_algeaff_expr(constant, -one(constant), rhs)
end

function Base.:*(lhs::algebraic_affine, rhs::AbstractVariableRef)
    coef = _complex_convert(value_type(typeof(rhs)), lhs)
    if iszero(coef)
        return zero(GenericAffExpr{typeof(coef), typeof(rhs)})
    else
        return _build_algeaff_expr(zero(coef), coef, rhs)
    end
end

# Extend exponentiation handling
function Base.:^(lhs::algebraic_affine, rhs::Integer)
    if rhs == 0
        return algebraic_affine(1.0)
    elseif rhs > 0
        result = lhs
        for i in 2:rhs
            result *= lhs
        end
        return result
    else
        error("Exponents less than 0 are not supported.")
    end
end


