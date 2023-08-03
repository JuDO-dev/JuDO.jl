
"""
@differential(model, args...)

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

 @differential(_model,x(t))

 @differential(_model,x(t),Initial_guess = 8)

 @differential(_model,x(t),Initial_guess = 8,0 <= Initial_bound <= 10)

 @differential(_model,x(t),0 <= Initial_bound <= 10,Initial_guess = 8)

 @differential(_model,x(t),Initial_guess = 8,Final_bound >= 100)

 @differential(_model,x(t),Interpolant = L,Initial_guess = 8,Final_bound >= 100)
"""

macro differential(model,args...)
    expr_of_args = collect(args)
    if expr_of_args[1].head == :ref
        len = check_vector_input(expr_of_args[1])
        result = []
    
        if length(expr_of_args) == 1
            for i in 1:len
                result = :(assign_vector($(esc(model)),$i,$expr_of_args,$result))
            end
            return macro_return(args[1].args[1].args[1],result) 
        else
            for i in 1:len
                result = :(assign_vector($(esc(model)),$i,$expr_of_args,$result,true))
            end
            return macro_return(args[1].args[1].args[1],result) 
        end
    end
    
    if length(expr_of_args) == 1 

        var_ref = :(add_new($(esc(model)),$expr_of_args))
        return macro_return(expr_of_args[1].args[1],var_ref)
    else

        var_ref = :(add_new($(esc(model)),$expr_of_args,true))
        return macro_return(expr_of_args[1].args[1],var_ref)
    end
end

function macro_return(sym,ref)
    return quote $(esc(sym)) = $ref end
end

"""
    @independent(model, args)

    The continuous independent variable in the problem (time is used in the following documentation)
    
    If the bound is not provided, then a free-time problem is assumed.

    Only one independent variable is allowed in a problem.
    
    @independent( model, t) 

    @independent( model, 0 <= t <= 10)

    @independent( model, t >= 0)

    @independent( model, 0 <= t)

    @independent( model, t <= 10)

    If keyword "initial" or "final" is provided, then the independent variable is fixed at the initial or final time

    @independent( model, t0, type = initial)

    @independent( model, tₚ, type = final)

    @independent( model, t0 = 0, type = initial)

    @independent( model, tₚ = 10, type = final)
"""

macro independent(model, args...)
    expr_of_args = collect(args)
    # separate the situation of initial/final value and trajectory bound
    if length(expr_of_args) == 1
        var_ref = :(add_independent($(esc(model)),$(expr_of_args)))
        sym,val = check_inde_var_input(args[1])   
        return macro_return(sym,var_ref)

    elseif length(expr_of_args) == 2
        var_ref = :(add_independent($(esc(model)),$([expr_of_args[1]]),$([expr_of_args[2]])))
        (args[1]) isa Expr ? (sym = args[1].args[1]) : (sym = args[1])  
        return macro_return(sym,var_ref)

    else
        throw(error("Incorrect input style"))
    end

end

"""
    algebraic(model, args...)

    The algebraic variable is an abstract quantity that can vary, often represents the control input.

    The algebraic variable can only be continuous.

    The user is required to put a model in the first argument, an expression (or symbol) in the second argument.

    @algebraic( model, u(t))

    @algebraic( model, 0 <= u(t) <= 10)

    @algebraic( model, -10 <= v(t) <= 10)

    @algebraic( model, 10 <= w(t))

"""

macro algebraic(model,args...)

    c_args = collect(args) 
    
    name,val = check_alge_var_input(c_args[1])

    if name.head == :ref
        len = check_vector_input(name)
        result = []
       
        for i in 1:len
            result = :(assign_alge_vector($(esc(model)),$i,$c_args,$result,$val))
        end
        return macro_return(name.args[1].args[1],result) 
        
    end

    #if the user is not providing any info, then add default info
    if (c_args[1] isa Expr) && (length(c_args[1].args) == 2)
        var_ref = :(add_new_algebraic($(esc(model)),$c_args,[-Inf,Inf]))
        return macro_return(c_args[1].args[1],var_ref)
    elseif (c_args[1] isa Expr) 
        var_ref = :(new_info_algebraic($(esc(model)),$c_args))
        sym,val = check_alge_var_input(c_args[1])
        return macro_return(sym.args[1],var_ref)
    else
        throw(error("Incorrect input style"))
    end
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

    const_ref = :(new_or_exist_constant($(esc(model)),$c_args))

    return macro_return(c_args[1].args[1],const_ref)
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

"""
    @dynamic_func(model, args...)

    This macro is used to add a dynamic function into the model.

    The user is required to put an expression as the argument.

    The dynamic function is considered as a minimization problem, so for maximization problem, 
    the user is required to add a negative sign in front of the expression.

    The dynamic function can only be added once in the model, it can only contain the registered variables and constants.

    @dynamic_func( model, x(t) + u(t) + v(t) + g)
"""

macro dynamic_func(model,args...)
    c_args = collect(args)

    return :(parse_objective_function($(esc(model)),$c_args))
end

