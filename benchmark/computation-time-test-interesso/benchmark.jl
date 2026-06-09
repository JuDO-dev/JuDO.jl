# This file should be run with an independent Julia envrionment
# with no JuDO loaded, as an example of running the test directly 
# using the underlying Interesso solver

import MathOptInterface as MOI
import DynOptInterface as DOI
using Interesso
using Plots
using Ipopt
using Statistics: mean, std
using Printf

include(joinpath(@__DIR__, "cart_pole.jl"))
include(joinpath(@__DIR__, "space_shuttle.jl"))

const NDF = DOI.NonlinearDynamicFunction

struct LinearInterpolant <: DOI.AbstractDynamicSolution
    y_a::Float64
    y_b::Float64
    t_0::Float64
    t_f::Float64
end
(li::LinearInterpolant)(t::Real) =
    li.y_a + (t - li.t_0) * (li.y_b - li.y_a) / (li.t_f - li.t_0)


const CART_POLE_CONFIGS = [   
    (10, 3), (10, 5),
    (20, 3), (20, 5),
]

const SHUTTLE_CONFIGS = [
    (10, 3), (10, 5),
    (20, 3), (20, 5),
]

const CART_POLE_RUNS = 8  
const SHUTTLE_RUNS   = 8  

# ── model factory ─────────────────────────────────────────────────────────────

function make_model(n_intervals::Int, n_lgr::Int)
    inner = Ipopt.Optimizer()
    MOI.set(inner, MOI.RawOptimizerAttribute("print_level"),        0)
    MOI.set(inner, MOI.RawOptimizerAttribute("max_iter"),           10_000)
    MOI.set(inner, MOI.RawOptimizerAttribute("nlp_scaling_method"), "gradient-based")
    MOI.set(inner, MOI.RawOptimizerAttribute("tol"),                1e-8)
    return Interesso.Optimizer(
        inner             = inner,
        default_intervals = FixedIntervals(n_intervals),
        default_points    = LGRPoints(n_lgr),
        default_method    = Collocation(),
    )
end


_solve!(m::MOI.AbstractOptimizer) = MOI.optimize!(m)

function one_run(problem_fn, plot_fn, model::Interesso.Optimizer, outdir::String)
    t0 = time_ns()
    vars = Base.invokelatest(problem_fn, model)
    _solve!(model)
    Base.invokelatest(plot_fn, model, vars, outdir)
    total_wall = (time_ns() - t0) * 1e-9
    ipopt_time = MOI.get(model.inner, MOI.SolveTimeSec())
    return total_wall, ipopt_time
end


function benchmark_problem(problem_fn, plot_fn, outdir, n_intervals::Int, n_lgr::Int; n_runs::Int)
    model = make_model(n_intervals, n_lgr)
    mkpath(outdir)

    total_walls = Float64[]
    ipopt_times = Float64[]

    for _ in 1:n_runs
        tw, ip = one_run(problem_fn, plot_fn, model, outdir)
        push!(total_walls, tw)
        push!(ipopt_times, ip)
    end

    overheads = total_walls .- ipopt_times

    p(v) = (first = v[1], rest = v[2:end])
    return (
        total    = p(total_walls),
        ipopt    = p(ipopt_times),
        overhead = p(overheads),
    )
end


function write_header(io, cart_runs, shuttle_runs)
    println(io)
    println(io, "=" ^ 96)
    println(io, "  Interesso Overhead Benchmark")
    println(io, "  Method: Collocation  |  Points: LGRPoints(k)  |  Intervals: FixedIntervals(N)")
    println(io, "  Each run: build + solve + plot timed together as total wall time")
    println(io, "  Cart-pole:     $(cart_runs) runs (run 1 = compilation, runs 2-$(cart_runs) = measurement)")
    println(io, "  Space shuttle: $(shuttle_runs) runs (run 1 = compilation, runs 2-$(shuttle_runs) = measurement)")
    println(io, "  Interesso overhead = total wall - Ipopt  (build + transcription + plot I/O)")
    println(io, "=" ^ 96)
end

function write_row(io, label, r)
    if isempty(r.rest)
        @printf io "    %-36s  first-run: %8.4f s\n" label r.first
    else
        @printf io "    %-36s  first-run: %8.4f s   mean: %8.4f s   std: %8.4f s\n" label r.first mean(r.rest) std(r.rest)
    end
end

function write_config_results(io, problem_name, n_intervals, n_lgr, r)
    n_nodes = n_intervals * n_lgr
    @printf io "\n  %-16s  intervals = %-3d  LGRPoints = %d  (total nodes = %d)\n" problem_name n_intervals n_lgr n_nodes
    write_row(io, "Total wall time",        r.total)
    write_row(io, "  Ipopt reported time",  r.ipopt)
    write_row(io, "  Interesso overhead",   r.overhead)
end

# ── main ──

function main()
    out_path  = joinpath(@__DIR__, "benchmark_results.txt")
    cp_outdir = joinpath(@__DIR__, "benchmark-plots", "cart-pole")
    ss_outdir = joinpath(@__DIR__, "benchmark-plots", "space-shuttle")

    open(out_path, "w") do io
        write_header(io, CART_POLE_RUNS, SHUTTLE_RUNS)

        println(io)
        println(io, "  -- Cart-pole " * "-" ^ 73)
        for (n_intervals, n_lgr) in CART_POLE_CONFIGS
            r = benchmark_problem(cart_pole, cart_pole_plot, cp_outdir, n_intervals, n_lgr; n_runs = CART_POLE_RUNS)
            write_config_results(io, "Cart-pole", n_intervals, n_lgr, r)
            flush(io)
        end

        println(io)
        println(io, "  -- Space shuttle " * "-" ^ 69)
        for (n_intervals, n_lgr) in SHUTTLE_CONFIGS
            r = benchmark_problem(space_shuttle_reentry, space_shuttle_plot, ss_outdir, n_intervals, n_lgr; n_runs = SHUTTLE_RUNS)
            write_config_results(io, "Space shuttle", n_intervals, n_lgr, r)
            flush(io)
        end

        println(io)
        println(io, "=" ^ 96)
    end

    println("Results saved to: $out_path")
end

main()
