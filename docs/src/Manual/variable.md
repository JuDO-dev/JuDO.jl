# Dynamic Variable

In dynamic optimization, dynamic variables represent states and inputs that change over a domain.

## How it Differs from JuMP

Standard JuMP variables are single scalar values. But JuDO variables are continuous trajectories. They evolve over a specific Phase. 

JuDO separates the lower bound and upper bound at the start, end and during the trajectory. It links this variable to the phase index. Then it registers the variable with the DynOptInterface backend. 


## Creating a Dynamic Variable

You define a dynamic variable using the standard `@variable` macro. But you must use the `DefinedOn` syntax. This tells the model which phase the variable belongs to.

### Option 1: Unbounded Variable

You can create a variable without any bounds.

```julia
# Creates a variable 'x' defined on phase 't'
@variable(model, x, DefinedOn(t))
```

### Option 2: Bounded Variable

You can define bounds directly in the macro. 
```julia
# Creates a variable 'h' with a lower bound of 0
@variable(model, 0 <= h, DefinedOn(t))

# Creates a variable 'v' with an upper bound of 100
@variable(model, v <= 100, DefinedOn(t))

# Creates a variable 'u' with both lower and upper bounds
@variable(model, -10 <= u <= 10, DefinedOn(t))
```

## API Reference

Use `DefinedOn(t)` to associate a variable with a phase. Internal types:
`DynamicVar`, `DynamicVarRef`, `DynamicAffExpr`, `DynamicQuadExpr`.