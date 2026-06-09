#This file should be run directly using a Julia environment with 
#InfiniteOpt and Ipopt loaded

using InfiniteOpt, Ipopt
using Plots


const m_shuttle      = 203000.0 / 32.174
const ρ_0            = 0.002378
const h_r            = 23800.0
const R_e            = 20902900.0
const μ_grav         = 0.14076539e17
const a_0, a_1       = -0.20704, 0.029244
const b_0, b_1, b_2  = 0.07854, -0.61592e-2, 0.621408e-3
const S_ref          = 2690.0
const _outdir = joinpath(@__DIR__, "betts-space-shuttle-config-test")
mkpath(_outdir)

t_total_start = time()
model = InfiniteModel(optimizer_with_attributes(
    Ipopt.Optimizer,
    "print_level"        => 0,
    "max_iter"           => 10_000,
    "nlp_scaling_method" => "gradient-based",
    "tol"                => 1e-6,   
    "acceptable_tol"     => 1e-6,
    "acceptable_iter"    => 10,
))

@infinite_parameter(model, τ in [0.0, 1.0],
                    num_supports      = 30,           
                    derivative_method = OrthogonalCollocation(6))           

@variable(model, 0.0 ≤ T ≤ 2500.0)

@variable(model, 0.0 ≤ scaled_h,                  Infinite(τ))
@variable(model, deg2rad(-89) ≤ θ ≤ deg2rad(89),  Infinite(τ))
@variable(model, Φ,                                Infinite(τ))
@variable(model, 1e-4 ≤ scaled_v,                 Infinite(τ))
@variable(model, deg2rad(-89) ≤ γ ≤ deg2rad(89),  Infinite(τ))
@variable(model, ψ,                                Infinite(τ))

@variable(model, deg2rad(-90) ≤ α ≤ deg2rad(90),  Infinite(τ))
@variable(model, deg2rad(-90) ≤ β ≤ deg2rad(1),   Infinite(τ))
constant_over_collocation(α, τ)
constant_over_collocation(β, τ)


@constraint(model, scaled_h(0.0) == 2.6)
@constraint(model, scaled_h(1.0) == 0.8)
@constraint(model, θ(0.0)        == 0.0)
@constraint(model, Φ(0.0)        == 0.0)
@constraint(model, scaled_v(0.0) == 2.56)
@constraint(model, scaled_v(1.0) == 0.25)
@constraint(model, γ(0.0)        == deg2rad(-1.0))
@constraint(model, γ(1.0)        == deg2rad(-5.0))
@constraint(model, ψ(0.0)        == deg2rad(90.0))

_h     = scaled_h * 1e5
_v     = scaled_v * 1e4
_r     = R_e + _h
_g     = μ_grav / _r^2
_ρ     = ρ_0 * exp(-_h / h_r)
_α_deg = α * (180.0 / pi)
_L     = 0.5 * S_ref * _ρ * _v^2 * (a_0 + a_1 * _α_deg)
_D     = 0.5 * S_ref * _ρ * _v^2 * (b_0 + b_1 * _α_deg + b_2 * _α_deg^2)

@constraint(model, deriv(scaled_h, τ) == T * _v * sin(γ) / 1e5)
@constraint(model, deriv(θ, τ)        == T * _v * cos(γ) * cos(ψ) / _r)
@constraint(model, deriv(Φ, τ)        == T * _v * cos(γ) * sin(ψ) / (_r * cos(θ)))
@constraint(model, deriv(scaled_v, τ) == T * (-_D / m_shuttle - _g * sin(γ)) / 1e4)
@constraint(model, deriv(γ, τ)        == T * (_L * cos(β) / (m_shuttle * _v) +
                                               cos(γ) * (_v / _r - _g / _v)))
@constraint(model, deriv(ψ, τ)        == T * (_L * sin(β) / (m_shuttle * _v * cos(γ)) +
                                               _v * cos(γ) * sin(ψ) * sin(θ) / (_r * cos(θ))))


set_start_value(T, 2000.0)
set_start_value_function(scaled_h, τ -> 2.6  + τ * (0.8          - 2.6))
set_start_value_function(θ,        τ -> 0.0  + τ * deg2rad(45.0))
set_start_value_function(Φ,        τ -> 0.0  + τ * deg2rad(50.0))
set_start_value_function(scaled_v, τ -> 2.56 + τ * (0.25         - 2.56))
set_start_value_function(γ,        τ -> deg2rad(-1.0) + τ * (deg2rad(-5.0)  - deg2rad(-1.0)))
set_start_value_function(ψ,        τ -> deg2rad(90.0) + τ * (deg2rad(-20.0) - deg2rad(90.0)))
set_start_value_function(α,        τ -> 0.0)
set_start_value_function(β,        τ -> 0.0)


@objective(model, Max, θ(1.0))

t_opt_start = time()
optimize!(model)
t_opt_end   = time()

wall_time        = t_opt_end - t_opt_start
ipopt_solve_time = solve_time(model)
total_time       = t_opt_end - t_total_start
T_opt            = value(T)

