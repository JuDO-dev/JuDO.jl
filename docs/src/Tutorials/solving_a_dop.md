```@meta
CurrentModule = JuDO
```
# Solving Dynamic Optimization Problems

This tutorial demonstrates how to solve dynamic optimization problems using JuDO through two classic examples: the cart-pole swing-up problem and the space shuttle reentry trajectory problem.

---

## Cart-Pole Swing-Up Problem

The cart-pole swing-up is a classic control problem where a pendulum attached to a cart must be swung from a hanging position to an upright position by applying a horizontal force to the cart, while minimising the total control effort.

### Problem Formulation

**Parameters**

| Symbol | Value | Description |
|--------|-------|-------------|
| ``m_1`` | 1.0 kg | Cart mass |
| ``m_2`` | 0.3 kg | Pole mass |
| ``l``   | 0.5 m  | Pole half-length |
| ``g``   | 9.81 m/s² | Gravitational acceleration |
| ``u_{\max}`` | 20 N | Maximum control force |
| ``r_{\max}`` | 2 m  | Maximum cart displacement |

**States and controls**

| Variable | Description |
|----------|-------------|
| ``r(t)`` | Cart position (m) |
| ``\nu(t)`` | Cart velocity (m/s) |
| ``\theta(t)`` | Pole angle from downward vertical (rad) |
| ``\omega(t)`` | Pole angular velocity (rad/s) |
| ``u(t)`` | Horizontal force applied to cart (N) — *control* |

**Optimal control problem**

```math
\min_{u(\cdot)} \quad \int_0^{t_f} u(t)^2 \, \mathrm{d}t
```

subject to the equations of motion (derived via the Lagrangian):

```math
\dot{r} = \nu
```

```math
\dot{\nu} = \frac{l \, m_2 \sin\theta \cdot \omega^2 + u + m_2 g \cos\theta \sin\theta}{m_1 + m_2 \sin^2\theta}
```

```math
\dot{\theta} = \omega
```

```math
\dot{\omega} = \frac{-l \, m_2 \cos\theta \sin\theta \cdot \omega^2 - u \cos\theta - (m_1 + m_2) g \sin\theta}{l \left(m_1 + m_2 \sin^2\theta\right)}
```

with boundary conditions:

```math
r(0) = 0, \quad \nu(0) = 0, \quad \theta(0) = 0, \quad \omega(0) = 0
```

```math
r(t_f) = 1, \quad \nu(t_f) = 0, \quad \theta(t_f) = \pi, \quad \omega(t_f) = 0
```

and path constraints:

```math
-u_{\max} \leq u(t) \leq u_{\max}, \qquad 0 \leq r(t) \leq r_{\max}, \qquad t \in [0,\, t_f]
```

where ``t_f = 2`` s is the fixed final time.

The terminal condition ``\theta(t_f) = \pi`` corresponds to the pole pointing straight up.

### JuDO Implementation

