#recognize derivative term in a Expr and recognize it as a NonlinearExpr
#make an identifier where JuDO knows which term is the derivative term
#in the dispatch of build_constraint() for NonlinearExpr, build DOI.

# in what cases will a NonlinearExpr be assembled?

# DerivativeTerm now carries a coefficient.
struct DerivativeTerm <: JuMP.AbstractJuMPScalar
    var::DynamicVarRef
    #id::Symbol
    coef::Float64
end

struct NonlinearExpr <: JuMP.AbstractJuMPScalar
    head::Symbol
    args::Vector{Any}
end


# The derivative operator returns a DerivativeTerm with coefficient 1.0.
function derivative(x::DynamicVarRef)
    return DerivativeTerm(x, 1.0)
end

# Custom printing for DerivativeTerm.
function JuMP.function_string(mode::MIME, d::DerivativeTerm)
    base = JuMP.function_string(mode, d.var)
    if mode == MIME("text/plain")
        if d.coef == 1.0
            return base * "\u0307"   # e.g. "x" with a combining dot
        else
            return string(d.coef, "*", base, "\u0307")
        end
    elseif mode == MIME("text/latex")
        if d.coef == 1.0
            return "\\dot{" * base * "}"
        else
            return string(d.coef, "\\dot{", base, "}")
        end
    else
        return string(d)
    end
end
Base.show(io::IO, d::DerivativeTerm) = print(io, JuMP.function_string(MIME("text/plain"), d))


function _build_nonlin_expr(op::Symbol, operands...)
    # The first element in the args is the operator, followed by the operands.
    return NonlinearExpr(:call, [op; operands...])
end

#operations that result in NonlinearExpr
# 1. Division between two DynamicVarRefs.
function Base.:/(a::DynamicVarRef, b::DynamicVarRef)
    return _build_nonlin_expr(:/, a, b)
end

# 2. Division between a DynamicVarRef and a DynamicAffExpr (both orders).
function Base.:/(a::DynamicVarRef, b::DynamicAffExpr)
    return _build_nonlin_expr(:/, a, b)
end
function Base.:/(num::DynamicAffExpr{C,V}, den::DynamicVarRef) where {C,V}
    # Check if the affine expression is exactly a single term (with zero constant) on the given variable.
    if num.constant == 0 && length(num.terms) == 1
        key = first(keys(num.terms))
        if key === den
            # Fully divisible: a * den / den simplifies to a.
            return first(values(num.terms))
        end
    end
    # Otherwise, fall back to building a nonlinear expression.
    return _build_nonlin_expr(:/, num, den)
end

# 3. Division between a DynamicVarRef and a DynamicQuadExpr (both orders).
function Base.:/(a::DynamicVarRef, b::DynamicQuadExpr)
    return _build_nonlin_expr(:/, a, b)
end
function Base.:/(num::DynamicQuadExpr{C,V}, den::DynamicVarRef) where {C,V}
    # Attempt to simplify the affine part.
    affine_simplified = nothing
    can_divide_aff = false
    if num.aff.constant == 0 && length(num.aff.terms) == 1
        key = first(keys(num.aff.terms))
        if key == den
            affine_simplified = first(values(num.aff.terms))
            can_divide_aff = true
        end
    end

    new_terms = OrderedDict{V, C}()
    can_divide_quad = true
    for (up, coeff) in num.terms
        if (up.a == den) || (up.b == den)
            # Determine the other variable in the pair.
            other = (up.a == den) ? up.b : up.a
            new_terms[other] = get(new_terms, other, zero(coeff)) + coeff
        else
            can_divide_quad = false
            break
        end
    end

    if can_divide_quad & can_divide_aff
        # Build a simplified affine expression:
        new_constant = (affine_simplified !== nothing) ? affine_simplified : zero(C)
        simplified_aff = DynamicAffExpr{C,V}(new_constant, new_terms)
        return simplified_aff
    end

    # Otherwise, return a nonlinear expression node.
    return _build_nonlin_expr(:/, num, den)
end


# 4. Division between a DynamicAffExpr and a DynamicQuadExpr (both orders).
function Base.:/(a::DynamicAffExpr, b::DynamicQuadExpr)
    return _build_nonlin_expr(:/, a, b)
