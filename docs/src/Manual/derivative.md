# Derivatives

In dynamic optimization, derivatives represent the rate of change of a dynamic variable with respect to its phase domain.

To support differential equations, JuDO introduces the `DerivativeTerm`, which represents the continuous derivative of a `DynamicVarRef`.

JuDO supports all basic mathematical operations between a DerivativeTerm and other types of variables.

## Creating a Derivative

You can specify the derivative of a dynamic variable using the `derivative()` function.

```julia
# Represents the derivative of x with respect to its phase
dx = derivative(x)
```

## API Reference

See [`DerivativeTerm`](@ref JuDO.DerivativeTerm), [`NonlinearExpr`](@ref JuDO.NonlinearExpr),
[`derivative`](@ref JuMP.derivative).
