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
Pkg.add(url="https://github.com/JuDO-dev/DynOptInterface.jl", rev="v0.3.2")
Pkg.add(url="https://github.com/Kailai-Shi/Interesso.jl",        rev="f1b0849ac2ae00b95a223c82fa1398b8163c5292")

# JuDO itself
Pkg.add(url="https://github.com/JuDO-dev/JuDO.jl", rev="v0.1.1")

# Packages used by the examples
Pkg.add(["JuMP", "Plots"])
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

---

## Benchmarks

The computation times reported in the JuDO paper are produced by two scripts in `benchmark/`. From the repository root, first install the package versions pinned in `Manifest.toml`:

```
julia --project=. -e "using Pkg; Pkg.instantiate()"
```

Then run each script in a fresh Julia process:

```
julia --project=. benchmark/benchmark_judo_examples.jl
julia --project=. benchmark/computation-time-test-interesso/benchmark.jl
```

- `benchmark_judo_examples.jl` solves the cart-pole and space shuttle examples in `test/` through JuDO for every discretization in `CARTPOLE_CONFIGS` and `SHUTTLE_CONFIGS`, and writes the timings to `benchmark/benchmark_judo_examples_results.txt`.
- `computation-time-test-interesso/benchmark.jl` solves the same problems directly with Interesso and writes the timings to `benchmark/computation-time-test-interesso/benchmark_results.txt`.

Every run also saves the plots of the solution. Set the environment variable `GKSwstype=100` before running the scripts, so that the GR plotting backend writes the figures without opening a display (`export GKSwstype=100` in bash, `$env:GKSwstype = "100"` in PowerShell).