end
function Base.:/(num::DynamicQuadExpr{C,V}, den::DynamicAffExpr{C,V}) where {C,V}
    # Check that the denominator is "simple": exactly one term.
    if length(den.terms) == 1
        # Get the denominator's variable, its coefficient, and its constant.
        dvar = first(keys(den.terms))
        dcoef = first(values(den.terms))
        dconst = den.constant

        # Extract numerator coefficients as a polynomial in dvar.
        # For the quadratic part, we expect a term UnorderedPair(dvar, dvar).
        qpair = JuMP.UnorderedPair(dvar, dvar)
        n2 = haskey(num.terms, qpair) ? num.terms[qpair] : zero(C)
        # For the affine part: n0 is the constant and n1 is the coefficient for dvar.
        n0 = num.aff.constant
        n1 = haskey(num.aff.terms, dvar) ? num.aff.terms[dvar] : zero(C)

        # Avoid division by zero.
        if dcoef == 0
            return _build_nonlin_expr(:/, num, den)
        end

        # Solve for the quotient Q = q0 + q1*x, where x represents dvar.
        # Equation 1: q1*dcoef = n2  =>  q1 = n2/dcoef.
        q1 = n2 / dcoef
        # Equation 2: q0*dcoef + q1*dconst = n1  =>  q0 = (n1 - q1*dconst)/dcoef.
        q0 = (n1 - q1*dconst) / dcoef
        # Equation 3: q0*dconst must equal n0.
        if q0*dconst != n0
            # Not exactly divisible.
            return _build_nonlin_expr(:/, num, den)
        end

        # Build the quotient as a DynamicAffExpr.
        quotient_terms = OrderedDict{V, C}()
        if q1 != zero(C)
            quotient_terms[dvar] = q1
        end
        quotient_aff = DynamicAffExpr{C,V}(q0, quotient_terms)
        return quotient_aff
    end
    # Fallback if the denominator is not simple.
    return _build_nonlin_expr(:/, num, den)
end


# 5. Division between a Number and a DynamicVarRef (both orders).
function Base.:/(a::Number, b::DynamicVarRef)
    return _build_nonlin_expr(:/, a, b)
end
function Base.:/(a::DynamicVarRef, b::Number)
    return _build_nonlin_expr(:/, a, b)
end

# 6. Division between a Number and a DynamicAffExpr (both orders).
function Base.:/(a::Number, b::DynamicAffExpr)
    return _build_nonlin_expr(:/, a, b)
end
function Base.:/(a::DynamicAffExpr, b::Number) #####why
    return _build_nonlin_expr(:/, a, b)
end

function Base.:^(a::DynamicAffExpr, b::Number)
    return _build_nonlin_expr(:^, a, b)
end

# 7. Division between a Number and a DynamicQuadExpr (both orders).
function Base.:/(a::Number, b::DynamicQuadExpr)
    return _build_nonlin_expr(:/, a, b)
end
function Base.:/(a::DynamicQuadExpr, b::Number) #####why
    return _build_nonlin_expr(:/, a, b)
end

function Base.:^(a::DynamicQuadExpr, b::Number)
    return _build_nonlin_expr(:^, a, b)
end




#### start with the derivative term
function Base.:-(x::DerivativeTerm)
    return _build_nonlin_expr(:-, x)
end

# DerivativeTerm and Number
function Base.:-(a::DerivativeTerm, b::Number)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:-(a::Number, b::DerivativeTerm)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:+(a::DerivativeTerm, b::Number)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:+(a::Number, b::DerivativeTerm)
    return _build_nonlin_expr(:+, a, b)
end

# DerivativeTerm with DerivativeTerm
function Base.:-(a::DerivativeTerm, b::DerivativeTerm)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:+(a::DerivativeTerm, b::DerivativeTerm)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:*(a::DerivativeTerm, b::DerivativeTerm)
    return _build_nonlin_expr(:*, a, b)
end
function Base.:/(a::DerivativeTerm, b::DerivativeTerm)
    return _build_nonlin_expr(:/, a, b)
end

# Operations with DynamicVarRef
function Base.:-(a::DerivativeTerm, b::DynamicVarRef)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:-(a::DynamicVarRef, b::DerivativeTerm)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:+(a::DerivativeTerm, b::DynamicVarRef)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:+(a::DynamicVarRef, b::DerivativeTerm)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:*(a::DerivativeTerm, b::DynamicVarRef)
    return _build_nonlin_expr(:*, a, b)
end
function Base.:*(a::DynamicVarRef, b::DerivativeTerm)
    return _build_nonlin_expr(:*, a, b)
end

