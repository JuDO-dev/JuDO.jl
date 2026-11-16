# Build the space shuttle reentry problem of test/space-shuttle.jl directly on an Interesso optimizer.
function space_shuttle_reentry(model::Interesso.Optimizer)
    MOI.empty!(model)

    m = 203000 / 32.174
    ρ_0, h_r, R_e = 0.002378, 23800.0, 20902900.0
    μ = 0.14076539e17
    a_0, a_1 = -0.20704, 0.029244
    b_0, b_1, b_2 = 0.07854, -0.61592e-2, 0.621408e-3
    S = 2690.0
    t_0, t_f_max = 0.0, 2500.0

    t = DOI.add_phase(model)
    MOI.add_constraint(model, DOI.Initial(t), MOI.EqualTo(t_0))
    MOI.add_constraint(model, DOI.Final(t), MOI.LessThan(t_f_max))

    scaled_h = DOI.add_dynamic_variable(model, t)
    θ        = DOI.add_dynamic_variable(model, t)
    Φ        = DOI.add_dynamic_variable(model, t)
    scaled_v = DOI.add_dynamic_variable(model, t)
    γ        = DOI.add_dynamic_variable(model, t)
    ψ        = DOI.add_dynamic_variable(model, t)
    α        = DOI.add_dynamic_variable(model, t)
    β        = DOI.add_dynamic_variable(model, t)

    MOI.add_constraint(model, scaled_h, MOI.Interval(0.0, Inf))
    MOI.add_constraint(model, θ,        MOI.Interval(deg2rad(-89), deg2rad(89)))
    MOI.add_constraint(model, scaled_v, MOI.Interval(1e-4, Inf))
    MOI.add_constraint(model, γ,        MOI.Interval(deg2rad(-89), deg2rad(89)))
    MOI.add_constraint(model, α,        MOI.Interval(deg2rad(-90), deg2rad(90)))
    MOI.add_constraint(model, β,        MOI.Interval(deg2rad(-90), deg2rad(1)))

    MOI.add_constraint(model, DOI.Initial(scaled_h), MOI.EqualTo(2.6))
    MOI.add_constraint(model, DOI.Final(scaled_h),   MOI.EqualTo(0.8))
    MOI.add_constraint(model, DOI.Initial(θ),        MOI.EqualTo(0.0))
    MOI.add_constraint(model, DOI.Initial(Φ),        MOI.EqualTo(0.0))
    MOI.add_constraint(model, DOI.Initial(scaled_v), MOI.EqualTo(2.56))
    MOI.add_constraint(model, DOI.Final(scaled_v),   MOI.EqualTo(0.25))
    MOI.add_constraint(model, DOI.Initial(γ),        MOI.EqualTo(deg2rad(-1)))
    MOI.add_constraint(model, DOI.Final(γ),          MOI.EqualTo(deg2rad(-5)))
    MOI.add_constraint(model, DOI.Initial(ψ),        MOI.EqualTo(deg2rad(90)))

    h     = NDF(:*, [scaled_h, 1e5], t)
    v     = NDF(:*, [scaled_v, 1e4], t)
    r     = NDF(:+, [R_e, h], t)
    g     = NDF(:/, [μ, NDF(:^, [r, 2], t)], t)
    ρ     = NDF(:*, [ρ_0, NDF(:exp, [NDF(:*, [-1.0 / h_r, h], t)], t)], t)
    α_deg = NDF(:*, [180 / pi, α], t)
    q     = NDF(:*, [0.5 * S, ρ, NDF(:^, [v, 2], t)], t)
    L     = NDF(:*, [q, NDF(:+, [a_0, NDF(:*, [a_1, α_deg], t)], t)], t)
    D     = NDF(:*, [q, NDF(:+, [b_0, NDF(:*, [b_1, α_deg], t), NDF(:*, [b_2, NDF(:^, [α_deg, 2], t)], t)], t)], t)

    sinγ, cosγ = NDF(:sin, [γ], t), NDF(:cos, [γ], t)
    sinψ, cosψ = NDF(:sin, [ψ], t), NDF(:cos, [ψ], t)
    sinθ, cosθ = NDF(:sin, [θ], t), NDF(:cos, [θ], t)
    sinβ, cosβ = NDF(:sin, [β], t), NDF(:cos, [β], t)

    ḣ = NDF(:*, [v, sinγ], t)
    θ̇ = NDF(:/, [NDF(:*, [v, cosγ, cosψ], t), r], t)
    Φ̇ = NDF(:/, [NDF(:*, [v, cosγ, sinψ], t), NDF(:*, [r, cosθ], t)], t)
    v̇ = NDF(:-, [NDF(:/, [NDF(:*, [-1.0, D], t), m], t), NDF(:*, [g, sinγ], t)], t)
    γ̇ = NDF(:+, [
        NDF(:/, [NDF(:*, [L, cosβ], t), NDF(:*, [m, v], t)], t),
        NDF(:*, [cosγ, NDF(:-, [NDF(:/, [v, r], t), NDF(:/, [g, v], t)], t)], t),
    ], t)
    ψ̇ = NDF(:+, [
        NDF(:/, [NDF(:*, [L, sinβ], t), NDF(:*, [m, v, cosγ], t)], t),
        NDF(:/, [NDF(:*, [v, cosγ, sinψ, sinθ], t), NDF(:*, [r, cosθ], t)], t),
    ], t)

    MOI.add_constraint(model, DOI.ExplicitDifferentialFunction(scaled_h, NDF(:/, [ḣ, 1e5], t)), MOI.EqualTo(0.0))
    MOI.add_constraint(model, DOI.ExplicitDifferentialFunction(θ, θ̇), MOI.EqualTo(0.0))
    MOI.add_constraint(model, DOI.ExplicitDifferentialFunction(Φ, Φ̇), MOI.EqualTo(0.0))
    MOI.add_constraint(model, DOI.ExplicitDifferentialFunction(scaled_v, NDF(:/, [v̇, 1e4], t)), MOI.EqualTo(0.0))
    MOI.add_constraint(model, DOI.ExplicitDifferentialFunction(γ, γ̇), MOI.EqualTo(0.0))
    MOI.add_constraint(model, DOI.ExplicitDifferentialFunction(ψ, ψ̇), MOI.EqualTo(0.0))

    MOI.set(model, DOI.DynamicVariableStart(), scaled_h, LinearInterpolant(2.6, 0.8, t_0, t_f_max))
    MOI.set(model, DOI.DynamicVariableStart(), θ,        LinearInterpolant(0.0, deg2rad(45), t_0, t_f_max))
    MOI.set(model, DOI.DynamicVariableStart(), Φ,        LinearInterpolant(0.0, deg2rad(50), t_0, t_f_max))
    MOI.set(model, DOI.DynamicVariableStart(), scaled_v, LinearInterpolant(2.56, 0.25, t_0, t_f_max))
    MOI.set(model, DOI.DynamicVariableStart(), γ,        LinearInterpolant(deg2rad(-1), deg2rad(-5), t_0, t_f_max))
    MOI.set(model, DOI.DynamicVariableStart(), ψ,        LinearInterpolant(deg2rad(90), deg2rad(-20), t_0, t_f_max))

    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    obj_fun = DOI.NonlinearBoundaryFunction(:+, [DOI.Final(θ)])
    MOI.set(model, MOI.ObjectiveFunction{typeof(obj_fun)}(), obj_fun)

    return (scaled_h = scaled_h, θ = θ, Φ = Φ, scaled_v = scaled_v, γ = γ, ψ = ψ, α = α, β = β)
