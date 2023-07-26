function parse_objective_function(_model,_args)
    (_model.Dynamic_objective != :()) ? error("The dynamic function can only be added once in the model") : nothing

    terms,type = parse_and_separate(_model,[],_args[1],nothing,[],[])

    code_of_independent_var = get_unicode(string(collect(keys(_model.Independent_var_index))[1]))
    call_trajectory(_model,unique(terms),code_of_independent_var)

    _model.Dynamic_objective = _args[1]

    return terms,type
end