# Operations with DynamicAffExpr
function Base.:-(a::DerivativeTerm, b::DynamicAffExpr)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:-(a::DynamicAffExpr, b::DerivativeTerm)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:+(a::DerivativeTerm, b::DynamicAffExpr)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:+(a::DynamicAffExpr, b::DerivativeTerm)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:*(a::DerivativeTerm, b::DynamicAffExpr)
    return _build_nonlin_expr(:*, a, b)
end
function Base.:*(a::DynamicAffExpr, b::DerivativeTerm)
    return _build_nonlin_expr(:*, a, b)
end

# Operations with DynamicQuadExpr
function Base.:-(a::DerivativeTerm, b::DynamicQuadExpr)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:-(a::DynamicQuadExpr, b::DerivativeTerm)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:+(a::DerivativeTerm, b::DynamicQuadExpr)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:+(a::DynamicQuadExpr, b::DerivativeTerm)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:*(a::DerivativeTerm, b::DynamicQuadExpr)
    return _build_nonlin_expr(:*, a, b)
end
function Base.:*(a::DynamicQuadExpr, b::DerivativeTerm)
    return _build_nonlin_expr(:*, a, b)
end

Base.zero(::Type{NonlinearExpr}) = NonlinearExpr(:call, [:+, 0.0])

function Base.:+(a::NonlinearExpr, b::Number)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:+(a::Number, b::NonlinearExpr)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:-(a::NonlinearExpr, b::Number)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:-(a::Number, b::NonlinearExpr)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:*(a::NonlinearExpr, b::Number)
    return _build_nonlin_expr(:*, a, b)
end
function Base.:*(a::Number, b::NonlinearExpr)
    return _build_nonlin_expr(:*, a, b)
end
function Base.:/(a::NonlinearExpr, b::Number)
    return _build_nonlin_expr(:/, a, b)
end
function Base.:/(a::Number, b::NonlinearExpr)
    return _build_nonlin_expr(:/, a, b)
end
function Base.:^(a::NonlinearExpr, b::Number)
    return _build_nonlin_expr(:^, a, b)
end

function Base.:+(a::NonlinearExpr, b::DynamicVarRef)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:+(a::DynamicVarRef, b::NonlinearExpr)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:-(a::NonlinearExpr, b::DynamicVarRef)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:-(a::DynamicVarRef, b::NonlinearExpr)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:*(a::NonlinearExpr, b::DynamicVarRef)
    return _build_nonlin_expr(:*, a, b)
end
function Base.:*(a::DynamicVarRef, b::NonlinearExpr)
    return _build_nonlin_expr(:*, a, b)
end
function Base.:/(a::NonlinearExpr, b::DynamicVarRef)
    return _build_nonlin_expr(:/, a, b)
end
function Base.:/(a::DynamicVarRef, b::NonlinearExpr)
    return _build_nonlin_expr(:/, a, b)
end

function Base.:+(a::NonlinearExpr, b::DynamicAffExpr)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:+(a::DynamicAffExpr, b::NonlinearExpr)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:-(a::NonlinearExpr, b::DynamicAffExpr)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:-(a::DynamicAffExpr, b::NonlinearExpr)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:*(a::NonlinearExpr, b::DynamicAffExpr)
    return _build_nonlin_expr(:*, a, b)
end
function Base.:*(a::DynamicAffExpr, b::NonlinearExpr)
    return _build_nonlin_expr(:*, a, b)
end
function Base.:/(a::NonlinearExpr, b::DynamicAffExpr)
    return _build_nonlin_expr(:/, a, b)
end
function Base.:/(a::DynamicAffExpr, b::NonlinearExpr)
    return _build_nonlin_expr(:/, a, b)
end

function Base.:+(a::NonlinearExpr, b::DynamicQuadExpr)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:+(a::DynamicQuadExpr, b::NonlinearExpr)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:-(a::NonlinearExpr, b::DynamicQuadExpr)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:-(a::DynamicQuadExpr, b::NonlinearExpr)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:*(a::NonlinearExpr, b::DynamicQuadExpr)
    return _build_nonlin_expr(:*, a, b)
end
function Base.:*(a::DynamicQuadExpr, b::NonlinearExpr)
    return _build_nonlin_expr(:*, a, b)
end
function Base.:/(a::NonlinearExpr, b::DynamicQuadExpr)
    return _build_nonlin_expr(:/, a, b)
end
function Base.:/(a::DynamicQuadExpr, b::NonlinearExpr)
    return _build_nonlin_expr(:/, a, b)
end

