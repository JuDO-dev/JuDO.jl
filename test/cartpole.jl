using Interesso
using JuMP
using Plots
using DynOptInterface

#need to be commented

using MathOptInterface

const g = 9.81
const l = 0.5
const m_1 = 1.0
const m_2 = 0.3
const t_0 = 0.0
const t_f = 2.0
const u_max = 20.0
const r_max = 2.0

dop = JuDO.DynModel(Interesso.Optimizer)

struct LinearInterpolant <: DynOptInterface.AbstractDynamicSolution
    y_a::Float64
    y_b::Float64
end
(li::LinearInterpolant)(t::Real) = li.y_a + (t - t_0) * (li.y_b - li.y_a) / (t_f - t_0)

JuDO.@phase(dop, t)
@constraint(dop, JuDO.initial(t) == 0)
@constraint(dop, JuDO.final(t) == 2)

@variable(dop, -u_max <= u <= u_max, JuDO.DefinedOn(t))
@variable(dop, 0 <= r <= r_max, JuDO.DefinedOn(t))

@variable(dop, θ, JuDO.DefinedOn(t))  
@variable(dop, ν, JuDO.DefinedOn(t))
@variable(dop, ω, JuDO.DefinedOn(t))

@constraint(dop, JuDO.initial(r) == 0)
@constraint(dop, JuDO.initial(θ) == 0)
@constraint(dop, JuDO.initial(ν) == 0)
@constraint(dop, JuDO.initial(ω) == 0)

@constraint(dop, JuDO.final(r) == 1)
@constraint(dop, JuDO.final(θ) == pi)
@constraint(dop, JuDO.final(ν) == 0)
@constraint(dop, JuDO.final(ω) == 0)

#to do:code needed for the warmstart 

@constraint(dop, JuDO.derivative(r) == ν)
@constraint(dop, JuDO.derivative(ν) == (l*m_2*sin(θ)*ω^2 + u + m_2*g*cos(θ)*sin(θ))/(m_1 + m_2*sin(θ)^2))

@constraint(dop, JuDO.derivative(θ) == ω)
@constraint(dop, JuDO.derivative(ω) == (-l*m_2*cos(θ)*sin(θ)*ω^2 - u*cos(θ) - (m_1 + m_2)*g*sin(θ))/(l*(m_1 + m_2*sin(θ)^2)))

@objective(dop, Min, JuDO.integral(u^2))

JuDO.set_interpolant(dop, LinearInterpolant(0.0, 1.0), r)
JuDO.set_interpolant(dop, LinearInterpolant(0.0, pi), θ)


JuDO.optimize(dop, intervals=FlexibleIntervals(4,0.5), points=LGRPoints(8))

rsol=JuDO.value(dop, r)
plot(t->rsol(t),xlims=(t_0,t_f))