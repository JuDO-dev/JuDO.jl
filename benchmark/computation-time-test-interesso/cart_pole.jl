# Build the cart-pole problem of test/cartpole.jl directly on an Interesso optimizer.
function cart_pole(model::Interesso.Optimizer)
    MOI.empty!(model)

    g, l, m_1, m_2 = 9.81, 0.5, 1.0, 0.3
    t_0, t_f = 0.0, 2.0
    u_max, r_max = 20.0, 2.0

    t = DOI.add_phase(model)
    MOI.add_constraint(model, DOI.Initial(t), MOI.EqualTo(t_0))
    MOI.add_constraint(model, DOI.Final(t), MOI.EqualTo(t_f))

    u = DOI.add_dynamic_variable(model, t)
    r = DOI.add_dynamic_variable(model, t)
    θ = DOI.add_dynamic_variable(model, t)
    ν = DOI.add_dynamic_variable(model, t)
    ω = DOI.add_dynamic_variable(model, t)

    MOI.add_constraint(model, u, MOI.Interval(-u_max, u_max))
    MOI.add_constraint(model, r, MOI.Interval(0.0, r_max))

    MOI.add_constraint(model, DOI.Initial(r), MOI.EqualTo(0.0))
    MOI.add_constraint(model, DOI.Initial(θ), MOI.EqualTo(0.0))
    MOI.add_constraint(model, DOI.Initial(ν), MOI.EqualTo(0.0))
    MOI.add_constraint(model, DOI.Initial(ω), MOI.EqualTo(0.0))

    MOI.add_constraint(model, DOI.Final(r), MOI.EqualTo(1.0))
    MOI.add_constraint(model, DOI.Final(θ), MOI.EqualTo(1.0 * pi))
    MOI.add_constraint(model, DOI.Final(ν), MOI.EqualTo(0.0))
    MOI.add_constraint(model, DOI.Final(ω), MOI.EqualTo(0.0))

    sinθ = NDF(:sin, [θ], t)
    cosθ = NDF(:cos, [θ], t)
    den = NDF(:+, [m_1, NDF(:*, [m_2, NDF(:^, [sinθ, 2], t)], t)], t)

    num_ν = NDF(:+, [
        NDF(:*, [l * m_2, sinθ, NDF(:^, [ω, 2], t)], t),
        u,
        NDF(:*, [m_2 * g, cosθ, sinθ], t),
    ], t)
    num_ω = NDF(:+, [
        NDF(:*, [-l * m_2, cosθ, sinθ, NDF(:^, [ω, 2], t)], t),
        NDF(:*, [-1.0, u, cosθ], t),
        NDF(:*, [-(m_1 + m_2) * g, sinθ], t),
    ], t)

    MOI.add_constraint(model, DOI.ExplicitDifferentialFunction(r, NDF(:*, [1.0, ν], t)), MOI.EqualTo(0.0))
    MOI.add_constraint(model, DOI.ExplicitDifferentialFunction(ν, NDF(:/, [num_ν, den], t)), MOI.EqualTo(0.0))
    MOI.add_constraint(model, DOI.ExplicitDifferentialFunction(θ, NDF(:*, [1.0, ω], t)), MOI.EqualTo(0.0))
    MOI.add_constraint(model, DOI.ExplicitDifferentialFunction(ω, NDF(:/, [num_ω, NDF(:*, [l, den], t)], t)), MOI.EqualTo(0.0))

    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    obj_fun = DOI.MultiPhaseIntegral([NDF(:^, [u, 2], t)])
    MOI.set(model, MOI.ObjectiveFunction{typeof(obj_fun)}(), obj_fun)

    MOI.set(model, DOI.DynamicVariableStart(), r, LinearInterpolant(0.0, 1.0, t_0, t_f))
    MOI.set(model, DOI.DynamicVariableStart(), θ, LinearInterpolant(0.0, 1.0 * pi, t_0, t_f))

    return (r = r, θ = θ, u = u)
end

# Save the cart position, pole angle and control plots of test/cartpole.jl.
function cart_pole_plot(model::Interesso.Optimizer, vars, outdir::String)
    sols = map(x -> MOI.get(model, DOI.DynamicVariableSolution(), x), vars)
    t_0, t_f = sols.r.initial, sols.r.final
    time_points = collect(range(t_0, t_f, length = 100))

    plot_configs = [
        (sols.r, "Cart Position (m)", "cartpole_r.png"),
        (sols.θ, "Theta (rad)", "cartpole_theta.png"),
        (sols.u, "Control Force (N)", "cartpole_u.png"),
    ]
    for (sol, ylab, fname) in plot_configs
        p = Plots.plot(time_points, [sol(t) for t in time_points];
            xlabel = "Time (s)",
            ylabel = ylab,
            legend = false,
            xlims  = (t_0, t_f),
            lw     = 1,
            grid   = true,
            lc     = :black)
        savefig(p, joinpath(outdir, fname))
    end
    return nothing
end
