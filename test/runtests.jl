using Test
using JuMP
using Interesso

import DynOptInterface as DOI

include(joinpath(@__DIR__, "cartpole.jl"))

sol = JuDO.get_solutions(dop)
var_names = join(keys(sol), ", ")

@test var_names == "ω, ν, u, r, θ"