
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
    @constraint(model, name, args...)

    This macro is used to add one constraint (scalar or vector) into the model.

    The user is required to put a dynamic model "model" as the first argument.
        
    "args..." contains a name (symbol) for the constraint in its first element, the second element is the constraint function, 
    the third element it can be "trajectory", "initial", "final" or "all". 

    The equation must use "==", "<=", or ">=" and each terms in the equation must contain either 
    a registered variable or constant, or a number.

    In the constraint function, the user is required to add ("name of the independent variable") like ẋ(t), u(t), A(t)
    to indicate the dependency with respected to the independent variable.
    
    When performing multiplication or division, the user is required to use "*" or "/" to separate the terms when two adjacent
    brackets or two adjacent symbols are present. For example, A(t)*(a*x(t)-1) is valid, but A(t)(a*x(t)-1) is not valid,
    A(t)x(t) is valid, but Ax(t) is not valid.

    Still, the user is encouraged to use "*" or "/" to describe the function whenever possible for minimizing the chance of error.

    Depending on the input function and set detected, the macro will call the corresponding DOI function to add the constraint,
    the detail is shown in DynOptInterface Readme.

            Function (subtypes):              Sets:                             Example:
            LinearDifferentialFunction        NonpositiveForAll:                @constraint( model, c1, a*x(t) <= 0, trajectory)
 
            LinearDifferentialFunction        NonnegativeForAll:                @constraint( model, c2, ẋ(t) - y(t) + p >= 0, trajectory)

            LinearDifferentialFunction        ZeroForAll:                       @constraint( model, c3, ẋ(t) - sin(t) == 0, trajectory)
            
            VectorLinearDifferentialFunction, NonpositiveForAll:                @constraint( model, c4, B(t)*ẋ(t) - A(t)*x(t) <= 0, trajectory)

            LinearAlgebraicFunction,          NonnegativeForAll:                @constraint( model, c5, u(t) - d/2 >= 0, trajectory)

            LinearDifferentialAlgebraicFunction, ZeroForAll:                    @constraint( model, c6, u(t) - x(t)*d == 0, trajectory)

            LinearDifferentialAlgebraicFunction, EqualToInitial:                @constraint( model, c7, u(t0) - x(t0)*d - 1 == 0, initial)
            ...

"""
macro constraint(model,args...)
    
    c_args = collect(args)

    return :(parse_equation($(esc(model)),$c_args))

end
