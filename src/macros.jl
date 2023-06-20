
function new_or_exist(_model,_sym,_args)
    haskey(_model.Differential_var_index,_sym[1]) ? (return add_exist(_model,_sym[1],_args)) : (return add_new(_model,_sym[1],_args))

end

function new_or_exist_independent(_model,_args)
    haskey(_model.Independent_var_index,_args[2]) ? (return add_exist_independent(_model,_args)) : (return add_new_independent(_model,_args))
end

"""
@differential_variable(model, args...)

Add a dynamic variable into the dynamic model.

## args

arguments can contain:
    The dynamic model 
    The initial value x₀ 
    The bound of x₀, [lb₀,ub₀]
    The bound of the final value x₁, [lb₁,ub₁]
    The range of x during run-time, [lb,ub]
    The interpolant, L

 A model and a symbol must be provided in a specified sequence, the rest are optional keywords, can be in any sequence.

 julia> JuDO.@differential_variable(_model,x₀)

 julia> JuDO.@differential_variable(_model,x₀,initial_val=8)

 julia> JuDO.@differential_variable(_model,x₀,initial_val=8,final_val=90)

 julia> JuDO.@differential_variable(_model,x₀,final_val=90,initial_val=8)

 julia> JuDO.@differential_variable(_model,x₀,final_val=90,initial_val=8,final_bound=[0,100])

 julia> JuDO.@differential_variable(_model,x₀,final_val=90,initial_val=8,final_bound=[0,100],interpolant=L)
"""

macro differential_variable(model,args...)
    
    args[1] isa Symbol ? nothing : symbol_error()

    if length(args) == 1 
        empty_info = [nothing,nothing,[-Inf,Inf],[-Inf,Inf],[-Inf,Inf],nothing,args[1]]
        #println("Creating a differential variable with default values:")
        return :(add_new($(esc(model)),$empty_info)) 
    end
    
    expr_of_args = collect(args)[2:end]

    return :(new_or_exist($(esc(model)),$([args[1]]),$expr_of_args)) 

end
 

"""
    @independent_variable(model, args)

    The final value or range of the independent variable (time is used in the following documentation)
    
    If the bound is not provided, then a free-time problem is assumed.
    
    @independent_variable( model, t) 

    @independent_variable( model, t in [0,10])

    @independent_variable( model, t in [0,Inf])

    @independent_variable( model, t in [-Inf,10])
"""
 

macro independent_variable(model, args...)
    
    if length(args) == 0
        symbol_error()
    elseif length(args) > 1
        multiple_independent_var_error()
    else
        # the user is not providing the bound, so a free-time problem is assumed
        if collect(args)[1] isa Symbol
            parsed_args = [Expr(:call,:in,:($(collect(args)[1])),:([-Inf,Inf]))]
            return :(add_exist_independent($(esc(model)),$(parsed_args[1].args)))
        end

        parsed_args = collect(args)[1].args
        bound_lower_upper(eval(parsed_args[3]))
 
        return :(new_or_exist_independent($(esc(model)),$parsed_args))
        
    end

end






