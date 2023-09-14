mutable struct ConstantRef <: AbstractDynamicRef
    model::Abstract_Dynamic_Model
    index::DOI.ConstantIndex
end

mutable struct ParameterRef <: AbstractDynamicRef
    model::Abstract_Dynamic_Model
    index::DOI.ParameterIndex
end

function eval_const_param(_model,_args)
    _args[1].head == :(=) && length(_args[1].args) == 2 ? nothing : error("Incorrect input style, make sure 'symbol = value' is used")

    _sym = _args[1].args[1]
    val = _args[1].args[2]
   
    (_sym isa Symbol ) ? nothing : error("Incorrect input style, make sure 'symbol = value' is used")
    same_var_error(_model,_sym) 

    try
        identified_val = eval(val)
    catch
        throw(error("The constant is not supported, make sure it is a number or an array"))
    end

    return _sym,val
end

function new_parameter(_model,_args)
    _sym, val = eval_const_param(_model,_args)

    param_data = Parameter_data(_sym,eval(val))
    return add_new_param(_model,param_data)
end

function new_constant(_model,_args)
    _sym, val = eval_const_param(_model,_args)

    const_data = Constant_data(_sym,eval(val))
    return add_new_const(_model,const_data)

end

function add_new_const(_model,_data)

    _model.Constant_index[_data.Sym] = _data
    index = DOI.add_variable(_model.optimizer.constants,_data) #add_variable 
    constant_ref = ConstantRef(_model,index)

    return constant_ref
end

function add_new_param(_model,_data)
    _model.Parameter_index[_data.Sym] = _data
    index = DOI.add_variable(_model.optimizer.parameters,_data)
    parameter_ref = ParameterRef(_model,index)

    return parameter_ref
    
end

function return_const_param(_model,_arg)
    (_arg in collect(keys(_model.Constant_index))) ? (return _model.Constant_index[_arg].Value) : nothing
    (_arg in collect(keys(_model.Parameter_index))) ? (return _model.Parameter_index[_arg].Value) : nothing
end

function check_const_param(_model,_arg)
    (_arg in collect(keys(_model.Constant_index))) ? (return true) : nothing
    (_arg in collect(keys(_model.Parameter_index))) ? (return true) : nothing
    return false    
end

######################

#for checking and returning constants added without macros
function check_constant(_con)
    #println(Main._con)
    r = true
    try
        getfield(Main,_con)
    catch
        r = false
    end
    return r
    
end

function return_constant(_con)
    try
        getfield(Main,_con)
    catch
        throw(error("The constant $_con is not defined"))
    end

    return getfield(Main,_con)
    
end

#######################################
function set_constant(ref::ConstantRef,val::Number)
    DOI.set_constant(ref.model.optimizer.constants,ref.index.value,val)

    sym = collect(keys(ref.model.Constant_index))[index]
    ref.model.Constant_index[sym].Value = val
end

function set_parameter(ref::ParameterRef,val::Number)
    DOI.set_constant(ref.model.optimizer.parameters,ref.index.value,val)

    sym = collect(keys(ref.model.Parameter_index))[index]
    ref.model.Constant_index[sym].Value = val
end

function delete_constant(ref::ConstantRef)
    DOI.delete_constant(ref.model.optimizer.constants,ref.index.value)

    sym = collect(keys(ref.model.Constant_index))[index]
    delete!(ref.model.Constant_index,sym)
end

function delete_parameter(ref::ParameterRef)
    DOI.delete_parameter(ref.model.optimizer.parameters,ref.index.value)

    sym = collect(keys(ref.model.Parameter_index))[index]
    delete!(ref.model.Parameter_index,sym)
end