# And mixing NonlinearExpr with DerivativeTerm
function Base.:+(a::NonlinearExpr, b::DerivativeTerm)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:+(a::DerivativeTerm, b::NonlinearExpr)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:-(a::NonlinearExpr, b::DerivativeTerm)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:-(a::DerivativeTerm, b::NonlinearExpr)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:*(a::NonlinearExpr, b::DerivativeTerm)
    return _build_nonlin_expr(:*, a, b)
end
function Base.:*(a::DerivativeTerm, b::NonlinearExpr)
    return _build_nonlin_expr(:*, a, b)
end
function Base.:/(a::NonlinearExpr, b::DerivativeTerm)
    return _build_nonlin_expr(:/, a, b)
end
function Base.:/(a::DerivativeTerm, b::NonlinearExpr)
    return _build_nonlin_expr(:/, a, b)
end

# Operations between NonlinearExpr nodes (for nesting)
function Base.:-(a::NonlinearExpr, b::NonlinearExpr)
    return _build_nonlin_expr(:-, a, b)
end
function Base.:+(a::NonlinearExpr, b::NonlinearExpr)
    return _build_nonlin_expr(:+, a, b)
end
function Base.:*(a::NonlinearExpr, b::NonlinearExpr)
    return _build_nonlin_expr(:*, a, b)
end
function Base.:/(a::NonlinearExpr, b::NonlinearExpr)
    return _build_nonlin_expr(:/, a, b)
end

Base.:sin(x::Union{DerivativeTerm, DynamicVarRef, DynamicAffExpr, DynamicQuadExpr, NonlinearExpr}) = _build_nonlin_expr(:sin, x)
Base.:cos(x::Union{DerivativeTerm, DynamicVarRef, DynamicAffExpr, DynamicQuadExpr, NonlinearExpr}) = _build_nonlin_expr(:cos, x)
Base.:tan(x::Union{DerivativeTerm, DynamicVarRef, DynamicAffExpr, DynamicQuadExpr, NonlinearExpr}) = _build_nonlin_expr(:tan, x)
Base.:sinh(x::Union{DerivativeTerm, DynamicVarRef, DynamicAffExpr, DynamicQuadExpr, NonlinearExpr}) = _build_nonlin_expr(:sinh, x)
Base.:cosh(x::Union{DerivativeTerm, DynamicVarRef, DynamicAffExpr, DynamicQuadExpr, NonlinearExpr}) = _build_nonlin_expr(:cosh, x)
Base.:tanh(x::Union{DerivativeTerm, DynamicVarRef, DynamicAffExpr, DynamicQuadExpr, NonlinearExpr}) = _build_nonlin_expr(:tanh, x)

Base.:log(x::Union{DerivativeTerm, DynamicVarRef, DynamicAffExpr, DynamicQuadExpr, NonlinearExpr}) = _build_nonlin_expr(:log, x)
Base.:log10(x::Union{DerivativeTerm, DynamicVarRef, DynamicAffExpr, DynamicQuadExpr, NonlinearExpr}) = _build_nonlin_expr(:log10, x)
Base.:log2(x::Union{DerivativeTerm, DynamicVarRef, DynamicAffExpr, DynamicQuadExpr, NonlinearExpr}) = _build_nonlin_expr(:log2, x)

Base.:exp(x::Union{DerivativeTerm, DynamicVarRef, DynamicAffExpr, DynamicQuadExpr, NonlinearExpr}) = _build_nonlin_expr(:exp, x)
Base.:sqrt(x::Union{DerivativeTerm, DynamicVarRef, DynamicAffExpr, DynamicQuadExpr, NonlinearExpr}) = _build_nonlin_expr(:sqrt, x)

