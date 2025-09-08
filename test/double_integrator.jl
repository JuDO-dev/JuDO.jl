using Interesso
using DynOptInterface
using JuDO
using Plots


const t_0 = 0.0
const t_f = 10.0

model = DynModel(() -> Interesso.Optimizer(
    default_intervals = FlexibleIntervals(20, 0.0),
    default_points    = LGRPoints(3; order_control = 2),
    default_method    = IntResidual(5),
    default_bounds    = SampledBounds(5),
))

@phase(model, t)
@constraint(model, initial(t) == t_0)
@constraint(model, final(t) == t_f)

@variable(model, -10.0 <= u <= 10.0, DefinedOn(t))
@variable(model, -6.0  <= x <= 6.0,  DefinedOn(t))
@variable(model, -10.0 <= v <= 10.0, DefinedOn(t))
@variable(model, τ, DefinedOn(t))

@constraint(model, initial(x) == 0.0)
@constraint(model, initial(v) == 5.0)
@constraint(model, initial(τ) == 0.0)

@constraint(model, derivative(x) == v)
@constraint(model, derivative(v) == u)
@constraint(model, derivative(τ) == 1.0)

@objective(model, Min,
    integral((x - 5*sin(τ))^2 + (v - 5*cos(τ))^2 + 0.0001*u^2))

JuDO.optimize!(model)

u_sol = dyn_value(model, u)
x_sol = dyn_value(model, x)
v_sol = dyn_value(model, v)

plot(tau -> x_sol(tau), t_0, t_f)

