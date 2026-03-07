```@meta
CurrentModule = JuDO
```

# JuDO.jl

*Julia for Dynamic Optimization*

JuDO is a domain-specific modeling language for dynamic optimization in [Julia](https://julialang.org/). It extends the syntax of [JuMP.jl](https://jump.dev/) to support infinite-dimensional optimization variables and differential equations.

## Why use JuDO?
JuDO solves the problem of solver fragmentation in optimal control. You can write your dynamic optimization problem once and test it on many solvers. 

* **Unified Modeling and Reproducibility:** Dynamic optimization solvers have different requirements, but JuDO gives you a standardized definition interface. It translates your high-level code so you do not have to write custom parsers.
* **Automated Reformulation:** JuDO and its underlying [DynOptInterface](https://judo.dev/DynOptInterface.jl/dev/) automatically recognize and transform the user-defined problem into the style that the underlying solver requires.
* **Familiar Syntax:** JuDO extends JuMP. It uses standard macros like `@variable` and `@constraint` so you can build models quickly if you know Julia or JuMP.


## Installation
```julia
using Pkg
Pkg.add("JuDO")
```



<!-- ## API Reference
```@autodocs
Modules = [JuDO]
``` -->