function JuMP.function_string(mode::MIME, expr::NonlinearExpr)
    if expr.head == :call
        # In a :call expression, the first element of args is the operator.
        op = expr.args[1]
        operands = expr.args[2:end]
        if op in (:+, :-, :*, :/)
            if length(operands) == 1
                # Unary operator: print like "- x"
                local arg = (operands[1] isa Number || operands[1] isa Symbol) ?
                            string(operands[1]) :
                            JuMP.function_string(mode, operands[1])
                return string(op, " ", arg)
            elseif length(operands) == 2
                # Binary operator: infix notation, e.g. "(a + b)"
                local arg1 = (operands[1] isa Number || operands[1] isa Symbol) ?
                             string(operands[1]) :
                             JuMP.function_string(mode, operands[1])
                local arg2 = (operands[2] isa Number || operands[2] isa Symbol) ?
                             string(operands[2]) :
                             JuMP.function_string(mode, operands[2])
                return "" * arg1 * " " * string(op) * " " * arg2 * ""
            else
                # More than two operands: print as op(arg1, arg2, …)
                local args_str = join(map(x -> (x isa Number || x isa Symbol) ?
                                             string(x) :
                                             JuMP.function_string(mode, x),
                                             operands), ", ")
                return string(op, "", args_str, "")
            end
        elseif op in [:sin,:cos,:tan,:sinh,:cosh,:tanh, :log,:log2,:log10,:exp,:sqrt]

            # Otherwise, treat op as a function name: print like "sin(arg1, arg2, …)"
            local args_str = join(map(x -> (x isa Number || x isa Symbol) ?
                                         string(x) :
                                         JuMP.function_string(mode, x),
                                         operands), ", ")
            return string(op, "(", args_str, ")")
        end
    elseif expr.head == :(=)
        error("Invalid operation =")
    else
        # Fallback: show as head(args...)
        local args_str = join(map(x -> (x isa Number || x isa Symbol) ?
                                     string(x) :
                                     JuMP.function_string(mode, x),
                                     expr.args), ", ")
        return string(expr.head, "(", args_str, ")")
    end
end


Base.show(io::IO, expr::NonlinearExpr) = print(io, JuMP.function_string(MIME("text/plain"), expr))


############# The extension of @constraint and relevant function
mutable struct DyNonlinearConstraint <: JuMP.AbstractConstraint
    expr::NonlinearExpr
    set::MOI.AbstractScalarSet
end

mutable struct ExplicitDifferentialConstraint <:JuMP.AbstractConstraint
    expr::NonlinearExpr
    set::MOI.AbstractScalarSet
    #derivative_id::Union{Symbol, Nothing}
end

function find_phase(ref::DynamicVarRef)
    m = ref.model
    # Look up the associated DynamicVar in the model’s extension dictionary.
    dv = m.ext[:variables][ref.Index]
    return dv.Phase
end

#if const = 0 in the DynamicAffExpr, construct a DOI LinearDynamicFunction
function construct_LinDyFunc(expr::DynamicAffExpr)
    all_terms = expr.terms

    vars =  [k for k in keys(all_terms)]
    coeff = collect(values(all_terms))

    C = typeof(coeff[1])
    lin_terms = DOI.LinearDynamicTerm{C}[]
    for (i, var) in enumerate(vars)
        c = coeff[i]
        # Construct a DynamicVariableIndex from the variable's index and its phase.
        dyn_index = DOI.DynamicVariableIndex(var.Index, DOI.PhaseIndex(find_phase(var)))
        push!(lin_terms, DOI.LinearDynamicTerm(c, dyn_index))
    end
    # Create and return the LinearDynamicFunction.
    return DOI.LinearDynamicFunction(lin_terms)

end

function construct_PureQuadDyFunc(expr::DynamicQuadExpr)

    C = typeof(collect(values(expr.terms))[1])
    quad_terms = DOI.PureQuadraticDynamicTerm{C}[]
     
    # Iterate over the unordered pairs and coefficients.
    for (up, coef) in expr.terms
        # up is of type JuMP.UnorderedPair{V}; we assume V is DynamicVarRef.
        dyn_index_a = DOI.DynamicVariableIndex(up.a.Index, DOI.PhaseIndex(find_phase(up.a)))
        dyn_index_b = DOI.DynamicVariableIndex(up.b.Index, DOI.PhaseIndex(find_phase(up.b)))
        # The constructor of PureQuadraticDynamicTerm checks that both variables are in the same phase.
        term = DOI.PureQuadraticDynamicTerm(coef, dyn_index_a, dyn_index_b)
        push!(quad_terms, term)
    end

    return DOI.PureQuadraticDynamicFunction(quad_terms)
end

function JuMP.build_constraint(error::Function, expr::DynamicAffExpr, set::MOI.AbstractScalarSet)
    
    if expr.constant != 0

        #extract the pure linear term out of DynamicAffExpr
        lindyterm = DynamicAffExpr(0.0, expr.terms)

        return JuMP.build_constraint(error, _build_nonlin_expr(:+, expr.constant, lindyterm), set) 

    else
        doi_expr = construct_LinDyFunc(expr)
        
        #DOI.add_constraint() to add lindyfunc 
    end
    
    return DyNonlinearConstraint(expr, set)
end


