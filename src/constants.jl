function new_or_exist_constant(_model,_args)

    _args[1].head == :(=) && length(_args[1].args) == 2 ? nothing : error("Incorrect input style, make sure 'symbol = value' is used")

    _sym = _args[1].args[1]
    _args = _args[1].args[2]

    _sym isa Symbol ? nothing : error("A symbol is expected for the second argument")

    haskey(_model.Differential_var_index,_sym) ? (return add_exist_const(_model,_sym,_args)) : (return add_new_const(_model,_sym,_args))
end

function add_exist_const(_model,_sym,_args)
    setfield!(_model.Constant_index[_sym],:Value,_args)

    return _model.Constant_index
end

function add_new_const(_model,_sym,_args)
    const_data = Constant_data(_sym,_args)

    _model.Constant_index[const_data.Sym] = const_data

    return _model.Constant_index
end