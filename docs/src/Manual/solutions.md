# Solutions

After you define your dynamic optimization model, you must solve it and extract the results.


## Solving the Model

You solve the model using the `optimize!` function. JuDO extends this function so you can pass specific options directly to the dynamic backend solver.

```julia
# Solve the model with specific options
JuDO.optimize!(model)
```

You can pass several options like solver, intervals, points, method, and bounds to control how the problem is discretized and solved.

## Retrieving Results
JuDO provides functions to get the continuous trajectories and the phase boundaries. Use `dyn_value(model, var)` to get the solution for one dynamic variable.

## Warmstarting
You can provide an initial guess to the solver to speed up the optimization. This is called warmstarting, realized using the `warmstart!` function.

## API Reference

```@docs
JuDO.optimize!
JuDO.dyn_value
JuDO.get_solutions
JuDO.phase_initial
JuDO.phase_final
JuDO.warmstart!
```