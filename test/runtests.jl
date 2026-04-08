using Test
using JuMP
using Interesso
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

@testset "Examples" begin
    include("cartpole.jl")
    include("space-shuttle.jl")
end