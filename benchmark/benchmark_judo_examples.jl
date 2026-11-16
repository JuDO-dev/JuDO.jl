module BenchmarkJuDOExamples

import MathOptInterface as MOI
using Statistics: mean, std
using Printf

const CARTPOLE_PATH = joinpath(@__DIR__, "..", "test", "cartpole.jl")
const SHUTTLE_PATH  = joinpath(@__DIR__, "..", "test", "space-shuttle.jl")

mkpath(joinpath(@__DIR__, "..", "test", "cartpole-test"))
mkpath(joinpath(@__DIR__, "..", "test", "betts-space-shuttle-config-test"))

# Rewrite every optimize! call of an example script to use FixedIntervals(n_intervals) and LGRPoints(n_points).
function set_discretization(ex, n_intervals::Int, n_points::Int)
    ex isa Expr || return ex
    args = Any[set_discretization(a, n_intervals, n_points) for a in ex.args]
    if ex.head == :call && args[1] in (:optimize!, :(JuDO.optimize!))
        filter!(a -> !(a isa Expr && a.head == :kw && a.args[1] in (:intervals, :points)), args)
        push!(args, Expr(:kw, :intervals, :(FixedIntervals($n_intervals))), Expr(:kw, :points, :(LGRPoints($n_points))))
    end
    return Expr(ex.head, args...)
end

"""
    run_example(path, n_intervals, n_points) -> (total_wall, ipopt_time, iterations, intervals, points)

Include `path` inside a fresh anonymous module, with its `optimize!` call set to
`FixedIntervals(n_intervals)` and `LGRPoints(n_points)`, time the whole execution, then
read back Ipopt's self-reported solve time and iteration count from the model's inner optimizer.
`Core.eval(m, :dop)` is used instead of `m.dop` to avoid a Julia 1.12
world-age error: the `dop` binding is created during `include` at the current
world age, so it must be read back through an eval in the same world.
"""
function run_example(path::String, n_intervals::Int, n_points::Int)
    m = Module()
    total_wall = @elapsed Base.include(ex -> set_discretization(ex, n_intervals, n_points), m, path)
    dop        = Core.eval(m, :dop)
    inner_model = dop.moi_backend.optimizer.model
    ipopt_time  = Base.invokelatest(MOI.get, inner_model.inner, MOI.SolveTimeSec())
    iterations  = Base.invokelatest(MOI.get, inner_model.inner, MOI.BarrierIterations())
    intervals   = string(inner_model.default_intervals)
    points      = string(inner_model.default_points)
    return total_wall, ipopt_time, iterations, intervals, points
end


"""
    benchmark_example(path, n_intervals, n_points; n_runs) -> NamedTuple

Run the example at `path` for `n_runs` iterations.  The first iteration
captures first-run cost (JIT compilation included).  Returns a NamedTuple
with fields `total`, `ipopt`, `overhead`, each a `(first, rest)` pair, and
`iterations`, the Ipopt iteration count of every run.
"""
function benchmark_example(path::String, n_intervals::Int, n_points::Int; n_runs::Int)
    total_times = Float64[]
    ipopt_times = Float64[]
    iterations  = Int[]
    intervals = ""
    points    = ""

    for _ in 1:n_runs
        total, ipopt, iters, ivs, pts = run_example(path, n_intervals, n_points)
        push!(total_times, total)
        push!(ipopt_times, ipopt)
        push!(iterations, iters)
        intervals = ivs
        points    = pts
    end

    overhead = total_times .- ipopt_times

    return (
        total     = (first = total_times[1], rest = total_times[2:end]),
        ipopt     = (first = ipopt_times[1], rest = ipopt_times[2:end]),
        overhead  = (first = overhead[1],    rest = overhead[2:end]),
        iterations = iterations,
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
    @printf io "    %-30s  %s\n" "  Ipopt iterations" join(unique(r.iterations), ", ")
end


const CARTPOLE_RUNS = 8
const SHUTTLE_RUNS  = 8

const CARTPOLE_CONFIGS = [
    (10, 5), (10, 7),
    (20, 5), (20, 7),
    (30, 5), (30, 7),
    (40, 5), (40, 7),
]

const SHUTTLE_CONFIGS = [
    (10, 5), (10, 7),
    (20, 5), (20, 7),
    (30, 5), (30, 7),
    (40, 5), (40, 7),
]

function main()
    out_path = joinpath(@__DIR__, "benchmark_judo_examples_results.txt")
    io = open(out_path, "w")
    try
        write_header(io)

        for (n_intervals, n_points) in CARTPOLE_CONFIGS
            println(io)
            println(io, "  -- Cart-pole  (FixedIntervals($n_intervals), LGRPoints($n_points)) " * "-" ^ 19)
            r = benchmark_example(CARTPOLE_PATH, n_intervals, n_points; n_runs = CARTPOLE_RUNS)
            write_results(io, "Cart-pole", r)
            flush(io)
        end

        for (n_intervals, n_points) in SHUTTLE_CONFIGS
            println(io)
            println(io, "  -- Space shuttle  (FixedIntervals($n_intervals), LGRPoints($n_points)) " * "-" ^ 15)
            r = benchmark_example(SHUTTLE_PATH, n_intervals, n_points; n_runs = SHUTTLE_RUNS)
            write_results(io, "Space shuttle", r)
            flush(io)
        end

        println(io)
        println(io, "=" ^ 78)
    finally
        close(io)
    end
    println("Results saved to: $out_path")
end

main()

end
