# Solutions

After you define your dynamic optimization model, you must solve it and extract the results.


## Solving the Model

You solve the model using the `optimize!` function. JuDO extends this function so you can pass specific options directly to the dynamic backend solver.

```julia
JuDO.optimize!(model)
```

Options controlling discretisation (intervals, collocation points, method, bounds) and the inner NLP solver can be set in two ways.

### Option 1: Via `set_attribute`

Options can be updated after model construction using the solver-agnostic attribute types from `DynOptInterface`.

```julia
set_attribute(model, DOI.GeneralIntervals(), FlexibleIntervals(20, 0.5))
set_attribute(model, DOI.GeneralPoints(),    LGRPoints(5))
set_attribute(model, DOI.GeneralMethod(),    Collocation())
```

### Option 2: As keyword arguments to `optimize!`

This is a convenience shorthand for setting options immediately before solving, without separate `set_attribute` calls.

```julia
JuDO.optimize!(model;
    intervals = FixedIntervals(20),
    points    = LGRPoints(5),
    method    = Collocation(),
)
```

## Retrieving Results
JuDO provides functions to get the continuous trajectories and the phase boundaries. Use `dyn_value(model, var)` to get the solution for one dynamic variable.

## Warmstarting
You can provide an initial guess to the solver to speed up the optimization. This is called warmstarting, realized using the `warmstart!` function.

## API Reference

See [`dyn_value`](@ref), [`phase_initial`](@ref), [`phase_final`](@ref),
`optimize!`. Also available: `get_solutions`, `warmstart!`.