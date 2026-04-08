#default constant support type of the variable in JuDO
const_type(::Type{<:DynamicVarRef}) = Float64

convert_type(::Type{T},x) where {T} = convert(T,x)

"""
    DynamicAffExpr{Ctype, Vtype} <: JuMP.AbstractJuMPScalar

An affine expression over dynamic variables of the form

    constant + Σ coeff_i * var_i

where each `var_i` is a `DynamicVarRef`. Produced automatically by arithmetic
operations such as `x + 2.0` or `3*x - y`.

# Fields
- `constant`: scalar offset of type `Ctype` (typically `Float64`).
- `terms`: ordered mapping from each `DynamicVarRef` to its coefficient.
"""
mutable struct DynamicAffExpr{Ctype,Vtype} <: JuMP.AbstractJuMPScalar
    constant::Ctype
    terms::OrderedDict{Vtype,Ctype}
end

"""
    DynamicQuadExpr{Ctype, Vtype} <: JuMP.AbstractJuMPScalar

A quadratic expression over dynamic variables of the form

    affine_part + Σ coeff_ij * var_i * var_j

Produced automatically by operations such as `x * y` or `x^2`.

# Fields
- `aff`: the affine part as a `DynamicAffExpr`.
- `terms`: ordered mapping from `JuMP.UnorderedPair{Vtype}` to its coefficient.
"""
mutable struct DynamicQuadExpr{Ctype,Vtype} <: JuMP.AbstractJuMPScalar
    aff::DynamicAffExpr{Ctype,Vtype}
    terms::OrderedDict{JuMP.UnorderedPair{Vtype}, Ctype}
end

function _build_aff_expr(constant::C,coeff::C,var::V) where {C,V}
    terms = OrderedDict{V,C}()
    terms[var] = coeff
    return DynamicAffExpr{C,V}(constant, terms)
end

# Define zero for custom types.
Base.zero(::Type{DynamicAffExpr{C,V}}) where {C,V} =
    DynamicAffExpr(zero(C), OrderedDict{V,C}())
Base.zero(::Type{DynamicQuadExpr{C,V}}) where {C,V} =
    DynamicQuadExpr(zero(DynamicAffExpr{C,V}), OrderedDict{JuMP.UnorderedPair{V},C}())

function JuMP.function_string(mode::MIME, expr::DynamicAffExpr{C,V}) where {C,V}
    parts = String[]
    if expr.constant != 0
        push!(parts, string(expr.constant))
    end
    for (var, coef) in expr.terms
        var_str = JuMP.function_string(mode, var)
        # If coefficient is one, show just the variable.
        if coef == 1
            push!(parts, var_str)
        else
            push!(parts, string(coef, "*", var_str))
        end
    end
    return isempty(parts) ? "0" : join(parts, " + ")
end

# Unary minus
function Base.:-(x::DynamicVarRef)
    con = convert_type(const_type(typeof(x)),0)
    return _build_aff_expr(con, -one(con), x)
end

# Addition of a DynamicVarRef and a number:
function Base.:+(x::DynamicVarRef, c::Number)
    T = const_type(typeof(x))
    c_T = convert_type(T, c)
    return _build_aff_expr(c_T, one(c_T), x)
end
Base.:+(c::Number, x::DynamicVarRef) = x + c

# Subtraction: x - c
function Base.:-(x::DynamicVarRef, c::Number)
    return x + (-c)
end
# Subtraction: c - x
function Base.:-(c::Number, x::DynamicVarRef)
    T = const_type(typeof(x))
    c_T = convert_type(T, c)
    return _build_aff_expr(c_T, -one(c_T), x)
end

# Multiplication: DynamicVarRef times a constant
function Base.:*(x::DynamicVarRef, c::Number)
    T = const_type(typeof(x))
    c_T = convert_type(T, c)
    if iszero(c_T)
        return DynamicAffExpr(zero(T), OrderedDict{typeof(x), T}())
    else
        return _build_aff_expr(zero(T), c_T, x)
    end
end
Base.:*(c::Number, x::DynamicVarRef) = x * c

# Addition: DynamicVarRef + DynamicVarRef yields an affine expression.
function Base.:+(x::DynamicVarRef, y::DynamicVarRef)
    T = const_type(typeof(x))
    expr_x = _build_aff_expr(zero(T), one(T), x)
    expr_y = _build_aff_expr(zero(T), one(T), y)
    return expr_x + expr_y
