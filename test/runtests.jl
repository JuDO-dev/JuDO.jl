using Test
using JuMP
import Interesso
using JuDO
import DynOptInterface as DOI

# ── Unit tests ────────────────────────────────────────────────────────────────
# Each file tests one layer of the API; none of them call optimize!.

@testset "JuDO" begin
    include("test_datatypes.jl")
    include("test_phase.jl")
    include("test_variable.jl")
    include("test_boundary.jl")
    include("test_derivative.jl")
    include("test_objective.jl")
end

#choose one test at a time
@testset "Examples" begin
    #include("cartpole.jl")
    example = cp(joinpath(@__DIR__, "space-shuttle.jl"), joinpath(mktempdir(), "space-shuttle.jl"))
    include(example)
end