```julia
using Interesso
using JuMP
using Plots
using JuDO  
using DynOptInterface

const g     = 9.81
const l     = 0.5
const m_1   = 1.0
const m_2   = 0.3
const t_0   = 0.0
const t_f   = 2.0
const u_max = 20.0
const r_max = 2.0

dop = DynModel(Interesso.Optimizer)

# Warm-start interpolant (linear guess between two endpoint values)
struct LinearInterpolant <: DynOptInterface.AbstractDynamicSolution
    y_a::Float64
    y_b::Float64
end
(li::LinearInterpolant)(t::Real) = li.y_a + (t - t_0) * (li.y_b - li.y_a) / (t_f - t_0)

# Independent variable (time)
@phase(dop, t)
@constraint(dop, initial(t) == 0)
@constraint(dop, final(t)   == 2)

# Control
@variable(dop, -u_max <= u <= u_max, DefinedOn(t))

# States
@variable(dop, 0 <= r <= r_max, DefinedOn(t))
@variable(dop, θ, DefinedOn(t))  
@variable(dop, ν, DefinedOn(t))
@variable(dop, ω, DefinedOn(t))

# Boundary conditions
@constraint(dop, initial(r) == 0)
@constraint(dop, initial(θ) == 0)
@constraint(dop, initial(ν) == 0)
@constraint(dop, initial(ω) == 0)

@constraint(dop, final(r) == 1)
@constraint(dop, final(θ) == pi)
@constraint(dop, final(ν) == 0)
@constraint(dop, final(ω) == 0)

# Equations of motion
@constraint(dop, derivative(r) == ν)
@constraint(dop, derivative(ν) == (l*m_2*sin(θ)*ω^2 + u + m_2*g*cos(θ)*sin(θ))/(m_1 + m_2*sin(θ)^2))
@constraint(dop, derivative(θ) == ω)
@constraint(dop, derivative(ω) == (-l*m_2*cos(θ)*sin(θ)*ω^2 - u*cos(θ) - (m_1 + m_2)*g*sin(θ))/(l*(m_1 + m_2*sin(θ)^2)))

# Objective: minimise control effort
@objective(dop, Min, integral(u^2))

# Warm-start with linear guesses
JuDO.warmstart!(dop, LinearInterpolant(0.0, 1.0), r)
JuDO.warmstart!(dop, LinearInterpolant(0.0, pi),  θ)

JuDO.optimize!(dop)

# Extract solutions
rsol     = dyn_value(dop, r)
thetasol = dyn_value(dop, θ)
nusol    = dyn_value(dop, ν)
omegasol = dyn_value(dop, ω)

time_points = collect(range(t_0, t_f, length=100))

# Plot angular velocity
p = plot(time_points, [omegasol(t) for t in time_points];
    xlabel = "Time (s)",
    ylabel = "Angular Velocity (rad/s)",
    legend = false,
    xlims  = (t_0, t_f),
    lw = 1, grid = true, lc = :black)
display(p)

# Plot pole angle
q = plot(time_points, [thetasol(t) for t in time_points];
    xlabel = "Time (s)",
    ylabel = "θ (rad)",
    legend = false,
    xlims  = (t_0, t_f),
    lw = 1, grid = true, lc = :black)
display(q)
```

---

## Space Shuttle Reentry Problem

This benchmark problem, due to Betts (2010), optimises the reentry trajectory of a space shuttle to **maximise the crossrange** (final latitude ``\theta(t_f)``), subject to the full six-state atmospheric flight dynamics and terminal boundary conditions.

### Problem Formulation

**Physical constants**

| Symbol | Value | Description |
|--------|-------|-------------|
| ``m``    | 203000/32.174 slug | Shuttle mass |
| ``S``    | 2690 ft²  | Reference area |
| ``R_e``  | 20902900 ft | Earth radius |
| ``\mu``  | 0.14076539 × 10¹⁷ ft³/s² | Gravitational parameter |
| ``\rho_0`` | 0.002378 slug/ft³ | Sea-level atmospheric density |
| ``h_r``  | 23800 ft  | Density scale height |

**Aerodynamic coefficients**

```math
C_L(\alpha) = a_0 + a_1 \alpha_{\deg}, \qquad C_D(\alpha) = b_0 + b_1 \alpha_{\deg} + b_2 \alpha_{\deg}^2
```

where ``\alpha_{\deg} = (180/\pi)\,\alpha`` and ``(a_0, a_1) = (-0.20704,\, 0.029244)``, ``(b_0, b_1, b_2) = (0.07854,\, -0.61592\times10^{-2},\, 0.621408\times10^{-3})``.

**States and controls**

