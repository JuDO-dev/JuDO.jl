# JuDO.jl

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuDO-dev.github.io/JuDO.jl/dev/)
[![Build Status](https://github.com/JuDO-dev/JuDO.jl/actions/workflows/CI.yml/badge.svg?branch=dev)](https://github.com/JuDO-dev/JuDO.jl/actions/workflows/CI.yml?query=branch%3Adev)
[![Coverage](https://codecov.io/gh/JuDO-dev/JuDO.jl/branch/dev/graph/badge.svg)](https://codecov.io/gh/JuDO-dev/JuDO.jl)

## Introduction

**JuDO.jl** (Julia Dynamic Optimization) is a Julia package for formulating and solving dynamic optimisation problems. It extends the [JuMP](https://jump.dev) modelling language.

JuDO follows the same layered architecture as JuMP/MathOptInterface (MOI): problem formulations are expressed in solver-agnostic JuDO syntax, translated into a standard intermediate representation defined by [DynOptInterface.jl](https://github.com/shawn-tao01/DynOptInterface.jl) (DOI), and dispatched to a concrete solver such as [Interesso.jl](https://github.com/Kailai-Shi/Interesso.jl). This separation means that a problem written in JuDO can in principle be solved by any solver that implements the DOI interface, with no changes to the model code using JuDO.

Typical use cases include trajectory optimization, optimal control, etc..

---

## Installation

JuDO.jl and its dependencies are currently under active development and are not yet registered in the Julia General registry. Install them directly from GitHub using Julia's package manager:

```julia
using Pkg

# Required dependencies
Pkg.add(url="https://github.com/shawn-tao01/DynOptInterface.jl", rev="dev")
Pkg.add(url="https://github.com/Kailai-Shi/Interesso.jl",        rev="dev")

# JuDO itself
Pkg.add(url="https://github.com/shawn-tao01/JuDO.jl", rev="dev")
```

Julia 1.12.2 or later is required.

### The Layered architecture

```
User code (JuDO macros / extended JuMP macros and functions)
        │
        ▼
   JuDO.jl  ── translates to ──▶  DynOptInterface.jl (DOI)
                                          │
                                          ▼
                                DOP Solver (e.g. Interesso.jl)
                                          │
                                          ▼
                                   NLP solver (e.g. Ipopt)
```

Solvers implement the DOI interface by extending the MOI types and functions for the DOI attribute types (`DOI.DefaultIntervals`, etc.), an example DOI interface can be found in [the DOI folder in Interesso](https://github.com/Kailai-Shi/Interesso.jl/tree/dev/src/DOI). 
