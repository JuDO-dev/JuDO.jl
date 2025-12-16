using Interesso
using DynOptInterface
using JuDO
using Plots


const t_0 = 0.0
const t_f = 4.0

model = DynModel(() -> Interesso.Optimizer(
    default_intervals = FlexibleIntervals(20, 0.1),
    default_points    = LGRPoints(3; order_control = 2),
    default_method    = IntResidual(5),
    default_bounds    = SampledBounds(5),
))

@phase(model, t)
@constraint(model, initial(t) == t_0)
@constraint(model, final(t) == t_f)

@variable(model, -1.0 <= u <= 1.0, DefinedOn(t))
@variable(model, x, DefinedOn(t))
@variable(model, v, DefinedOn(t))

@constraint(model, initial(x) == 0.0)
@constraint(model, initial(v) == 1.0)

@constraint(model, derivative(x) == v)
@constraint(model, derivative(v) == (1 - x^2) * v + u - x)

@objective(model, Min, integral(0.5*x^2 + 0.5*v^2))

JuDO.optimize!(model)

u_sol = dyn_value(model, u)
plot(tau -> u_sol(tau), t_0, t_f)