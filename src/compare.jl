import MathOptInterface as MOI
import DynOptInterface as DOI
using JuDO
using Interesso
using SLOW

include(joinpath(@__DIR__, "..", "example", "cart_pole.jl"))

# optimizer = SLOW.Optimizer()
# MOI.set(optimizer, MOI.RawOptimizerAttribute("λ0"), nothing)
# MOI.set(optimizer, MOI.RawOptimizerAttribute("ρ0"), 10.0)
# MOI.set(optimizer, MOI.RawOptimizerAttribute("h_norm"), 1)
# MOI.set(optimizer, MOI.RawOptimizerAttribute("max_iter"), 1000)
# MOI.set(optimizer, MOI.RawOptimizerAttribute("max_time"), 60.0)

model1 = Interesso.Optimizer(
    # inner = SLOW.Optimizer(),
    default_intervals = FlexibleIntervals(4, 0.5),
    default_points    = LGRPoints(8),
    # default_method    = IntResidual(5),
    # default_bounds    = SampledBounds(10),
)

_, _, _, _ = cart_pole(model1)
ws1 = Interesso.get_solutions(model1)

const g = 9.81
const l = 0.5
const m_1 = 1.0
const m_2 = 0.3
const t_0 = 0.0
const t_f = 2.0
const u_max = 20.0
const r_max = 2.0

factory = () -> begin
    # inner = SLOW.Optimizer()
    # MOI.set(inner, MOI.RawOptimizerAttribute("λ0"), nothing)
    # MOI.set(inner, MOI.RawOptimizerAttribute("ρ0"), 10.0)
    # MOI.set(inner, MOI.RawOptimizerAttribute("h_norm"), 1)
    # MOI.set(inner, MOI.RawOptimizerAttribute("max_iter"), 1000)
    # MOI.set(inner, MOI.RawOptimizerAttribute("max_time"), 60.0)

    Interesso.Optimizer(
        # inner             = SLOW.Optimizer(),
        default_intervals = FlexibleIntervals(4, 0.5),
        default_points    = LGRPoints(8),
        # default_method    = IntResidual(5),
        # default_bounds    = SampledBounds(10),
    )
end

model = DynModel(factory)

struct LinearInterpolant <: DOI.AbstractDynamicSolution
    y_a::Float64
    y_b::Float64
end
(li::LinearInterpolant)(t::Real) = li.y_a + (t - t_0) * (li.y_b - li.y_a) / (t_f - t_0)

@phase(model, t)
@constraint(model, initial(t) == 0.0)
@constraint(model, final(t) == 2.0)

@variable(model, -u_max <= u <= u_max, DefinedOn(t))
@variable(model, 0 <= r <= r_max, DefinedOn(t))

@variable(model, θ, DefinedOn(t))  
@variable(model, v, DefinedOn(t))
@variable(model, ω, DefinedOn(t))

@constraint(model, initial(r) == 0.0)
@constraint(model, initial(θ) == 0.0)
@constraint(model, initial(v) == 0.0)
@constraint(model, initial(ω) == 0.0)

@constraint(model, final(r) == 1.0)
@constraint(model, final(θ) == 1.0 * pi)
@constraint(model, final(v) == 0.0)
@constraint(model, final(ω) == 0.0)

#to do:code needed for the warmstart 

@constraint(model, derivative(r) == v)
@constraint(model, derivative(v) == (l*m_2*sin(θ)*ω^2 + u + m_2*g*cos(θ)*sin(θ)) / (m_1 + m_2*sin(θ)^2))
@constraint(model, derivative(θ) == ω)
@constraint(model, derivative(ω) == ((-1.0)*l*m_2*cos(θ)*sin(θ)*ω^2 + (-1.0)*u*cos(θ) + (-1.0)*(m_1 + m_2)*g*sin(θ)) / (l*(m_1 + m_2*sin(θ)^2)))

@objective(model, Min, integral(u^2))

JuDO.warmstart!(model, LinearInterpolant(0.0, 1.0), r)
JuDO.warmstart!(model, LinearInterpolant(0.0, 1.0 * pi), θ)
JuDO.warmstart!(model, LinearInterpolant(0.0, 0.0), u)
JuDO.warmstart!(model, LinearInterpolant(0.0, 0.0), v)
JuDO.warmstart!(model, LinearInterpolant(0.0, 0.0), ω)

# # JuDO.warmstart!(model, ws1)
JuDO.optimize!(model)

ws = JuDO.get_solutions(model)

# JuDO.warmstart!(model, ws)
# JuDO.optimize!(model)

open("ws.txt", "w") do io
    println(io, ws["u"])
end

open("ws1.txt", "w") do io
    println(io, ws1["u"])
end

# MOI.empty!(model1)
# _, _, _, _ = cart_pole(model1; starts = ws)