# Dynamic Optimization Model

At the core of any JuDO.jl application is the Dynamic Optimization Model, initialized using `DynModel`. 

## How it Differs from JuMP

In standard [JuMP](https://jump.dev/), you create an optimization model using `JuMP.Model()`. This standard model is designed for finite-dimensional decision variables, objective functions, and constraints. 

However, Dynamic Optimization Problems (DOPs) require an infinite-dimensional domain. To solve this, JuDO introduces `DynModel`. `DynModel` acts as a wrapper around a standard `JuMP.Model`, it automatically initializes specialized internal data structures (stored safely in the `model.ext` dictionary) to track:
* **Phases** (the independent variables, such as time)
* **Dynamic Variables** (trajectories that evolve over a phase)
* **Dictionaries** that map your variable names to internal indices for the backend solver.

## Creating a Model

Because `DynModel` wraps standard JuMP functionality, it accepts the exact same arguments and keyword arguments as a regular `JuMP.Model`.

**Basic Initialization (No Optimizer attached yet):**
```julia
using JuDO
model = DynModel()
```

**Initialization with an Optimizer:**
If you want to attach a solver:
```julia
using JuDO
using Interesso
model = DynModel(Interesso.Optimizer)
```

## API Reference

```@docs
DynModel
get_phase
get_phasenum
get_var
get_varnum
```