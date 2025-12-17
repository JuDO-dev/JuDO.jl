using Interesso
using JuMP
using JuDO
dop = DynModel(Interesso.Optimizer)
 
const m = 203000 / 32.174
const ρ_0, h_r, R_e = 0.002378, 23800.0, 20902900.0
const μ = 0.14076539e17
const a_0, a_1 = -0.20704, 0.029244
const b_0, b_1, b_2 = 0.07854, -0.61592e-2, 0.621408e-3
const S = 2690
 
# Phase
@phase(dop, t)
@constraint(dop, initial(t) == 0)
@constraint(dop,   final(t) ≤  2500)
 
# States
@variable(dop,            0 ≤ h,               DefinedOn(t))
@variable(dop, deg2rad(-89) ≤ θ ≤ deg2rad(89), DefinedOn(t))
@variable(dop,            1 ≤ v,               DefinedOn(t))
@variable(dop, deg2rad(-89) ≤ γ ≤ deg2rad(89), DefinedOn(t))
@variable(dop,                ψ,               DefinedOn(t))
 
# Controls
@variable(dop, deg2rad(-90) ≤ α ≤ deg2rad(90), DefinedOn(t))
@variable(dop, deg2rad(-90) ≤ β ≤ deg2rad(1),  DefinedOn(t))
 
# Boundary conditions
@constraint(dop, initial(h) == 2.6e5)
@constraint(dop,   final(h) == 0.8e5)
@constraint(dop, initial(θ) == 0)
@constraint(dop, initial(v) == 25600)
@constraint(dop,   final(v) == 2500)
@constraint(dop, initial(γ) == deg2rad(1))
@constraint(dop,   final(γ) == deg2rad(-5))
@constraint(dop, initial(ψ) == deg2rad(90))
 
# Expressions
@expression(dop, r, R_e + h)
@expression(dop, g, μ / r^2)
@expression(dop, ρ, ρ_0 * exp(-h / h_r))
@expression(dop, α_deg, (180 / pi) * α) 
@expression(dop, L, 0.5 * S * ρ * v^2 * (a_0 + a_1 * α_deg))
@expression(dop, D, 0.5 * S * ρ * v^2 * (b_0 + b_1 * α_deg + b_2 * α_deg))
 
# Differential equations
@constraint(dop, derivative(h) == v * sin(γ))
@constraint(dop, derivative(θ) == v * cos(γ) * cos(ψ) / r)
@constraint(dop, derivative(v) == -D / m - g * sin(γ))
@constraint(dop, derivative(γ) == L * cos(β) / (m * v) + cos(γ) * (v / r - g / v))
@constraint(dop, derivative(ψ) == L * sin(β) / (m * v * cos(γ)) + v * cos(γ) * sin(ψ) * sin(θ) / (r * cos(θ)))
 
# Objective
@objective(dop, Max, final(θ))

JuDO.optimize!(dop)