function find_phase(expr::DynamicAffExpr)
    
    if !isempty(expr.terms)
        first_var = first(keys(expr.terms))
        return find_phase(first_var)
    end
    # If it's a constant, return nothing or a default phase.
    return nothing
end

function find_phase(expr::DynamicQuadExpr)
    # Check the affine part first.
    if expr.aff.constant != 0 || !isempty(expr.aff.terms)
        return find_phase(expr.aff)
    end
    # If no affine part, check the quadratic terms.
    if !isempty(expr.terms)
        first_term = first(keys(expr.terms))
        return find_phase(first_term.a)  # Assuming both a and b share the same phase.
    end
    # If it's purely constant, return nothing or a default phase.
    return nothing
end

function find_phase(expr::NonlinearExpr)
    # Check if the expression is a call with an operator.
    if expr.head == :call && !isempty(expr.args)
        # The first argument is the operator, the rest are operands.
        for arg in expr.args[2:end]
            local p = get_phase(arg)
            if p !== nothing
                return p
            end
        end
    end
    # If no phase found, return nothing or a default phase.
    return nothing
end

# Return the phase of a DOI.DynamicVariableIndex
function get_phase(x::DOI.DynamicVariableIndex)
    return x.phase
end

# Return the phase of a DOI.LinearDynamicFunction
function get_phase(ldf::DOI.LinearDynamicFunction{T}) where {T}
    # All terms in ldf must share the same phase, so return the first's phase.
    return DOI.phase_index(ldf)
end

# Return the phase of a DOI.PureQuadraticDynamicFunction
function get_phase(qf::DOI.PureQuadraticDynamicFunction{T}) where {T}
    # All terms in qf must share the same phase, so return the first's phase.
    return DOI.phase_index(first(qf.terms).dyn_var_1)
end

# Return the phase of a DOI.NonlinearDynamicFunction
function get_phase(nf::DOI.NonlinearDynamicFunction)
    return nf.phase
end

# Return the phase of a DOI.Derivative
function get_phase(d::DOI.Derivative)
    # The derivative wraps an AbstractDynamicFunction. Return that function's phase.
    return get_phase(d.dyn_fun)
end

# A fallback that says "no phase" for simple numbers, etc.
function get_phase(x::Number)
    return nothing
end

function unify_phases(objs::Vector)
    phases = Any[]
    for o in objs
        local p = get_phase(o)
        if p !== nothing
            push!(phases, p)
        end
    end
    if isempty(phases)
        # If absolutely no phase is found, choose a default or throw.
        return 
    end
    # All must match the first:
    local base = first(phases)
    for ph in phases
        if ph != base
            throw(DOI.MixedPhases("Non-matching phases among arguments."))
        end
    end
    return base
end

function is_explicit_derivative_expr(expr::NonlinearExpr)
    # Check if expr is of the form: (==, lhs, rhs) with lhs a derivative term.
    if expr.head == :call && length(expr.args) == 3 
        local lhs = expr.args[2]
        return lhs isa DerivativeTerm
    end
    return false
end