end

# Subtraction: DynamicVarRef - DynamicVarRef.
function Base.:-(x::DynamicVarRef, y::DynamicVarRef)
    T = const_type(typeof(x))
    expr_x = _build_aff_expr(zero(T), one(T), x)
    expr_y = _build_aff_expr(zero(T), one(T), y)
    return expr_x - expr_y
end

#########################
function Base.:-(expr::DynamicAffExpr{C,V}) where {C,V}
    new_terms = OrderedDict{V,C}()
    for (k, coef) in expr.terms
        new_terms[k] = -coef
    end
    return DynamicAffExpr{C,V}(-expr.constant, new_terms)
end

function Base.:+(expr::DynamicAffExpr{C,V}, a::Number) where {C,V}
    return DynamicAffExpr{C,V}(expr.constant + a, expr.terms)
end
function Base.:+(a::Number, expr::DynamicAffExpr{C,V}) where {C,V}
    return expr + a
end

function Base.:-(expr::DynamicAffExpr{C,V}, a::Number) where {C,V}
    return expr + (-a)
end
function Base.:-(a::Number, expr::DynamicAffExpr{C,V}) where {C,V}
    return a + (-expr)
end
function Base.:*(expr::DynamicAffExpr{C,V}, a::Number) where {C,V}
    new_const = expr.constant * a
    new_terms = OrderedDict{V,C}()
    for (k, coef) in expr.terms
        new_terms[k] = coef * a
    end
    return DynamicAffExpr{C,V}(new_const, new_terms)
end
function Base.:*(a::Number, expr::DynamicAffExpr{C,V}) where {C,V}
    return expr * a
end
function Base.:/(expr::DynamicAffExpr{C,V}, a::Number) where {C,V}
    new_const = expr.constant / a
    new_terms = OrderedDict{V,C}()
    for (k, coef) in expr.terms
        new_terms[k] = coef / a
    end
    return DynamicAffExpr{C,V}(new_const, new_terms)
end


# DynamicAffExpr -- DynamicVarRef addition:
function Base.:+(lhs::DynamicAffExpr{C,V}, rhs::DynamicVarRef) where {C,V<:DynamicVarRef}
    # Make a copy of lhs and add a term with coefficient one.
    new_expr = DynamicAffExpr(lhs.constant, copy(lhs.terms))
    new_expr.terms[rhs] = get(new_expr.terms, rhs, zero(C)) + one(C)
    return new_expr
end
Base.:+(lhs::DynamicVarRef, rhs::DynamicAffExpr{C,V}) where {C,V<:DynamicVarRef} = rhs + lhs

function Base.:-(lhs::DynamicAffExpr{C,V}, rhs::DynamicVarRef) where {C,V<:DynamicVarRef}
    new_expr = DynamicAffExpr(lhs.constant, copy(lhs.terms))
    new_expr.terms[rhs] = get(new_expr.terms, rhs, zero(C)) - one(C)
    return new_expr
end
function Base.:-(lhs::DynamicVarRef, rhs::DynamicAffExpr{C,V}) where {C,V<:DynamicVarRef}
    lhs_aff = _build_aff_expr(zero(C), one(C), lhs)
    return lhs_aff - rhs
end


# Now define addition for two DynamicAffExpr's.
function Base.:+(A::DynamicAffExpr{C, V}, B::DynamicAffExpr{C, V}) where {C, V}
    constant = A.constant + B.constant
    new_terms = copy(A.terms)
    for (var, coef) in B.terms
        new_terms[var] = get(new_terms, var, zero(C)) + coef
    end
    return DynamicAffExpr{C, V}(constant, new_terms)
end

# And subtraction for two DynamicAffExpr's.
function Base.:-(A::DynamicAffExpr{C, V}, B::DynamicAffExpr{C, V}) where {C, V}
    constant = A.constant - B.constant
    new_terms = copy(A.terms)
    for (var, coef) in B.terms
        new_terms[var] = get(new_terms, var, zero(C)) - coef
    end
    return DynamicAffExpr{C, V}(constant, new_terms)
end


