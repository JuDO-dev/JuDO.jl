module BenchmarkJuDOExamples

import MathOptInterface as MOI
using Statistics: mean, std
using Printf

const CARTPOLE_PATH = joinpath(@__DIR__, "..", "test", "cartpole.jl")
const SHUTTLE_PATH  = joinpath(@__DIR__, "..", "test", "space-shuttle.jl")

mkpath(joinpath(@__DIR__, "..", "test", "cartpole-test"))
mkpath(joinpath(@__DIR__, "..", "test", "betts-space-shuttle-config-test"))

"""
    run_example(path) -> (total_wall, ipopt_time)

Include `path` inside a fresh anonymous module, time the whole execution, then
read back Ipopt's self-reported solve time from the model's inner optimizer.
`Core.eval(m, :dop)` is used instead of `m.dop` to avoid a Julia 1.12
world-age error: the `dop` binding is created during `include` at the current
world age, so it must be read back through an eval in the same world.
"""
function run_example(path::String)
    m = Module()
    total_wall = @elapsed Base.include(m, path)
    dop        = Core.eval(m, :dop)
    inner_model = dop.moi_backend.optimizer.model
    ipopt_time  = MOI.get(inner_model.inner, MOI.SolveTimeSec())
    intervals   = string(inner_model.default_intervals)
    points      = string(inner_model.default_points)
    return total_wall, ipopt_time, intervals, points
end


"""
    benchmark_example(path; n_runs) -> NamedTuple

Run the example at `path` for `n_runs` iterations.  The first iteration
captures first-run cost (JIT compilation included).  Returns a NamedTuple
with fields `total`, `ipopt`, `overhead`, each a `(first, rest)` pair.
"""
function benchmark_example(path::String; n_runs::Int)
    total_times = Float64[]
    ipopt_times = Float64[]
    intervals = ""
    points    = ""

    for _ in 1:n_runs
        total, ipopt, ivs, pts = run_example(path)
        push!(total_times, total)
        push!(ipopt_times, ipopt)
        intervals = ivs
        points    = pts
    end

    overhead = total_times .- ipopt_times

    return (
        total     = (first = total_times[1], rest = total_times[2:end]),
        ipopt     = (first = ipopt_times[1], rest = ipopt_times[2:end]),
        overhead  = (first = overhead[1],    rest = overhead[2:end]),
        intervals = intervals,
        points    = points,
    )
end


function write_header(io)
    println(io)
    println(io, "=" ^ 78)
    println(io, "  JuDO Example Benchmark  (direct include of test scripts)")
    println(io, "  Each iteration runs the full script in a fresh anonymous module.")
    println(io, "  run 1 = first-run (includes JIT compilation)")
    println(io, "  runs 2-N = steady-state")
    println(io, "  'JuDO+plot overhead' = total - Ipopt  (build + transcription + plot I/O)")
    println(io, "=" ^ 78)
end

function write_row(io, label, r)
    if isempty(r.rest)
        @printf io "    %-30s  first-run: %8.4f s   (only 1 run)\n" label r.first
    else
        @printf io "    %-30s  first-run: %8.4f s   mean: %8.4f s   std: %8.4f s\n" label r.first mean(r.rest) std(r.rest)
    end
end

function write_results(io, problem_name, r)
    @printf io "\n  %s\n" problem_name
    write_row(io, "Total wall time",       r.total)
    write_row(io, "  Ipopt reported time", r.ipopt)
    write_row(io, "  JuDO+plot overhead",  r.overhead)
end


const CARTPOLE_RUNS = 8
const SHUTTLE_RUNS  = 8

#run the cartpole example or the space shuttle example by commenting/uncommenting the relevant lines in main()
function main()
    out_path = joinpath(@__DIR__, "benchmark_judo_examples_results.txt")
    io = open(out_path, "a")
    try
        write_header(io)

        println(io)
        println(io, "  -- Cart-pole  (FixedIntervals(), LGRPoints()) " * "-" ^ 19)
        r = benchmark_example(CARTPOLE_PATH; n_runs = CARTPOLE_RUNS)
        write_results(io, "Cart-pole", r)
        flush(io)

        # println(io)
        # println(io, "  -- Space shuttle  (FixedIntervals(), LGRPoints()) " * "-" ^ 15)
        # r = benchmark_example(SHUTTLE_PATH; n_runs = SHUTTLE_RUNS)
        # write_results(io, "Space shuttle", r)
        # flush(io)

        println(io)
        println(io, "=" ^ 78)
    finally
        close(io)
    end
    println("Results saved to: $out_path")
end

main()

end