| Variable | Description |
|----------|-------------|
| ``h(t)`` | Altitude (ft) |
| ``\theta(t)`` | Latitude (rad) |
| ``\Phi(t)`` | Longitude (rad) |
| ``v(t)`` | Velocity (ft/s) |
| ``\gamma(t)`` | Flight path angle (rad) |
| ``\psi(t)`` | Azimuth angle (rad) |
| ``\alpha(t)`` | Angle of attack (rad) — *control* |
| ``\beta(t)`` | Bank angle (rad) — *control* |

**Optimal control problem**

```math
\max_{\alpha(\cdot),\,\beta(\cdot)} \quad \theta(t_f)
```

subject to the three-degree-of-freedom flight dynamics over a spherical Earth:

```math
\dot{h} = v \sin\gamma
```

```math
\dot{\theta} = \frac{v \cos\gamma \cos\psi}{r}
```

```math
\dot{\Phi} = \frac{v \cos\gamma \sin\psi}{r \cos\theta}
```

```math
\dot{v} = -\frac{D}{m} - g\sin\gamma
```

```math
\dot{\gamma} = \frac{L\cos\beta}{mv} + \cos\gamma\!\left(\frac{v}{r} - \frac{g}{v}\right)
```

```math
\dot{\psi} = \frac{L\sin\beta}{mv\cos\gamma} + \frac{v\cos\gamma\sin\psi\tan\theta}{r}
```

where ``r = R_e + h``, ``g = \mu/r^2``, ``\rho = \rho_0 e^{-h/h_r}``, and:

```math
L = \tfrac{1}{2} S \rho v^2 C_L(\alpha), \qquad D = \tfrac{1}{2} S \rho v^2 C_D(\alpha)
```

**Boundary conditions**

```math
t_0 = 0\text{ s}, \quad t_f \leq 2500\text{ s}
```

```math
h(0) = 2.6\times10^5\text{ ft}, \quad \theta(0) = 0, \quad \Phi(0) = 0, \quad v(0) = 25600\text{ ft/s}
```

```math
\gamma(0) = -1°, \quad \psi(0) = 90°
```

```math
h(t_f) = 0.8\times10^5\text{ ft}, \quad v(t_f) = 2500\text{ ft/s}, \quad \gamma(t_f) = -5°
```

**Path constraints**

```math
-89° \leq \theta(t) \leq 89°, \quad -89° \leq \gamma(t) \leq 89°
```

```math
-90° \leq \alpha(t) \leq 90°, \quad -90° \leq \beta(t) \leq 1°
```

The reference solution (Betts, 2010) achieves a maximum crossrange of approximately **34.14°**.

### JuDO Implementation

