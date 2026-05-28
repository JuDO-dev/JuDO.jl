"""
    BoundaryOperator()
A boundary operator representing either the initial or final value of a variable or phase.

"""
struct BoundaryOperator <: JuMP.AbstractJuMPScalar
    op::Symbol      # should be :initial or :final
    arg::Union{PhaseVarRef,DynamicVarRef}        # a DynamicVarRef or PhaseVarRef
end

"""
    initial(x) -> BoundaryOperator

Return a `BoundaryOperator` that evaluates `x` at the **start** of its phase.
Use inside `@constraint` or `@objective`:

```julia
@constraint(model, initial(x) == 0.0)
@objective(model, Min, initial(fuel))
```
"""
initial(x) = BoundaryOperator(:initial, x)

"""
    final(x) -> BoundaryOperator

Return a `BoundaryOperator` that evaluates `x` at the **end** of its phase.
Use inside `@constraint` or `@objective`:

```julia
@constraint(model, final(x) == 1.0)
@objective(model, Max, final(altitude))
```
"""
final(x)   = BoundaryOperator(:final, x)

""" 
    BoundaryConditionExpr{L,R} <: JuMP.AbstractJuMPScalar
A boundary condition expression representing conditions on the initial or final values of variables or phases.
"""
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



"""
    DyBoundaryConstraint <: JuMP.AbstractConstraint

Internal constraint object produced by `JuMP.build_constraint` when a
`BoundaryConditionExpr` is constrained with `==`, `<=`, or `>=`. Holds the
parsed boundary expression and the MOI set encoding the right-hand side.

# Fields
- `expr`: the `BoundaryConditionExpr` representing the boundary condition.
- `set`: an MOI scalar set (`EqualTo`, `LessThan`, or `GreaterThan`).
"""
struct DyBoundaryConstraint <: JuMP.AbstractConstraint
    expr::BoundaryConditionExpr
    set::MOI.AbstractScalarSet
end

#now only the initial() == ... is implemented, not sure how <= can be done
function JuMP.build_constraint(error::Function, bc::BoundaryConditionExpr, set::Union{MOI.EqualTo, MOI.LessThan, MOI.GreaterThan})
    model = bc.lhs.model

    set_value = (bc.rhs isa Number) ? bc.rhs : 0.0

    if set isa MOI.EqualTo
        set = MOI.EqualTo(set_value)
    elseif set isa MOI.LessThan
        set = MOI.LessThan(set_value)
    elseif set isa MOI.GreaterThan
        set = MOI.GreaterThan(set_value)
    end

    if bc.lhs isa DynamicVarRef && !(bc.rhs isa BoundaryOperator)
        # For dynamic variable boundary conditions.
        local p = find_phase(bc.lhs)
        local dyn_idx = DOI.DynamicVariableIndex(bc.lhs.Index, DOI.PhaseIndex(p))
        if bc.op == :initial
            local bound_obj = DOI.Initial(dyn_idx)
            MOI.add_constraint(model.moi_backend.optimizer, bound_obj, set)

        elseif bc.op == :final
            local bound_obj = DOI.Final(dyn_idx)
            MOI.add_constraint(model.moi_backend.optimizer, bound_obj, set)
  
        else
            error("Unknown boundary operator: $(bc.op)")
        end
    elseif bc.lhs isa PhaseVarRef && !(bc.rhs isa BoundaryOperator)
        # For phase boundary conditions.
        local phase_num = bc.lhs.Index  # phase number stored in Index.
        if bc.op == :initial
            local bound_obj = DOI.Initial(DOI.PhaseIndex(phase_num))
            MOI.add_constraint(model.moi_backend.optimizer, bound_obj, set)
        elseif bc.op == :final
            local bound_obj = DOI.Final(DOI.PhaseIndex(phase_num))
            MOI.add_constraint(model.moi_backend.optimizer, bound_obj, set)
        else
            error("Unknown boundary operator: $(bc.op)")
        end

    # linkage between phases becomes boundary conditions
    elseif bc.lhs isa PhaseVarRef && bc.rhs isa BoundaryOperator
        # Check that RHS is also a phase
        if !(bc.rhs.arg isa PhaseVarRef)
            error("Cannot link a Phase to a Variable.")
        end

        local phase1_idx = bc.lhs.Index
        local phase2_idx = bc.rhs.arg.Index

        if bc.op == :final && bc.rhs.op == :initial
            lhs_term = DOI.Final(DOI.PhaseIndex(phase1_idx))
            rhs_term = DOI.Initial(DOI.PhaseIndex(phase2_idx))
        elseif bc.op == :initial && bc.rhs.op == :final
            lhs_term = DOI.Initial(DOI.PhaseIndex(phase1_idx))
            rhs_term = DOI.Final(DOI.PhaseIndex(phase2_idx))
        else
            error("Unsupported linkage boundary condition operators: $(bc.op), $(bc.rhs.op)")
        end
        local boundary_func = DOI.NonlinearBoundaryFunction(:-, [lhs_term, rhs_term])
        MOI.add_constraint(model.moi_backend.optimizer, boundary_func, set)

    # -----------------------------------------------------------
    # CASE B: Linking two VARIABLES (e.g. final(q1) == initial(q2))
    # -----------------------------------------------------------
    elseif bc.lhs isa DynamicVarRef && bc.rhs isa BoundaryOperator
        # Check that RHS is also a variable
        if !(bc.rhs.arg isa DynamicVarRef)
            error("Cannot link a Variable to a Phase.")
        end

        local var1 = bc.lhs
        local var2 = bc.rhs.arg

        # Construct DOI.DynamicVariableIndex for both variables
        # Note: We must look up the correct phase for each variable
        local idx1 = DOI.DynamicVariableIndex(var1.Index, DOI.PhaseIndex(find_phase(var1)))
        local idx2 = DOI.DynamicVariableIndex(var2.Index, DOI.PhaseIndex(find_phase(var2)))

        # Construct Linkage with VARIABLE indices
        local linkage = DOI.Linkage(idx1, idx2)
        MOI.add_constraint(model.moi_backend.optimizer, linkage, set)
    # elseif bc.rhs isa BoundaryOperator
    #     # Linkage constraint: we assume the expression was rewritten as:
    #     #    final(t1) - initial(t2)
    #     # so that bc.op is :final, bc.lhs is t1 (a PhaseVarRef),
    #     # and bc.rhs is BoundaryOperator(:initial, t2).
    #     # if !(bc.lhs isa PhaseVarRef) || !(bc.rhs.arg isa PhaseVarRef)
    #     #     error("Linkage constraints require both arguments to be phase references.")
    #     # end
    #     local phase1 = bc.lhs.Index
    #     local phase2 = bc.rhs.arg.Index
    #     local final_obj   = DOI.PhaseIndex(phase1)
    #     local initial_obj = DOI.PhaseIndex(phase2)
    #     local linkage = DOI.Linkage(final_obj, initial_obj)
    #     MOI.add_constraint(model.moi_backend.optimizer.model, linkage, MOI.EqualTo(0.0))
    #     #return DyBoundaryConstraint(linkage, nothing, set)
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