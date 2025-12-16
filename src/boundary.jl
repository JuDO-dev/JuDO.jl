# A lightweight wrapper representing a boundary operator.
struct BoundaryOperator <: JuMP.AbstractJuMPScalar
    op::Symbol      # should be :initial or :final
    arg::Union{PhaseVarRef,DynamicVarRef}        # a DynamicVarRef or PhaseVarRef
end

initial(x) = BoundaryOperator(:initial, x)
final(x)   = BoundaryOperator(:final, x)

# For a dynamic variable, rhs must be a Number.
# For a phase, rhs may be a Number or (potentially) another boundary operator.
struct BoundaryConditionExpr{L,R} <: JuMP.AbstractJuMPScalar
    op::Symbol      # :initial or :final, from the LHS operator
    lhs::L          # either a DynamicVarRef or PhaseVarRef
    rhs::R         # if lhs is DynamicVarRef, then rhs is a MOI set (e.g. MOI.GreaterThan or MOI.LessThan);
                    # if lhs is PhaseVarRef, then rhs is likewise either a MOI set or another boundary operator.
end

function JuMP.function_string(mode::MIME, bc::BoundaryConditionExpr)
    # Convert the lhs and rhs to strings.
    lhs_str = (bc.lhs isa Number || bc.lhs isa Symbol) ? string(bc.lhs) : JuMP.function_string(mode, bc.lhs)
    rhs_str = (bc.rhs isa Number || bc.rhs isa Symbol) ? string(bc.rhs) : JuMP.function_string(mode, bc.rhs)
    return string(bc.op, "(", lhs_str, ") - ", rhs_str)
end
Base.show(io::IO, bc::BoundaryConditionExpr) = print(io, JuMP.function_string(MIME("text/plain"), bc))

# Define display for BoundaryOperator:
function JuMP.function_string(mode::MIME, b::BoundaryOperator)
    arg_str = (b.arg isa Number || b.arg isa Symbol) ? string(b.arg) : JuMP.function_string(mode, b.arg)
    return string(b.op, "(", arg_str, ")")
end
Base.show(io::IO, b::BoundaryOperator) = print(io, JuMP.function_string(MIME("text/plain"), b))


# Overload subtraction: BoundaryOperator - Number.
function Base.:-(b::BoundaryOperator, r::Number)
    return BoundaryConditionExpr{typeof(b.arg), Number}(b.op, b.arg, float(r))
end
function Base.:+(b::BoundaryOperator, r::Number)
    return BoundaryConditionExpr{typeof(b.arg), Number}(b.op, b.arg, -float(r))
end

function Base.:+(bc::BoundaryConditionExpr, r::Number)
    return BoundaryConditionExpr{typeof(bc.lhs), typeof(bc.rhs)}(bc.op, bc.lhs, bc.rhs - float(r))
end

function Base.:-(bc::BoundaryConditionExpr, r::Number)
    return BoundaryConditionExpr{typeof(bc.lhs), typeof(bc.rhs)}(bc.op, bc.lhs, bc.rhs + float(r))
end

function Base.:-(b::BoundaryOperator, r::BoundaryOperator)
    return BoundaryConditionExpr{typeof(b.arg), BoundaryOperator}(b.op, b.arg, r)
end



struct DyBoundaryConstraint <: JuMP.AbstractConstraint
    expr::BoundaryConditionExpr
    set::MOI.AbstractScalarSet
end

#now only the initial() == ... is implemented, not sure how <= can be done
function JuMP.build_constraint(error::Function, bc::BoundaryConditionExpr, set::MOI.EqualTo)
    model = bc.lhs.model
    if bc.lhs isa DynamicVarRef && !(bc.rhs isa BoundaryOperator)
        # For dynamic variable boundary conditions.
        local p = find_phase(bc.lhs)
        local dyn_idx = DOI.DynamicVariableIndex(bc.lhs.Index, DOI.PhaseIndex(p))
        if bc.op == :initial
            local bound_obj = DOI.Initial(dyn_idx)
            MOI.add_constraint(model.moi_backend.optimizer.model, bound_obj, MOI.EqualTo(bc.rhs))

        elseif bc.op == :final
            local bound_obj = DOI.Final(dyn_idx)
            MOI.add_constraint(model.moi_backend.optimizer.model, bound_obj, MOI.EqualTo(bc.rhs))
  
        else
            error("Unknown boundary operator: $(bc.op)")
        end
    elseif bc.lhs isa PhaseVarRef && !(bc.rhs isa BoundaryOperator)
        # For phase boundary conditions.
        local phase_num = bc.lhs.Index  # phase number stored in Index.
        if bc.op == :initial
            local bound_obj = DOI.Initial(DOI.PhaseIndex(phase_num))
            MOI.add_constraint(model.moi_backend.optimizer.model, bound_obj, MOI.EqualTo(bc.rhs))
        elseif bc.op == :final
            local bound_obj = DOI.Final(DOI.PhaseIndex(phase_num))
            MOI.add_constraint(model.moi_backend.optimizer.model, bound_obj, MOI.EqualTo(bc.rhs))
        else
            error("Unknown boundary operator: $(bc.op)")
        end
    elseif bc.rhs isa BoundaryOperator
        # Linkage constraint: we assume the expression was rewritten as:
        #    final(t1) - initial(t2)
        # so that bc.op is :final, bc.lhs is t1 (a PhaseVarRef),
        # and bc.rhs is BoundaryOperator(:initial, t2).
        # if !(bc.lhs isa PhaseVarRef) || !(bc.rhs.arg isa PhaseVarRef)
        #     error("Linkage constraints require both arguments to be phase references.")
        # end
        local phase1 = bc.lhs.Index
        local phase2 = bc.rhs.arg.Index
        local final_obj   = DOI.PhaseIndex(phase1)
        local initial_obj = DOI.PhaseIndex(phase2)
        local linkage = DOI.Linkage(final_obj, initial_obj)
        MOI.add_constraint(model.moi_backend.optimizer.model, DOI.Linkage{DOI.PhaseIndex}, MOI.EqualTo(0.0))
        #return DyBoundaryConstraint(linkage, nothing, set)
    else
        error("Unsupported left-hand side type in BoundaryCondition: $(typeof(bc.lhs))")
    end

    return DyBoundaryConstraint(bc,set)
end

function JuMP.add_constraint(
    model::JuMP.Model,
    con::DyBoundaryConstraint,
    name::String,
)
    
    return con.expr
end