println("Termination status : ", termination_status(model))
println("Objective value    : ", rad2deg(objective_value(model)), " deg (final latitude)")
println("Optimal final time : ", round(T_opt,            digits = 4), " s")
println("Wall time          : ", round(wall_time,        digits = 4), " s")
println("IPopt solve time   : ", round(ipopt_solve_time, digits = 4), " s")
println("Total time         : ", round(total_time,       digits = 4), " s")


open(joinpath(_outdir, "timing.txt"), "w") do io
    println(io, "Betts Space Shuttle Reentry — Timing Report")
    println(io, "============================================")
    println(io, "Collocation    : OrthogonalCollocation(6),  num_supports = 15")
    println(io, "Final time     : free,  T ∈ (0, 2500] s  (time-scaling τ ∈ [0,1])")
    println(io, "")
    println(io, "Termination status : ", termination_status(model))
    println(io, "Objective value    : ", rad2deg(objective_value(model)), " deg  (final latitude)")
    println(io, "Optimal final time : ", round(T_opt, digits = 6), " s")
    println(io, "")
    println(io, "Wall time (optimize! call) : ", round(wall_time,        digits = 6), " s")
    println(io, "IPopt solve time           : ", round(ipopt_solve_time, digits = 6), " s")
    println(io, "Total time (incl. setup)   : ", round(total_time,       digits = 6), " s")
end


τs    = supports(τ)

h_sol = value(scaled_h)
θ_sol = value(θ)
Φ_sol = value(Φ)
v_sol = value(scaled_v)
γ_sol = value(γ)
ψ_sol = value(ψ)
α_sol = value(α)
β_sol = value(β)

const _OC_NODES = 6
const _STRIDE   = _OC_NODES - 1

function _bary_lagrange(ts_e::AbstractVector, ys_e::AbstractVector, t::Real)
    n = length(ts_e)
    for j in 1:n
        abs(t - ts_e[j]) < 1e-12 && return Float64(ys_e[j])
    end
    w = [prod(1.0 / (ts_e[j] - ts_e[k]) for k in 1:n if k ≠ j) for j in 1:n]
    num = sum(w[j] * ys_e[j] / (t - ts_e[j]) for j in 1:n)
    den = sum(w[j]            / (t - ts_e[j]) for j in 1:n)
    return num / den
end

function _poly_dense(ts_all::Vector{Float64}, ys_all::Vector{Float64};
                     n_fine::Int = 50)
    n_elem = (length(ts_all) - 1) ÷ _STRIDE
    tss = Float64[]
    yss = Float64[]
    for i in 1:n_elem
        a    = (i - 1) * _STRIDE + 1
        b    = a + _OC_NODES - 1
        ts_e = ts_all[a:b]
        ys_e = ys_all[a:b]
        for t in range(ts_e[1], ts_e[end], length = n_fine + 1)[1:end-1]
            push!(tss, t)
            push!(yss, _bary_lagrange(ts_e, ys_e, t))
        end
    end
    push!(tss, ts_all[end])
    push!(yss, ys_all[end])
    return tss, yss
end

τs_plot, h_plot = _poly_dense(τs, h_sol)
_,       θ_plot = _poly_dense(τs, θ_sol)
_,       Φ_plot = _poly_dense(τs, Φ_sol)
_,       v_plot = _poly_dense(τs, v_sol)
_,       γ_plot = _poly_dense(τs, γ_sol)
_,       ψ_plot = _poly_dense(τs, ψ_sol)
_,       α_plot = _poly_dense(τs, α_sol)
_,       β_plot = _poly_dense(τs, β_sol)
ts_plot = τs_plot .* T_opt   

plot_configs = [
    (h_plot, "Altitude",          "Altitude (×10⁵ ft)",  y -> y,  "altitude.png"),
    (θ_plot, "Latitude",          "Latitude (deg)",       rad2deg, "latitude.png"),
    (Φ_plot, "Longitude",         "Longitude (deg)",      rad2deg, "longitude.png"),
    (v_plot, "Velocity",          "Velocity (×10⁴ ft/s)", y -> y,  "velocity.png"),
    (γ_plot, "Flight Path Angle", "FPA (deg)",            rad2deg, "flight_path.png"),
    (ψ_plot, "Azimuth",           "Azimuth (deg)",        rad2deg, "azimuth.png"),
    (α_plot, "Angle of Attack",   "AoA (deg)",            rad2deg, "alpha.png"),
    (β_plot, "Bank Angle",        "Bank Angle (deg)",     rad2deg, "beta.png"),
]

for (y_arr, title, ylabel, transform, fname) in plot_configs
    p = plot(ts_plot, transform.(y_arr);
        title     = title,
        xlabel    = "Time (s)",
        ylabel    = ylabel,
        legend    = false,
        linewidth = 1.5,
        lc        = :blue,
    )
    savefig(p, joinpath(_outdir, fname))
end


traj = plot(
    rad2deg.(Φ_plot),
    rad2deg.(θ_plot),
    h_plot ./ 1000;
    linewidth = 1,
    legend    = nothing,
    xlabel    = "Longitude (deg)",
    ylabel    = "Latitude (deg)",
    zlabel    = "Altitude (km)",
    lc        = :black,
)
savefig(traj, joinpath(_outdir, "trajectory_3d.png"))

println("All results saved to: ", _outdir)
