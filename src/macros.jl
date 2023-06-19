symbol_error() = throw(error("A symbol is expected for the second argument"))
_bound_error() = throw(error("Initial/Final bound not in the total bound"))
input_style_error() = throw(error("Keyword argument input style incorrect, make sure all arguments are in the form of keyword = value"))

function var_not_inside_error(_val,_bound)  
    _val >= _bound[1] && _val <= _bound[2] ? nothing : throw(error("The initial/final value is not inside the initial/final bound"))
end

function bound_not_inside_error(_initial_bound,_final_bound,_total_bound)
    _initial_bound[1] >= _total_bound[1] && _initial_bound[2] <= _total_bound[2] ? nothing : throw(error("Initial bound is not inside the trajectory bound"))
    _final_bound[1] >= _total_bound[1] && _final_bound[2] <= _total_bound[2] ? nothing : throw(error("Final bound is not inside the trajectory bound"))
end
    

function output_macro(m,diff_var_data)
     
    #m.Differential_var_index = Dict{Symbol,Differential_Var_data}([(diff_var_data.Run_sym,diff_var_data)])
    #m.independent_var_index = Dict{Symbol,Independent_Var_data}()
    
    return m

end 

function identify_kw(raw_expr)
    # raw_expr is the raw expression of the macro, with type vector.

    kw_collection = [:initial_val,:final_val,:initial_bound,:final_bound,:trajectory_bound,:interpolant]
    default_info = [nothing, nothing, [-Inf,Inf], [-Inf,Inf],[-Inf,Inf],nothing]

    kws = filter(x -> x isa Expr && x.head == :(=) && x.args[1] in kw_collection, raw_expr)

    length(kws) == length(raw_expr) ? nothing : throw(input_style_error())

    #return the indices of keywords in kw_collection
    key_matches=[]
    for i in eachindex(kws)
        push!(key_matches,findfirst(isequal(kws[i].args[1]),kw_collection))
    end

    full_info=[]
    for i in 1:6
        i in key_matches ? push!(full_info,kws[findfirst(isequal(i),key_matches)].args[2]) : push!(full_info,default_info[i])

        #evaluate the expression apart from the interpolant
        i == 6 ? nothing : full_info[i] = eval(full_info[i]) 
    end
   
    # check for the potential errors in the input bounds
    full_info[1] == nothing ? nothing : var_not_inside_error(full_info[1],full_info[3])
    full_info[2] == nothing ? nothing : var_not_inside_error(full_info[2],full_info[4])
    #bound_not_inside_error(full_info[3],full_info[4],full_info[5])
    
    return full_info

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

 # to do: add the input type @differential_variable( model, x₀=0, x₁==10,...)
# keyword/arguments/ to allow a freedom of input order
# create a test file 

 A model and a symbol must be provided in a specified sequence, the rest are optional keywords, can be in any sequence.

 julia> JuDO.@differential_variable(_model,x₀)

 julia> JuDO.@differential_variable(_model,x₀,initial_val=8)

 julia> JuDO.@differential_variable(_model,x₀,initial_val=8,final_val=90)

 julia> JuDO.@differential_variable(_model,x₀,final_val=90,initial_val=8)

 julia> JuDO.@differential_variable(_model,x₀,final_val=90,initial_val=8,final_bound=[0,100])

 julia> JuDO.@differential_variable(_model,x₀,final_val=90,initial_val=8,final_bound=[0,100],interpolant=L)
"""

macro differential_variable(_model,args...)
    
    expr_of_model = quote $(esc(_model)) end
    _model = expr_of_model.args[2].args[1]

    args[1] isa Symbol ? nothing : symbol_error()

    if length(args) == 1 
        empty_info = [nothing,nothing,[-Inf,Inf],[-Inf,Inf],[-Inf,Inf],nothing]
        return construct_differential_variable(args[1],empty_info) 
    end
    expr_of_args = collect(args)[2:end]

    var_info = identify_kw(expr_of_args)

    return construct_differential_variable(args[1],var_info)    
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
 

macro independent_variable(_model, args...)
    
    expr_of_args = collect(args)[1]
    
    if length(args) == 0
        return construct_independent_variable(nothing,[-Inf,Inf])
    elseif length(args) > 1
        throw(error("Only one independent variable is allowed"))
    else
        expr_of_args isa Symbol ? (return construct_independent_variable(expr_of_args,[-Inf,Inf])) : nothing
        
        t_bound = eval(expr_of_args.args[3])
        t_bound[1] < t_bound[2] ? nothing : throw(error("Initial value $(t_bound[1]) greater than final value $(t_bound[2])!"))

        return construct_independent_variable(expr_of_args.args[2],t_bound)
    end

end






