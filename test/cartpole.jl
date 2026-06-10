using Interesso
using JuMP
using Plots
using JuDO  
using DynOptInterface


const g = 9.81
const l = 0.5
const m_1 = 1.0
const m_2 = 0.3
const t_0 = 0.0
const t_f = 2.0
const u_max = 20.0
const r_max = 2.0

dop = DynModel(Interesso.Optimizer)

struct LinearInterpolant <: DynOptInterface.AbstractDynamicSolution
    y_a::Float64
    y_b::Float64
end
(li::LinearInterpolant)(t::Real) = li.y_a + (t - t_0) * (li.y_b - li.y_a) / (t_f - t_0)

JuDO.@phase(dop, t)
JuMP.@constraint(dop, initial(t) == 0)
JuMP.@constraint(dop, final(t) == 2)

JuMP.@variable(dop, -u_max <= u <= u_max, DefinedOn(t))
JuMP.@variable(dop, 0 <= r <= r_max, DefinedOn(t))

JuMP.@variable(dop, θ, DefinedOn(t))  
JuMP.@variable(dop, ν, DefinedOn(t))
JuMP.@variable(dop, ω, DefinedOn(t))

JuMP.@constraint(dop, initial(r) == 0)
JuMP.@constraint(dop, initial(θ) == 0)
JuMP.@constraint(dop, initial(ν) == 0)
JuMP.@constraint(dop, initial(ω) == 0)

JuMP.@constraint(dop, final(r) == 1)
JuMP.@constraint(dop, final(θ) == pi)
JuMP.@constraint(dop, final(ν) == 0)
JuMP.@constraint(dop, final(ω) == 0)

JuMP.@constraint(dop, derivative(r) == ν)
JuMP.@constraint(dop, derivative(ν) == (l*m_2*sin(θ)*ω^2 + u + m_2*g*cos(θ)*sin(θ))/(m_1 + m_2*sin(θ)^2))

JuMP.@constraint(dop, derivative(θ) == ω)
JuMP.@constraint(dop, derivative(ω) == (-l*m_2*cos(θ)*sin(θ)*ω^2 - u*cos(θ) - (m_1 + m_2)*g*sin(θ))/(l*(m_1 + m_2*sin(θ)^2)))

JuMP.@objective(dop, Min, integral(u^2))

JuDO.warmstart!(dop, LinearInterpolant(0.0, 1.0), r)
JuDO.warmstart!(dop, LinearInterpolant(0.0, pi), θ)


JuDO.optimize!(dop,intervals=FixedIntervals(20), points=LGRPoints(5))

rsol=dyn_value(dop, r)
thetasol=dyn_value(dop, θ)
nusol=dyn_value(dop, ν)
omegasol=dyn_value(dop, ω)
usol=dyn_value(dop, u)

time_points = collect(range(t_0, t_f, length=100))
const _cartpole_outdir = joinpath(@__DIR__)

r_values = [rsol(t) for t in time_points]
p = Plots.plot(time_points, r_values;
    xlabel = "Time (s)",
    ylabel = "Angular Velocity (rad/s)",
    legend = false,
    xlims  = (t_0, t_f),
    lw     = 1,
    grid   = true,
    lc    = :black)

savefig(p, joinpath(_cartpole_outdir, "cartpole_r.png"))


thetasol_values = [thetasol(t) for t in time_points]
q = Plots.plot(time_points, thetasol_values;
    xlabel = "Time (s)",
    ylabel = "Theta (rad)",
    legend = false,
    xlims  = (t_0, t_f),
    lw     = 1,
    grid   = true,
    lc    = :black)

savefig(q, joinpath(_cartpole_outdir, "cartpole_theta.png"))

u_values = [usol(t) for t in time_points]
s = Plots.plot(time_points, u_values;
    xlabel = "Time (s)",
    ylabel = "Control Force (N)",
    legend = false,
    xlims  = (t_0, t_f),
    lw     = 1,
    grid   = true,
    lc    = :black)

savefig(s, joinpath(_cartpole_outdir, "cartpole_u.png"))