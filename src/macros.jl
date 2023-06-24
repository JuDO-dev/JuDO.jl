
function new_or_exist(_model,_sym,_args)
    haskey(_model.Differential_var_index,_sym[1]) ? (return add_exist(_model,_sym[1],_args)) : (return add_new(_model,_sym[1],_args))
end

function new_or_exist_independent(_model,_args)
    haskey(_model.Independent_var_index,_args[2]) ? (return add_exist_independent(_model,_args)) : (return add_new_independent(_model,_args))
end

function new_or_exist_algebraic(_model,_sym,_args)
    haskey(_model.Algebraic_var_index,_sym[1]) ? (return add_exist_algebraic(_model,_sym[1],_args)) : (return add_new_algebraic(_model,_sym[1],_args))
end

"""
@differential_variable(model, args...)

Add a dynamic variable into the dynamic model.
The user is required to put the dynamic model and the variable symbol in the first two positions, the rest are optional keyword arguments.
Expressions of bounds should be put in the form of "keyword in [lb,ub]".
Initial guess and interpolant should be put in the form of "keyword = value".

## args

keyword arguments can contain:
    The initial guess of the variable, x₀
    The bound of initial value, [lb₀,ub₀]
    The bound of the final value, [lb₁,ub₁]
    The bound of the variable during run-time, [lb,ub]
    The interpolant, L

 @differential_variable(_model,x)

 @differential_variable(_model,x,Initial_guess=8)

 @differential_variable(_model,x,Initial_guess=8,Initial_bound in [0,10])

 @differential_variable(_model,x,Initial_bound in [0,10],Initial_guess=8)

 @differential_variable(_model,x,Initial_guess=8,Final_bound in [0,100])

 @differential_variable(_model,x,Interpolant=L,Initial_guess=8,Final_bound in [0,100])
"""

macro differential_variable(model,args...)
    
    collect(args)[1] isa Symbol ? nothing : symbol_error()

    if length(args) == 1 
        empty_info = [args[1],nothing,[-Inf,Inf],[-Inf,Inf],[-Inf,Inf],nothing]
        return :(add_new($(esc(model)),$empty_info)) 
    end
    
    expr_of_args = collect(args)[2:end]

    return :(new_or_exist($(esc(model)),$([args[1]]),$expr_of_args))

end
 

"""
    @independent_variable(model, args)

    The continuous independent variable in the problem (time is used in the following documentation)
    
    If the bound is not provided, then a free-time problem is assumed.
    
    @independent_variable( model, t) 

    @independent_variable( model, t in [0,10])

    @independent_variable( model, t in [0,Inf])

    @independent_variable( model, t in [-Inf,10])
"""

macro independent_variable(model, args...)
    
    # the user is not providing the bound, so a free-time problem is assumed
    if collect(args)[1] isa Symbol
        empty_info = [Expr(:call,:in,:($(collect(args)[1])),:([-Inf,Inf]))]
        return :(add_exist_independent($(esc(model)),$(empty_info[1].args)))
    end

    parsed_args = collect(args)[1].args

    return :(new_or_exist_independent($(esc(model)),$parsed_args))        

end

"""
    algebraic_variable(model, args...)

    The algebraic variable is an abstract quantity that can vary, often represents the control input.

    The algebraic variable can be either continuous or discrete, the default is continuous.

    The user is required to put a model in the first argument, an expression (or symbol) in the second argument,
    "in" is used for uncountable algebraic variable, algebraic variable with finite set is not supported.

    @algebraic_variable( model, u)

    @algebraic_variable( model, u in [0,10])

    @algebraic_variable( model, v in [-10,10])

    granular
"""

macro algebraic_variable(model,args...)

    c_args = collect(args)

    #if the user is not providing any info, then add default info
    if c_args[1] isa Symbol
        empty_info = [c_args[1],:([-Inf,Inf])]
        return :(add_new_algebraic($(esc(model)),$(empty_info)))
    end 

    return :(new_or_exist_algebraic($(esc(model)),$([c_args[1].args[2]]),$(c_args[1].args[3])))

end