# Print a DynamicQuadExpr by printing its affine part and quadratic terms.
function JuMP.function_string(mode::MIME, quad::DynamicQuadExpr{C,V}) where {C,V}
    aff_str = JuMP.function_string(mode, quad.aff)
    parts = String[]
    for (up, coef) in quad.terms
        
        a_str = JuMP.function_string(mode, up.a)
        b_str = JuMP.function_string(mode, up.b)
        term_str = (a_str == b_str) ? string(a_str, "^2") : string(a_str, "*", b_str)
        if coef == 1
            push!(parts, term_str)
        elseif coef == -1
            push!(parts, "-" * term_str)
        else
            push!(parts, string(coef, "*", term_str))
        end
    end
    quad_str = isempty(parts) ? "" : join(parts, " + ")
    if aff_str == "0"
        return quad_str
    elseif quad_str == ""
        return aff_str
    else
        return aff_str * " + " * quad_str
    end
end

function Base.:+(Q::DynamicQuadExpr{C,V}, c::Number) where {C,V}
    # Add the constant to the affine part.
    new_aff = Q.aff + c  # (this uses our DynamicAffExpr + Number operator)
    return DynamicQuadExpr(new_aff, Q.terms)
end
Base.:+(c::Number, Q::DynamicQuadExpr{C,V}) where {C,V} = Q + c

function Base.:-(Q::DynamicQuadExpr{C,V}, c::Number) where {C,V}
    return Q + (-c)
end
function Base.:-(c::Number, Q::DynamicQuadExpr{C,V}) where {C,V}
    return c + (-Q)
end

function Base.:-(Q::DynamicQuadExpr{C,V}) where {C,V}
    new_aff = -Q.aff
    new_terms = OrderedDict{JuMP.UnorderedPair{V}, C}()
    for (up, coef) in Q.terms
        new_terms[up] = -coef
    end
    return DynamicQuadExpr(new_aff, new_terms)
end


# (a) Multiplication of two DynamicVarRef's produces a quadratic expression.
function Base.:*(x::DynamicVarRef, y::DynamicVarRef)
    T = const_type(typeof(x))
    zero_aff = zero(DynamicAffExpr{T,typeof(x)})
    terms = OrderedDict{JuMP.UnorderedPair{typeof(x)}, T}()
    terms[JuMP.UnorderedPair(x, y)] = one(T)
    return DynamicQuadExpr(zero_aff, terms)
end


# (a2) Multiplication of two DynamicVarRef's using ^2.
function Base.:^(x::DynamicVarRef, n::Integer)
    T = const_type(typeof(x))
    if n == 0
        return convert(T, 1)  # return the constant one
    elseif n == 1
        return x
    elseif n == 2
        return x * x   # use our multiplication of two DynamicVarRefs to yield a quadratic expression
    else
        # Fallback: treat as nonlinear expression (or error)
        error("Exponentiation for n > 2 not implemented for DynamicVarRef")
    end
end

function Base.:^(x::DynamicVarRef, n::Number)
    return _build_nonlin_expr(:^, x, n)
end

# (b) Multiplication of a DynamicVarRef with a DynamicAffExpr.
function Base.:*(x::DynamicVarRef, aff::DynamicAffExpr{C,V}) where {C,V<:DynamicVarRef}
    if !iszero(aff.constant)
        aff_part = x * aff.constant   # using our DynamicVarRef * Number operator
    else
        aff_part = zero(DynamicAffExpr{C,V})
    end
    quad_terms = OrderedDict{JuMP.UnorderedPair{V}, C}()
    for (var, coef) in aff.terms
        # Multiply x and var to form a quadratic term.
        qexpr = x * var   # returns a DynamicQuadExpr with a single quadratic term
        for (up, qcoef) in qexpr.terms
            quad_terms[up] = get(quad_terms, up, zero(C)) + coef * qcoef
        end
    end
    return DynamicQuadExpr(aff_part, quad_terms)
end
Base.:*(aff::DynamicAffExpr{C,V}, x::DynamicVarRef) where {C,V<:DynamicVarRef} = x * aff

