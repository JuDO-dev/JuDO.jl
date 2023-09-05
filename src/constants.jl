function new_constant(_model,_args)

    _args[1].head == :(=) && length(_args[1].args) == 2 ? nothing : error("Incorrect input style, make sure 'symbol = value' is used")

    _sym = _args[1].args[1]
    val = _args[1].args[2]
   
    (_sym isa Symbol ) ? nothing : error("Incorrect input style, make sure 'symbol = value' is used")
        same_var_error(_model,_sym) 

    try
        identified_val = eval(val)
    catch
        throw(error("The constant is not supported"))
    end

    const_data = Constant_data(_sym,eval(val))
    return add_new_const(_model,const_data)

end

function add_new_const(_model,_data)
    

    _model.Constant_index[_data.Sym] = _data
    index = DOI.add_constant(_model.optimizer.constants,_data)
    constant_ref = ConstantRef(_model,index)

    return constant_ref
end

mutable struct ConstantRef <: AbstractDynamicRef
    model::Abstract_Dynamic_Model
    index::DOI.ConstantIndex
end