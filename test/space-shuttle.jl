using Interesso, JuMP, JuDO, DynOptInterface
using Plots
dop = DynModel(Interesso.Optimizer)
 
const m = 203000 / 32.174
const ρ_0, h_r, R_e = 0.002378, 23800.0, 20902900.0
const μ = 0.14076539e17
const a_0, a_1 = -0.20704, 0.029244
const b_0, b_1, b_2 = 0.07854, -0.61592e-2, 0.621408e-3
const S = 2690
 
struct LinearInterpolant <: DynOptInterface.AbstractDynamicSolution
    y_a::Float64
    y_b::Float64
end
(li::LinearInterpolant)(t::Real) = li.y_a + (t - 0) * (li.y_b - li.y_a) / (2500 - 0)

# Phase
@phase(dop, t)
@constraint(dop, initial(t) == 0)
@constraint(dop,   final(t) ≤  2500)
 
# States
@variable(dop,            0 ≤ h,               DefinedOn(t))
@variable(dop, deg2rad(-89) ≤ θ ≤ deg2rad(89), DefinedOn(t))
@variable(dop,             Φ,               DefinedOn(t))
@variable(dop,            1e-4 ≤ v,               DefinedOn(t))
@variable(dop, deg2rad(-89) ≤ γ ≤ deg2rad(89), DefinedOn(t))
@variable(dop,                ψ,               DefinedOn(t))
 
# Controls
@variable(dop, deg2rad(-90) ≤ α ≤ deg2rad(90), DefinedOn(t))
@variable(dop, deg2rad(-90) ≤ β ≤ deg2rad(1),  DefinedOn(t))
 
# Boundary conditions
@constraint(dop, initial(h) == 2.6e5)
@constraint(dop,   final(h) == 0.8e5)
@constraint(dop, initial(θ) == 0)
@constraint(dop, initial(Φ) == 0)
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
@constraint(dop, derivative(Φ) == v * cos(γ) * sin(ψ) / (r * cos(θ)))
@constraint(dop, derivative(v) == -D / m - g * sin(γ))
@constraint(dop, derivative(γ) == L * cos(β) / (m * v) + cos(γ) * (v / r - g / v))
@constraint(dop, derivative(ψ) == L * sin(β) / (m * v * cos(γ)) + v * cos(γ) * sin(ψ) * sin(θ) / (r * cos(θ)))
 
JuDO.warmstart!(dop, LinearInterpolant(2.6e5, 0.8e5), h)
JuDO.warmstart!(dop, LinearInterpolant(0.0, deg2rad(90)), θ)
JuDO.warmstart!(dop, LinearInterpolant(0.0, deg2rad(50)), Φ)
JuDO.warmstart!(dop, LinearInterpolant(25600.0, 2500.0), v)
JuDO.warmstart!(dop, LinearInterpolant(deg2rad(1), deg2rad(-5)), γ)
JuDO.warmstart!(dop, LinearInterpolant(deg2rad(90),deg2rad(20) ), ψ)

# Objective
@objective(dop, Max, final(θ))

JuDO.optimize!(dop)

h_sol = dyn_value(dop, h)
θ_sol = dyn_value(dop, θ)
Φ_sol = dyn_value(dop, Φ)
v_sol = dyn_value(dop, v)
γ_sol = dyn_value(dop, γ)
ψ_sol = dyn_value(dop, ψ)
α_sol = dyn_value(dop, α)
β_sol = dyn_value(dop, β)

# --- 2. Extract Final Time & Time Grid ---
tf = phase_final(t)
ts = collect(range(0, tf, length=500))

# --- 3. Define Plotting Configuration ---
# Format: (SolutionObject, Title, Y-Label, ScalingFunction, Filename)
plot_configs = [
    (h_sol, "Altitude", "Altitude (km)", y -> y/1000, "altitude.png"),
    (θ_sol, "Latitude", "Latitude (deg)", y -> rad2deg(y), "latitude.png"),
    (Φ_sol, "Longitude", "Longitude (deg)", y -> rad2deg(y), "longitude.png"),
    (v_sol, "Velocity", "Velocity (km/s)", y -> y/1000, "velocity.png"),
    (γ_sol, "Flight Path Angle", "Flight Path Angle (deg)", y -> rad2deg(y), "flight_path.png"),
    (ψ_sol, "Azimuth", "Azimuth (deg)", y -> rad2deg(y), "Azimuth.png"),
    (α_sol, "Angle of Attack", "Angle of Attack (deg)", y -> rad2deg(y), "alpha.png"),
    (β_sol, "Bank Angle", "Bank Angle (deg)", y -> rad2deg(y), "beta.png")
]
traj = plot(
    rad2deg.(Φ_sol.(ts)),
    rad2deg.(θ_sol.(ts)),
    h_sol.(ts)./1000;
    linewidth = 1,
    legend = nothing,
    xlabel = "Longitude (deg)",
    ylabel = "Latitude (deg)",
    zlabel = "Altitude (km)",
    lc = :black
)

savefig(traj,"3-d-trajectory.png")
# --- 4. Loop, Plot, and Save ---
for (sol, title_text, ylab, scale_fn, fname) in plot_configs
    # Create the plot
    p = plot(ts, t -> scale_fn(sol(t)), 
             legend = false,
             ylabel = ylab,
             xlabel = "Time (s)",
             lw     = 1,
             lc     = :black
    )
    
    # Save the figure
    savefig(p, fname)
end

open("latitude.txt", "w") do io
    println(io, "time,r_value")
    for (t, theta_val) in zip(ts, rad2deg.(θ_sol.(ts)))
        println(io, "$(t),$(theta_val)")
    end
end

open("longitude.txt", "w") do io
    println(io, "time,r_value")
    for (t, phi_val) in zip(ts, rad2deg.(Φ_sol.(ts)))
        println(io, "$(t),$(phi_val)")
    end
end

println("finished")