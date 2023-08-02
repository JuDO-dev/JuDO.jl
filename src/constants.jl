function new_or_exist_constant(_model,_args)

    _args[1].head == :(=) && length(_args[1].args) == 2 ? nothing : error("Incorrect input style, make sure 'symbol = value' is used")

    _sym = _args[1].args[1]
    _args = _args[1].args[2]

    _sym isa Symbol ? nothing : error("A symbol is expected for the second argument")

    same_var_error(_model,_sym) 
    return add_new_const(_model,_sym,_args)
end

function add_new_const(_model,_sym,_args)
    const_data = Constant_data(_sym,eval(_args))
    _model.Constant_index[const_data.Sym] = const_data

    index = DOI.add_constant(_model.optimizer.constants,const_data)
    constant_ref = ConstantRef(_model,index)

    return constant_ref
end

mutable struct ConstantRef <: AbstractDynamicRef
    model::Abstract_Dynamic_Model
    index::DOI.ConstantIndex
end