# (c) Multiplication of two DynamicAffExpr's to yield a quadratic expression.
function Base.:*(A::DynamicAffExpr{C,V}, B::DynamicAffExpr{C,V}) where {C,V<:DynamicVarRef}
    if !iszero(B.constant)
        aff_part = A * B.constant  # This uses our DynamicVarRef * Number on each term of A
    else
        aff_part = zero(DynamicAffExpr{C,V})
    end
    quad_terms = OrderedDict{JuMP.UnorderedPair{V}, C}()
    for (var1, coef1) in A.terms
        for (var2, coef2) in B.terms
            up = JuMP.UnorderedPair(var1, var2)
            quad_terms[up] = get(quad_terms, up, zero(C)) + coef1 * coef2
        end
    end
    return DynamicQuadExpr(aff_part, quad_terms)
end

# (d) Addition and subtraction for DynamicQuadExpr.
# Helper: convert a DynamicVarRef into a DynamicQuadExpr with an affine part only.
function to_quad(x::DynamicVarRef)
    T = const_type(typeof(x))
    # Build an affine expression representing x
    aff = _build_aff_expr(zero(T), one(T), x)
    # Create a quadratic expression with no quadratic terms.
    return DynamicQuadExpr(aff, OrderedDict{JuMP.UnorderedPair{typeof(x)}, T}())
end

# Helper: convert an affine expression to a quadratic expression.
function to_quad(expr::DynamicAffExpr{C,V}) where {C,V}
    return DynamicQuadExpr(expr, OrderedDict{JuMP.UnorderedPair{V}, C}())
end

function Base.:+(q::DynamicQuadExpr{C,V}, v::DynamicVarRef) where {C,V}
    new_aff = q.aff + v      # uses your DynamicAffExpr + DynamicVarRef overload
    return DynamicQuadExpr(new_aff, copy(q.terms))
end
Base.:+(q::DynamicVarRef, v::DynamicQuadExpr{C,V}) where {C,V} = v + q

function Base.:-(q::DynamicQuadExpr{C,V}, v::DynamicVarRef) where {C,V}
    new_aff = q.aff - v
    return DynamicQuadExpr(new_aff, copy(q.terms))
end
function Base.:-(q::DynamicVarRef, v::DynamicQuadExpr{C,V}) where {C,V}
    return to_quad(q) - v
end

function Base.:+(q::DynamicQuadExpr{C,V}, a::DynamicAffExpr{C,V}) where {C,V}
    new_aff = q.aff + a
    return DynamicQuadExpr(new_aff, copy(q.terms))
end
Base.:+(q::DynamicAffExpr, v::DynamicQuadExpr{C,V}) where {C,V} = v + q

function Base.:-(q::DynamicQuadExpr{C,V}, a::DynamicAffExpr{C,V}) where {C,V}
    new_aff = q.aff - a
    return DynamicQuadExpr(new_aff, copy(q.terms))
end
function Base.:-(q::DynamicAffExpr{C,V}, v::DynamicQuadExpr{C,V}) where {C,V}
    return to_quad(q) - v
end

function Base.:+(Q1::DynamicQuadExpr{C,V}, Q2::DynamicQuadExpr{C,V}) where {C,V}
    new_aff = Q1.aff + Q2.aff
    new_terms = copy(Q1.terms)
    for (up, coef) in Q2.terms
        new_terms[up] = get(new_terms, up, zero(C)) + coef
    end
    return DynamicQuadExpr(new_aff, new_terms)
end

function Base.:-(Q1::DynamicQuadExpr{C,V}, Q2::DynamicQuadExpr{C,V}) where {C,V}
    new_aff = Q1.aff - Q2.aff
    new_terms = copy(Q1.terms)
    for (up, coef) in Q2.terms
        new_terms[up] = get(new_terms, up, zero(C)) - coef
    end
    return DynamicQuadExpr(new_aff, new_terms)
end

# (e) Multiplication of a constant with a DynamicQuadExpr.
function Base.:*(a::Number, Q::DynamicQuadExpr{C,V}) where {C,V}
    new_aff = a * Q.aff
    new_terms = OrderedDict{JuMP.UnorderedPair{V}, C}()
    for (up, coef) in Q.terms
        new_terms[up] = a * coef
    end
    return DynamicQuadExpr(new_aff, new_terms)
end
Base.:*(Q::DynamicQuadExpr{C,V}, a::Number) where {C,V} = a * Q



