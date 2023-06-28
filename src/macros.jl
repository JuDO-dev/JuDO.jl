
"""
@differential_variable(model, args...)

Add a dynamic variable into the dynamic model.
The user is required to put the dynamic model and the variable symbol in the first two positions, the rest are optional keyword arguments.
Expressions of bounds should be put in the form of "keyword <= / >= value", "value <= / >= keyword", or "value <= keyword <= value".
Initial guess and interpolant should be put in the form of "keyword = value".

## args

keyword arguments can contain:
    The Initial_guess, x₀
    The Initial_bound, [lb₀,ub₀]
    The Final_bound, [lb₁,ub₁]
    The Trajectory_bound, [lb,ub]
    The Interpolant, L

 @differential_variable(_model,x)

 @differential_variable(_model,x,Initial_guess = 8)

 @differential_variable(_model,x,Initial_guess = 8,0 <= Initial_bound <= 10)

 @differential_variable(_model,x,0 <= Initial_bound <= 10,Initial_guess = 8)

 @differential_variable(_model,x,Initial_guess = 8,Final_bound >= 100)

 @differential_variable(_model,x,Interpolant = L,Initial_guess = 8,Final_bound >= 100)
"""

macro differential_variable(model,args...)
    
    collect(args)[1] isa Symbol ? nothing : symbol_error()

    if length(args) == 1 
        empty_info = [args[1],nothing,[[-Inf,Inf]],[[-Inf,Inf]],[[-Inf,Inf]],nothing]
        return :(add_new($(esc(model)),$empty_info)) 
    end
    
    expr_of_args = collect(args)[2:end]

    return :(new_or_exist($(esc(model)),$([args[1]]),$expr_of_args))

end
 

"""
    @independent_variable(model, args)

    The continuous independent variable in the problem (time is used in the following documentation)
    
    If the bound is not provided, then a free-time problem is assumed.

    Only one independent variable is allowed in a problem.
    
    @independent_variable( model, t) 

    @independent_variable( model, 0 <= t <= 10)

    @independent_variable( model, t >= 0)

    @independent_variable( model, 0 <= t)

    @independent_variable( model, t <= 10)
"""

macro independent_variable(model, args...)
    
    # the user is not providing the bound, so a free-time problem is assumed
    if collect(args)[1] isa Symbol
        return :(add_new_independent($(esc(model)),$[args[1],[-Inf,Inf]]))
    end

    expr_of_args = collect(args)

    return :(new_or_exist_independent($(esc(model)),$expr_of_args))        

end

"""
    algebraic_variable(model, args...)

    The algebraic variable is an abstract quantity that can vary, often represents the control input.

    The algebraic variable can only be continuous.

    The user is required to put a model in the first argument, an expression (or symbol) in the second argument.

    @algebraic_variable( model, u)

    @algebraic_variable( model, 0 <= u <= 10)

    @algebraic_variable( model, -10 <= v <= 10)

    @algebraic_variable( model, 10 <= w)

"""

macro algebraic_variable(model,args...)

    c_args = collect(args)

    #if the user is not providing any info, then add default info
    if c_args[1] isa Symbol
        return :(add_new_algebraic($(esc(model)),$[c_args[1],[-Inf,Inf]]))
    end 

    return :(new_or_exist_algebraic($(esc(model)),$c_args))

end

"""
    @constant(model, args...)

    This macro is used to add a constant into the model to simplify future macro calls by using the constant symbol.

    The user is required to put a model in the first argument, an equality equation in the second argument.

    @constant( model, g = 9.81)

    @constant( model, k = 0.0069)

    @constant( model, P = 1.01e5)
"""

macro constant(model,args...)

    c_args = collect(args)

    return :(new_or_exist_constant($(esc(model)),$c_args))

end

"""
    @differential_equation(model, args...)

    This macro is used to add a differential equation into the model.

    The user is required to put a model in the first argument, an equality equation in the second argument.

    @differential_equation( model, ẋ = v)

    @differential_equation( model, v̇ = -g - k*v^2/m + u/m)

    @differential_equation( model, v̇ = -g - k*v^2/m + u/m, 0 <= v <= 10)

    @differential_equation( model, v̇ = -g - k*v^2/m + u/m, -10 <= v <= 10)

    @differential_equation( model, v̇ = -g - k*v^2/m + u/m, -10 <= v)

    @differential_equation( model, v̇ = -g - k*v^2/m + u/m, v <= 10)
"""
    