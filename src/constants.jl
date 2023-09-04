function new_or_exist_constant(_model,_args)

    _args[1].head == :(=) && length(_args[1].args) == 2 ? nothing : error("Incorrect input style, make sure 'symbol = value' is used")

    _sym = _args[1].args[1]
    val = _args[1].args[2]
   
    (_sym isa Symbol ) ? nothing : error("Incorrect input style, make sure 'symbol = value' is used")
        same_var_error(_model,_sym) 

    if (val isa Number) || (val isa Symbol)
        const_data = Constant_data(_sym,eval(val))

        return add_new_const(_model,const_data)

    elseif length(val.args) == 2
        identified_val = scalar_dynamics(_model,val,:t)

        const_data = Constant_data(_sym,identified_val)
        return add_new_const(_model,const_data)

    else
        throw(error("The constant is not supported"))
    end


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