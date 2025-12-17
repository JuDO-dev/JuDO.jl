using Interesso
using JuMP
using JuDO
dop = DynModel(Interesso.Optimizer)
 
const ξ = 0.084
const b, µ, d, G = 5.85, 0.02, 0.00873, 0.15
const A, a = 15.0, 75.0
const p_eq = ((b - µ) / d)^(3 / 2)
const q_eq = p_eq 
 
@phase(dop, t1)
@phase(dop, t2)
@constraint(dop, initial(t1) == 0.0)
@constraint(dop, final(t1) == initial(t2))
 
@variable(dop, 0.01 ≤ p1 ≤ p_eq, DefinedOn(t1))
@variable(dop, 0.01 ≤ p2 ≤ p_eq, DefinedOn(t2))
@variable(dop, 0.01 ≤ q1 ≤ q_eq, DefinedOn(t1)) 
@variable(dop, 0.01 ≤ q2 ≤ q_eq, DefinedOn(t2))
@variable(dop, 0.0 ≤ y, DefinedOn(t1))
 
@constraint(dop, initial(p1) == p_eq / 2)
@constraint(dop, final(p1) == initial(p2))
@constraint(dop, initial(q1) == q_eq / 4)
@constraint(dop, final(q1) == initial(q2))
@constraint(dop, initial(y) == 0.0)
@constraint(dop, final(y) ≤ A)
 
@constraint(dop, derivative(p1) == -ξ * p1 * log(p1 / q1))
@constraint(dop, derivative(p2) == -ξ * p2 * log(p2 / q2))
@constraint(dop, derivative(q1) == q1 * (b - (µ + d * p1 ^ (2 / 3) + G * a)))
@constraint(dop, derivative(q2) == q2 * (b - (µ + d * p2 ^ (2 / 3))))
@constraint(dop, derivative(y) == a)
 
@objective(dop, Min, final(p2))
 
JuDO.optimize!(dop)