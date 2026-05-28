using Interesso, JuMP, JuDO, DynOptInterface
using Plots

model = DynModel(Interesso.Optimizer)

## Time as a phase [0, 10]
@phase(model, t, 0.0, 10.0)

## Dynamic Variables
@variable(model, -1.0 <= u <= 1.0, DefinedOn(t))
@variable(model, x, DefinedOn(t))
@variable(model, v, DefinedOn(t))

## Boundary Conditions
@constraint(model, initial(x) == 0.0)
@constraint(model, initial(v) == 0.0)
@constraint(model, final(x) == 20.0)
@constraint(model, final(v) == 0.0)

## Differential Equations
@constraint(model, derivative(v) == u)
@constraint(model, derivative(x) == v)

## Objective
@objective(model, Min, integral(2*x^2 + 2*v^2))

JuDO.optimize!(model)

## Extract solutions
t_0 = phase_initial(t).value
t_f = 10.0

x_sol = dyn_value(model, x)
v_sol = dyn_value(model, v)
u_sol = dyn_value(model, u)

## Plot
p1 = plot(τ -> x_sol(τ), t_0, t_f; label="x(t)", ylabel="Position")
p2 = plot(τ -> v_sol(τ), t_0, t_f; label="v(t)", ylabel="Velocity")
p3 = plot(τ -> u_sol(τ), t_0, t_f; label="u(t)", ylabel="Control", xlabel="t")

display(plot(p1, p2, p3; layout=(3, 1), size=(600, 700), legend=:topright))