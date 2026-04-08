# Constraints

Constraints in JuDO define the physical laws (such as system dynamics) and operational limits (such as path constraints) that trajectories must satisfy throughout a given phase.


## Creating Constraints

You define dynamic constraints using the standard JuMP `@constraint` macro. JuDO handles the routing into two main types of constraints based on your formulation:

### Option 1: Explicit Differential Constraints

```julia
# Explicitly defines the dynamics: x' = -x + u
@constraint(model, derivative(x) == -x + u)
```

### Option 2: General Dynamic (Path) Constraints


```julia
# A path constraint ensuring the sum of states is bounded
@constraint(model, x + y <= 10)

# An implicit differential equation
@constraint(model, derivative(x)^2 + x == 0)
```

## API Reference

See [`initial`](@ref) and [`final`](@ref). Internal types:
`BoundaryOperator`, `BoundaryConditionExpr`, `DyBoundaryConstraint`.