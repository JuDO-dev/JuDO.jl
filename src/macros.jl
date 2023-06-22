
function new_or_exist(_model,_sym,_args)
    haskey(_model.Differential_var_index,_sym[1]) ? (return add_exist(_model,_sym[1],_args)) : (return add_new(_model,_sym[1],_args))
end

function new_or_exist_independent(_model,_args)
    haskey(_model.Independent_var_index,_args[2]) ? (return add_exist_independent(_model,_args)) : (return add_new_independent(_model,_args))
end

function new_or_exist_algebraic(_model,_sym,_args,_is_discrete=false)
    haskey(_model.Algebraic_var_index,_sym[1]) ? (return add_exist_algebraic(_model,_sym[1],_args,_is_discrete)) : (return add_new_algebraic(_model,_sym[1],_args,_is_discrete))
end

"""
@differential_variable(model, args...)

Add a dynamic variable into the dynamic model.
The user is required to put the dynamic model and the variable symbol in the first two positions, the rest are optional keyword arguments.

## args

keyword arguments can contain:
    The initial guess of the variable, x₀
    The bound of initial value, [lb₀,ub₀]
    The bound of the final value, [lb₁,ub₁]
    The bound of the variable during run-time, [lb,ub]
    The interpolant, L

 julia> JuDO.@differential_variable(_model,x₀)

 julia> JuDO.@differential_variable(_model,x₀,Initial_guess=8)

 julia> JuDO.@differential_variable(_model,x₀,Initial_guess=8,Initial_bound=[0,10])

 julia> JuDO.@differential_variable(_model,x₀,Initial_bound=[0,10],Initial_guess=8)

 julia> JuDO.@differential_variable(_model,x₀,initial_guess=8,final_bound=[0,100])

 julia> JuDO.@differential_variable(_model,x₀,interpolant=L,initial_guess=8,final_bound=[0,100],)
"""

macro differential_variable(model,args...)
    
    args[1] isa Symbol ? nothing : symbol_error()

    if length(args) == 1 
        empty_info = [nothing,[-Inf,Inf],[-Inf,Inf],[-Inf,Inf],nothing,args[1]]
        #println("Creating a differential variable with default values:")
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
    
    input_argument_error(collect(args))
    
    # the user is not providing the bound, so a free-time problem is assumed
    if collect(args)[1] isa Symbol
        parsed_args = [Expr(:call,:in,:($(collect(args)[1])),:([-Inf,Inf]))]
        return :(add_exist_independent($(esc(model)),$(parsed_args[1].args)))
    end

    parsed_args = collect(args)[1].args
    bound_lower_upper(eval(parsed_args[3]))

    return :(new_or_exist_independent($(esc(model)),$parsed_args))        

end

"""
    algebraic_variable(model, args...)

    The algebraic variable is an abstract quantity that can vary, often represents the control input.

    The algebraic variable can be either continuous or discrete, the default is continuous.

    The user is required to put a model in the first argument, an expression (or symbol) in the second argument,
    and the "discrete = false/true" is optional, for user to remind his/herself the type of algebraic variable, since
    "in" is used for continuous algebraic variable, and "=" is used for discrete algebraic variable.

    @algebraic_variable( model, u)

    @algebraic_variable( model, u in [0,10])

    @algebraic_variable( model, v in [-10,10])

    @algebraic_variable( model, v in [-10,10], discrete = false)
    @algebraic_variable( model, v in [-10,10], discrete = true) is not allowed

    @algebraic_variable( model, u = [-1,1], discrete = true)
    @algebraic_variable( model, u = [-1,1]) is not allowed, since the default is continuous

"""

macro algebraic_variable(model,args...)

    c_args = collect(args)

    kw,val,is_discrete = cont_or_dis(c_args)

    is_discrete ? (return :(new_or_exist_algebraic($(esc(model)),$([kw]),$val,$is_discrete))) : (return :(new_or_exist_algebraic($(esc(model)),$([kw]),$val)))

end