function toDOINonlinearFunction(obj::Any)

    # 1) If it's just a number, return it as a plain numeric constant.
    if obj isa Number
        return obj
    end

    # 2) If it's a DynamicVarRef, convert to DOI.DynamicVariableIndex
    if obj isa DynamicVarRef
        local p = find_phase(obj)
        return DOI.DynamicVariableIndex(obj.Index, DOI.PhaseIndex(p))
    end

    # 3) If it's a DerivativeTerm, build a DOI.Derivative object.
    #    If the coefficient != 1, wrap it in a NonlinearDynamicFunction(:*, ...).
    if obj isa DerivativeTerm
        local p = find_phase(obj.var)
        local dv = DOI.DynamicVariableIndex(obj.var.Index, DOI.PhaseIndex(p))
        local base_deriv = DOI.Derivative(dv)  # Now we use the Derivative struct
        if obj.coef == 1.0
            return base_deriv
        else
            # Multiply by the coefficient:  coef * (Derivative(dv))
            return DOI.NonlinearDynamicFunction(
                :*,
                [obj.coef, base_deriv],
                DOI.PhaseIndex(p)
            )
        end
    end

    # 4) If it's a DynamicAffExpr
    if obj isa DynamicAffExpr

        # If constant == 0, we can convert to a LinearDynamicFunction directly:
        if obj.constant == 0
            local ldf = construct_LinDyFunc(obj)  # returns a LinearDynamicFunction
            local p = get_phase(ldf)

            return ldf
        else
            # If constant != 0, treat as a sum of (constant) + (linear part).
            if isempty(obj.terms)
                # It's purely a constant with no variables
                return obj.constant
            else
                local ldf = construct_LinDyFunc(DynamicAffExpr(zero(obj.constant), copy(obj.terms)))
                local p = get_phase(ldf)
                # println(ldf)
                # println(p)

                return DOI.NonlinearDynamicFunction(
                    :+,
                    [obj.constant, ldf],
                    p
                )
            end
        end
    end

    # 5) If it's a DynamicQuadExpr
    if obj isa DynamicQuadExpr
        local pqf = construct_PureQuadDyFunc(obj)  # returns a PureQuadraticDynamicFunction
        local p = get_phase(pqf)
        # Check the affine part
        if obj.aff.constant == 0 && isempty(obj.aff.terms)
            # purely quadratic
            return pqf
        else
            # There's a nontrivial affine portion
            local afffn = toDOINonlinearFunction(obj.aff)
            return DOI.NonlinearDynamicFunction(
                :+,
                [afffn, pqf],
                p
            )
        end
    end

    # 6) If it's a NonlinearExpr
    if obj isa NonlinearExpr
        if obj.head == :explicit_diff
            # In this case, obj.args[1] holds the explicit differential function.
            return obj.args[1]
        end
        # If head == :call, then the first element of args is the operator, 
        # and the rest are the operands. We'll map them to their conversions, 
        # unify their phases, and build a NonlinearDynamicFunction.
        if obj.head == :call
            local op = obj.args[1]  # e.g. :sin, :*, :log, etc.
            local raw_operands = obj.args[2:end]
            # Convert each operand:
            local converted = map(toDOINonlinearFunction, raw_operands)
            # Unify phases across all operands that have a definable phase:
            local p = unify_phases(converted)
            # Return a NonlinearDynamicFunction
            return DOI.NonlinearDynamicFunction(op, converted, p)
        else
            error("Unsupported NonlinearExpr head = $(obj.head).")
        end
    end

    # If none of the above matched, throw an error.
    error("Unsupported object type in toDOINonlinearFunction: $(typeof(obj))")
end

# First, add the missing helper function to extract the phase from a
# PureQuadraticDynamicFunction. This is analogous to the one for LinearDynamicFunction.
# function phase_index(quad_dyn_fun::PureQuadraticDynamicFunction)
#     if isempty(quad_dyn_fun.terms)
#         # This case should ideally be handled based on package conventions,
#         # but throwing an error is a safe default.
#         error("Cannot determine phase of an empty PureQuadraticDynamicFunction.")
#     end
#     # The constructor ensures all terms share the same phase.
#     return phase_index(quad_dyn_fun.terms[1].dyn_var_1)
# end

"""
    to_NDF(f::AbstractDynamicFunction)

Convert an `AbstractDynamicFunction` into its `NonlinearDynamicFunction`
equivalent.

This function builds a nested expression tree to represent the input function.
"""
function to_NDF end

# Method to handle linear functions
function to_NDF(f::DOI.LinearDynamicFunction{T}) where {T}
    phase = get_phase(f)

    # Convert each term c*y into a nonlinear expression `:* (c, y)`
    nonlinear_terms = map(f.terms) do term
        return DOI.NonlinearDynamicFunction(:*, [term.coefficient, term.dyn_var], phase)
    end

    # If there's only one term, no need for a '+' wrapper.
    # Otherwise, combine all terms with the '+' operator.
    if length(nonlinear_terms) == 1
        return nonlinear_terms[1]
    else
        return DOI.NonlinearDynamicFunction(:+, nonlinear_terms, phase)
    end
end

# Method to handle pure quadratic functions
function to_NDF(f::DOI.PureQuadraticDynamicFunction{T}) where {T}
    phase = get_phase(f)

    # Convert each term c*y1*y2 into a nonlinear expression `:* (c, y1, y2)`
    nonlinear_terms = map(f.terms) do term
        return DOI.NonlinearDynamicFunction(
            :*,
            [term.coefficient, term.dyn_var_1, term.dyn_var_2],
            phase,
        )
    end

    # If there's only one term, no need for a '+' wrapper.
    # Otherwise, combine all terms with the '+' operator.
    if length(nonlinear_terms) == 1
        return nonlinear_terms[1]
    else
        return DOI.NonlinearDynamicFunction(:+, nonlinear_terms, phase)
    end
end

