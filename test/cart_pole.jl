using Interesso
using DynOptInterface
using JuDO
using Plots


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

@phase(dop, t)
@constraint(dop, initial(t) == 0)
@constraint(dop, final(t) == 2)

@variable(dop, -u_max <= u <= u_max, DefinedOn(t))
@variable(dop, 0 <= r <= r_max, DefinedOn(t))

@variable(dop, θ, DefinedOn(t))  
@variable(dop, ν, DefinedOn(t))
@variable(dop, ω, DefinedOn(t))

@constraint(dop, initial(r) == 0)
@constraint(dop, initial(θ) == 0)
@constraint(dop, initial(ν) == 0)
@constraint(dop, initial(ω) == 0)

@constraint(dop, final(r) == 1)
@constraint(dop, final(θ) == pi)
@constraint(dop, final(ν) == 0)
@constraint(dop, final(ω) == 0)

#to do:code needed for the warmstart 

@constraint(dop, derivative(r) == ν)
@constraint(dop, derivative(ν) == (l*m_2*sin(θ)*ω^2 + u + m_2*g*cos(θ)*sin(θ))/(m_1 + m_2*sin(θ)^2))

@constraint(dop, derivative(θ) == ω)
@constraint(dop, derivative(ω) == (-l*m_2*cos(θ)*sin(θ)*ω^2 - u*cos(θ) - (m_1 + m_2)*g*sin(θ))/(l*(m_1 + m_2*sin(θ)^2)))

@objective(dop, Min, integral(u^2))

JuDO.warmstart!(dop, LinearInterpolant(0.0, 1.0), r)
JuDO.warmstart!(dop, LinearInterpolant(0.0, pi), θ)

JuDO.optimize!(dop, intervals=FlexibleIntervals(4,0.5), points=LGRPoints(8))

ws = JuDO.get_solutions(dop)

JuDO.warmstart!(dop, ws)
JuDO.optimize!(dop, intervals=FlexibleIntervals(4,0.5), points=LGRPoints(8))

