# Phase

In dynamic optimization, a **Phase** represents the continuous, independent variable domain over which the dynamic variables evolve. In most physical problems, this represents "Time" ($t$), but it could also represent space or another continuous dimension.

## How it Differs from JuMP

Standard JuMP only deals with variables that have a single, scalar value. JuMP does not have a native concept of an independent variable domain. 

In JuDO, you must define a Phase before you can define the variables. When you declare a phase, JuDO creates a `PhaseVarRef` registers this new domain with the `DynOptInterface` (DOI) backend.

## Defining a Phase

You define a phase using the `@phase` macro. There are two primary ways to create a phase, depending on whether you know the bounds of your domain in advance.

### Option 1: Unbounded Phase

If you want to create a phase without specifying its start and end times upfront (for example, if the final time is free and determined by the optimizer), you can define it simply by providing the model and the name of the phase:

```julia
# Creates a phase 't' with bounds from -Inf to Inf
@phase(model, t)
```

### Option 2: Bounded Phase 

If your phase has a fixed duration, you can pass the start and stop limits directly into the macro.
```julia
# Creates a phase 't' that goes strictly from 0 to 10
@phase(model, t, 0, 10)
```

## API Reference

See [`@phase`](@ref). Internal types: `Phase`, `PhaseVar`, `PhaseVarRef`.