# Base case: If the function is already in the target format, make sure each element in the args are converted to NonlinearDynamicFunction.
function to_NDF(ndf::DOI.NonlinearDynamicFunction)
    all_args = [to_NDF(arg) for arg in ndf.args]

    return DOI.NonlinearDynamicFunction(ndf.head, all_args, ndf.phase)
end

function to_NDF(v::DOI.DynamicVariableIndex)
    # To represent a single variable as a NonlinearDynamicFunction,
    # we wrap it in a neutral operator. The unary plus `:+` is a
    # standard choice, as the expression `+(v)` is equivalent to `v`.
    return DOI.NonlinearDynamicFunction(:+, [v], v.phase)
end

function to_NDF(d::Number)
    # For numbers, we can directly return them
    return d
end

# convert doi quantities to DOI.NonlinearDynamicFunction

# function to_doi_variable_ref(vref::DynamicVarRef, model::JuMP.Model)
#     phase = model.ext[:variables][vref.Index].Phase
#     return DOI.NonlinearDynamicFunction(
#         :+,
#         [DOI.DynamicVariableIndex(vref.Index, DOI.PhaseIndex(phase))],
#         DOI.PhaseIndex(phase)
#     )
# end
# #DynamicVariableIndex(vref.Index, DOI.PhaseIndex(phase))

# function to_doi_nonlinear_function(expr::JuMP.AbstractJuMPScalar, model::JuMP.Model, phase::Int)
#     # Base case: numbers
#     expr isa Number && return expr
    
#     # Base case: variables
#     if expr isa DynamicVarRef
#         return to_doi_variable_ref(expr, model)
#     end
    
#     # Derivative terms
#     if expr isa DerivativeTerm
#         var_ref = to_doi_variable_ref(expr.var, model)
#         deriv = DOI.Derivative(var_ref)
#         return expr.coef == 1 ? deriv : DOI.NonlinearDynamicFunction(:*, [expr.coef, deriv], DOI.PhaseIndex(phase))
#     end
    
#     # Nonlinear expressions
#     if expr isa NonlinearExpr
#         #iteratively convert each argument to a DOI Objective
#         head = expr.head
#         args = expr.args
        
#         converted_args = [to_doi_nonlinear_function(arg, model, phase) for arg in args[2:end]]
#         return DOI.NonlinearDynamicFunction(head, converted_args, DOI.PhaseIndex(phase))
#     end
    
#     # Dynamic expressions
#     if expr isa Union{DynamicAffExpr, DynamicQuadExpr}
#         # Convert to NonlinearDynamicFunction recursively
#         # (Implement based on your expression structure - placeholder)
#         return DOI.NonlinearDynamicFunction(:custom, [expr], DOI.PhaseIndex(phase))
#     end
    
#     error("Unsupported expression type: $(typeof(expr))")
# end

function JuMP.build_constraint(error::Function, expr::NonlinearExpr, set::MOI.EqualTo)


    if is_explicit_derivative_expr(expr)
        
        return ExplicitDifferentialConstraint(expr, set)
   else
        # Fallback: use the original behavior.
        return DyNonlinearConstraint(expr, set)
   end
end

function JuMP.add_constraint(
    model::JuMP.Model,
    con::ExplicitDifferentialConstraint,
    name::String,
)

    # Extract the left-hand side and right-hand side of the equality.
    lhs = con.expr.args[2]   # expected to be a DerivativeTerm
    rhs = con.expr.args[3]

    # Convert lhs into a DOI.Derivative.
    d = toDOINonlinearFunction(lhs)   # should return a DOI.Derivative
    # Convert rhs into a DOI.NonlinearDynamicFunction.
    f = toDOINonlinearFunction(rhs)   #to_doi_nonlinear_function(rhs, model, find_phase(lhs.var))

    dyn_var = d.dyn_fun
    
    ndf = to_NDF(f)

    println("head of ndf: ", ndf.head)
    println("args of ndf: ", ndf.args)

    explicitfunc =  DOI.ExplicitDifferentialFunction(dyn_var, ndf)
    set = MOI.EqualTo{Float64}(0)

    
    MOI.add_constraint( model.moi_backend.optimizer.model, explicitfunc, set)
    
    return con.expr
end

function JuMP.add_constraint(
    model::JuMP.Model,
    con::DyNonlinearConstraint,
    name::String,
)
    set = MOI.EqualTo{Float64}(0)
    MOI.add_constraint(model.moi_backend.optimizer.model, toDOINonlinearFunction(con.expr), set)
    
    return con.expr
end

JuMP.index(v::DynamicVarRef) = v.Index