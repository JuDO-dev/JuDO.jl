
"""
    dynamic_variable(model, var, phase)

    Add a dynamic variable into the dynamic model, it can be differential or algebraic.

    The user is required to put the dynamic model in the first position,
    then the expression of the variable, the third argument should be an existing phase.

    Expressions of bounds should be put in the form of "keyword <= / >= value", "value <= / >= keyword", or "value <= keyword <= value".
    Initial guess and interpolant should be put in the form of "keyword = value".

    The vectorized input only supports defining differential variables with the same information, use set to modify the individual fields.

    ## args

    keyword arguments can contain:
        The Initial_value, x₀
        The Initial_bound, [lb₀,ub₀]
        The Final_value, xₑ
        The Final_bound, [lb₁,ub₁]
        The Trajectory_bound, [lb,ub]

"""
macro dynamic_variable(model,args...)

    c_args = collect(args) 

    if length(c_args) != 2
        throw(error("Incorrect number of arguments"))
    end

    # #if the user is not providing any info, then add default info
    if c_args[1] isa Symbol
        var_ref = :(add_new_dvar($(esc(model)),$c_args,[-Inf,Inf]))
        return var_ref#macro_return(c_args[1].args[1],var_ref)

    #if the bound of the variable is also given, then ensure that the variable is at the lhs, or at the middle
    #then possibly simplify the pure numeric side of the expression

    #when the 
    elseif c_args[1] isa Expr
        
        if length(c_args[1].args) == 5

            bound = [c_args[1].args[1],c_args[1].args[5]]
            
            data = :(add_new_dvar($(esc(model)),$c_args,bound))

        end

    else
        throw(error("Incorrect input style"))
    end

end

"""
    @phase(model, args)

    The continuous independent variable in the problem (time is used in the following documentation)
    
    If the bound is not provided, then a free-time problem is assumed.

    Only one independent variable for each type is allowed in a problem.

"""

macro phase(model, args...)
    expr_of_args = collect(args)
    
    if length(expr_of_args) == 1
        data = :(add_independent($(esc(model)),$(expr_of_args)))
        return macro_return(expr_of_args[1],data)

    else
        #the argument should be a single variable for now
        throw(error("Incorrect input style"))
    end

end

function macro_return(sym,ref)
    return :($(esc(sym)) = $ref;)
end