end

# Save the trajectory and state/control plots of test/space-shuttle.jl.
function space_shuttle_plot(model::Interesso.Optimizer, vars, outdir::String)
    sols = map(x -> MOI.get(model, DOI.DynamicVariableSolution(), x), vars)
    ts = collect(range(sols.scaled_h.initial, sols.scaled_h.final, length = 500))

    plot_configs = [
        (sols.scaled_h, "Altitude (10⁵ ft)",      y -> y,          "altitude.png"),
        (sols.θ,        "Latitude (deg)",          y -> rad2deg(y), "latitude.png"),
        (sols.Φ,        "Longitude (deg)",         y -> rad2deg(y), "longitude.png"),
        (sols.scaled_v, "Velocity (10⁴ ft/s)",    y -> y,          "velocity.png"),
        (sols.γ,        "Flight Path Angle (deg)", y -> rad2deg(y), "flight_path.png"),
        (sols.ψ,        "Azimuth (deg)",           y -> rad2deg(y), "Azimuth.png"),
        (sols.α,        "Angle of Attack (deg)",   y -> rad2deg(y), "alpha.png"),
        (sols.β,        "Bank Angle (deg)",        y -> rad2deg(y), "beta.png"),
    ]
    traj = Plots.plot(
        rad2deg.(sols.Φ.(ts)),
        rad2deg.(sols.θ.(ts)),
        sols.scaled_h.(ts);
        linewidth = 1,
        legend = nothing,
        xlabel = "Longitude (deg)",
        ylabel = "Latitude (deg)",
        zlabel = "Altitude (10⁵ ft)",
        lc = :black
    )
    savefig(traj, joinpath(outdir, "3-d-trajectory.png"))
    for (sol, ylab, scale_fn, fname) in plot_configs
        p = Plots.plot(ts, t -> scale_fn(sol(t));
            legend = false,
            ylabel = ylab,
            xlabel = "Time (s)",
            lw     = 1,
            lc     = :black
        )
        savefig(p, joinpath(outdir, fname))
    end
    return nothing
end