```julia
using Interesso, JuMP, JuDO, DynOptInterface
using Plots

dop = DynModel(Interesso.Optimizer)

# Physical constants
const m               = 203000 / 32.174
const ρ_0, h_r, R_e  = 0.002378, 23800.0, 20902900.0
const μ               = 0.14076539e17
const a_0, a_1        = -0.20704, 0.029244
const b_0, b_1, b_2   = 0.07854, -0.61592e-2, 0.621408e-3
const S               = 2690

# Warm-start interpolant
struct LinearInterpolant <: DynOptInterface.AbstractDynamicSolution
    y_a::Float64
    y_b::Float64
end
(li::LinearInterpolant)(t::Real) = li.y_a + t * (li.y_b - li.y_a) / 2500

# Independent variable (time)
@phase(dop, t)
@constraint(dop, initial(t) == 0)
@constraint(dop,   final(t) ≤ 2500)

# States
@variable(dop,            0 ≤ h,               DefinedOn(t))
@variable(dop, deg2rad(-89) ≤ θ ≤ deg2rad(89), DefinedOn(t))
@variable(dop,             Φ,                  DefinedOn(t))
@variable(dop,          1e-4 ≤ v,              DefinedOn(t))
@variable(dop, deg2rad(-89) ≤ γ ≤ deg2rad(89), DefinedOn(t))
@variable(dop,             ψ,                  DefinedOn(t))

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
@constraint(dop, initial(γ) == deg2rad(-1))
@constraint(dop,   final(γ) == deg2rad(-5))
@constraint(dop, initial(ψ) == deg2rad(90))

# Intermediate expressions
@expression(dop, r,     R_e + h)
@expression(dop, g,     μ / r^2)
@expression(dop, ρ,     ρ_0 * exp(-h / h_r))
@expression(dop, α_deg, (180 / pi) * α)
@expression(dop, L,     0.5 * S * ρ * v^2 * (a_0 + a_1 * α_deg))
@expression(dop, D,     0.5 * S * ρ * v^2 * (b_0 + b_1 * α_deg + b_2 * α_deg^2))

# Equations of motion
@constraint(dop, derivative(h) == v * sin(γ))
@constraint(dop, derivative(θ) == v * cos(γ) * cos(ψ) / r)
@constraint(dop, derivative(Φ) == v * cos(γ) * sin(ψ) / (r * cos(θ)))
@constraint(dop, derivative(v) == -D / m - g * sin(γ))
@constraint(dop, derivative(γ) == L * cos(β) / (m * v) + cos(γ) * (v / r - g / v))
@constraint(dop, derivative(ψ) == L * sin(β) / (m * v * cos(γ)) + v * cos(γ) * sin(ψ) * sin(θ) / (r * cos(θ)))

# Warm-start with linear guesses
JuDO.warmstart!(dop, LinearInterpolant(2.6e5,      0.8e5),          h)
JuDO.warmstart!(dop, LinearInterpolant(0.0,        deg2rad(45)),    θ)
JuDO.warmstart!(dop, LinearInterpolant(0.0,        deg2rad(50)),    Φ)
JuDO.warmstart!(dop, LinearInterpolant(25600.0,    2500.0),         v)
JuDO.warmstart!(dop, LinearInterpolant(deg2rad(-1),deg2rad(-5)),    γ)
JuDO.warmstart!(dop, LinearInterpolant(deg2rad(90),deg2rad(-20)),   ψ)

# Objective: maximise crossrange (final latitude)
@objective(dop, Max, final(θ))

JuDO.optimize!(dop)

# Extract solutions
h_sol = dyn_value(dop, h)
θ_sol = dyn_value(dop, θ)
Φ_sol = dyn_value(dop, Φ)
v_sol = dyn_value(dop, v)
γ_sol = dyn_value(dop, γ)
ψ_sol = dyn_value(dop, ψ)
α_sol = dyn_value(dop, α)
β_sol = dyn_value(dop, β)

tf = phase_final(t)
ts = collect(range(0, tf, length=500))

# 3-D trajectory plot
traj = plot(
    rad2deg.(Φ_sol.(ts)),
    rad2deg.(θ_sol.(ts)),
    h_sol.(ts) ./ 1000;
    linewidth = 1,
    legend    = nothing,
    xlabel    = "Longitude (deg)",
    ylabel    = "Latitude (deg)",
    zlabel    = "Altitude (km)",
    lc        = :black,
)
display(traj)

# Individual state/control plots
plot_configs = [
    (h_sol, "Altitude (km)",            y -> y/1000),
    (θ_sol, "Latitude (deg)",           y -> rad2deg(y)),
    (Φ_sol, "Longitude (deg)",          y -> rad2deg(y)),
    (v_sol, "Velocity (km/s)",          y -> y/1000),
    (γ_sol, "Flight Path Angle (deg)",  y -> rad2deg(y)),
    (ψ_sol, "Azimuth (deg)",            y -> rad2deg(y)),
    (α_sol, "Angle of Attack (deg)",    y -> rad2deg(y)),
    (β_sol, "Bank Angle (deg)",         y -> rad2deg(y)),
]

for (sol, ylab, scale_fn) in plot_configs
    p = plot(ts, t -> scale_fn(sol(t));
             legend = false, ylabel = ylab, xlabel = "Time (s)",
             lw = 1, lc = :black)
    display(p)
end
```
