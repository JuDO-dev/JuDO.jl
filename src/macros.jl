
function parse_args(args)
    # parse arguments with =, initial value or final time 
    arg_list = collect(args)
    args_with_eq = filter(x -> isexpr(x, :(=)), arg_list)

    if length(args_with_eq) != 0
        initial_var = args_with_eq[1].args[2]
        initial_var_name = args_with_eq[1].args[1]
    else
        initial_var = nothing
        initial_var_name = nothing
    end
      
    # parse arguments with in
    args_with_in = filter(x -> x.args[1] == :in, arg_list)
    length(args_with_in) == 3  ? nothing : throw(error("If any variable is specified, all variables (or only their names) should be specified"))


    bounds=[]
    for i in 1:3
        arg_1 = args_with_in[i].args[end].args[1]
        arg_2 = args_with_in[i].args[end].args[2]
        if arg_1 isa Real && arg_2 isa Real
            arg_1 <= arg_2 ? nothing : throw(error("$arg_1 greater than $arg_2!"))
        end
        push!(bounds,arg_1,arg_2)
    end   
    
    _bound_error() = error("Initial/Final bound not in the total bound")

    for i in 1:2
       (bounds[i] == :Inf || bounds[i+2] == :Inf) && (bounds[i+4] isa Real) ? _bound_error() : nothing
       if (bounds[i] isa Real && bounds[i+2] isa Real && bounds[i+4] isa Real) 
            ((bounds[i] >= bounds[i+4] && bounds[i+2] >= bounds[i+4]) || (bounds[i] <= bounds[i+4] && bounds[i+2] <= bounds[i+4])) ? nothing : _bound_error() 
       end
    end
    var_names=[args_with_in[1].args[2], args_with_in[2].args[2], args_with_in[3].args[2]]
    
    return initial_var, initial_var_name, bounds, var_names
end

function parse_args(args,_index)

    arg_list = collect(args)    
    new_list = []
    # turn each unspecified element into standard form by adding :in and [-Inf,Inf] at the end
    for i in eachindex(arg_list)
        i in _index ? push!(new_list,Expr(:call,:in,:($(arg_list[i])),:([-Inf,Inf]))) : push!(new_list,arg_list[i])
    end 
    
    # call standard parse function
    return parse_args(new_list)
end


function output_macro(m,diff_var_data)
     
    #m.Differential_var_index = Dict{Symbol,Differential_Var_data}([(diff_var_data.Run_sym,diff_var_data)])
    #m.independent_var_index = Dict{Symbol,Independent_Var_data}()
    
    return m

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


 @differential_variable( model, x₀=0, x₀ in [0,10], x₁ in [90,100], x in [0,100])

 julia> a=JuDO.@differential_variable( model, x₀=0, x₀ in [0,10], x₁, x)
 Main.JuDO.Differential_Var_data(:x₀, 0, [0, 10], :x₁, Any[:(-Inf), :Inf], :x, Any[:(-Inf), :Inf])
# constraint / guess and interpolant (for solver) of the initial value 

 @differential_variable( model, x₀ in [0,10], x₁, x)

 @differential_variable( model)

 # to do: add the input type @differential_variable( model, x₀=0, x₁==10,...)
# keyword/arguments/ to allow a freedom of input order
# create a test file 

 Model must be provided, the rest is optional, 
 but once specified a variable then all three variables (or only their names) should be specified.
 If there is no bounds provided, the user only need to type in the variable symbol, then the default bounds are [-Inf,Inf]

"""

macro differential_variable(_model,args...)
    
    expr_of_model = quote $(esc(_model)) end
    _model = expr_of_model.args[2].args[1]

    if length(args) == 0
        return construct_differential_variable(nothing, [nothing for i in 1:6], [nothing for i in 1:3])
    end

   
    if length(filter(x -> x isa Symbol, collect(args))) != 0

        # if there is any infinite bound
        unspecified_index = [i for i in 1:length(args) if args[i] isa Symbol]
        initial_var, initial_var_name, bounds, var_names = parse_args(args,unspecified_index)
    else

        initial_var, initial_var_name, bounds, var_names = parse_args(args)
    end
     
    _var_data = construct_differential_variable(initial_var, bounds, var_names)

    return  _var_data
end
 

#to do
"""
    @independent_variable(model, args)

    The final value or range of the independent variable (time is used in the following documentation)
    
    If it is not called, then a free-time problem is assumed.
    
    Argument can be: t=5 

"""
macro independent_variable(model::Dy_Model, args...)
     
end
