# Objective

The objective function defines the goal of your dynamic optimization problem. 

## Defining the Objective

You define the goal using the `@objective` macro, specify the direction (like `Min` or `Max`) and the expression to optimize.

### Boundary Objectives (Mayer Term)

You can optimize the value of a variable at the start or end of a phase. You use the `initial()` or `final()` boundary operators.

```julia
# Maximize the final position
@objective(model, Max, final(x))

# Minimize the initial energy
@objective(model, Min, initial(E))
```

### Integral Objectives (Lagrange Term)
You can minimize or maximize the accumulated value of an expression over the entire phase. You use the integral() function.

```julia
# Minimize the total control effort over the phase
@objective(model, Min, integral(u^2))
```

## API Reference

```@docs
JuDO.Integral
JuDO.integral
JuDO.initial
JuDO.final
```