symbol_error() = throw(error("A symbol is expected for the second argument"))

_bound_error() = throw(error("Initial/Final bound not in the total bound"))

input_style_error() = throw(error("Keyword argument input style incorrect, make sure all arguments are in the form of keyword = value"))

diff_var_input_style_error() = throw(error("Incorrect use of 'keyword = value' and 'keyword in value'"))

multiple_independent_var_error() = throw(error("Only one independent variable is allowed, please use set_independent_var to change the independent variable"))

function same_var_error(_model,sym) 
    t = collect(keys(_model.Independent_var_index))
    i = collect(keys(_model.Initial_Independent_var_index))
    f = collect(keys(_model.Final_Independent_var_index))
    diff = collect_keys(_model.Differential_var_index)
    alg = collect_keys(_model.Algebraic_var_index)
    con = collect(keys(_model.Constant_index))

    append!(diff,alg)
    append!(diff,t)
    append!(diff,i)
    append!(diff,f)
    append!(diff,con)

    if sym in diff
        throw(error("The symbol $(sym) is already used in the model"))
    end
end


function check_contradict(collection,val)
    val[1] <= val[2] ? nothing : throw(error("Initial value greater than final value in the bound"))

    for i in eachindex(collection)
        if collection[i][1] >= val[2] || collection[i][2] <= val[1]
            throw(error("The bound $(val) contradicts with $(collection[i])"))
        end
    end
    
end

function check_alge_bound(val,bound)
    (bound[1] <= bound[2]) ? nothing : throw(error("Initial value greater than final value in the bound"))
    if val !== nothing
        (val >= bound[1] && val <= bound[2]) ? nothing : throw(error("The initial guess $(val) is not inside the bound $(bound)"))
    end
end

function check_modified(var)

   bound_lower_upper(var.Initial_bound) 
end

function bound_lower_upper(_bound)
    _bound[1] isa Real && _bound[2] isa Real ? nothing : throw(error("Elements in the bound must be real numbers"))
    _bound[1] < _bound[2] ? nothing : throw(error("Initial value greater than final value in the bound"))
end

function bound_not_inside_error(_initial_bound,_final_bound,_total_bound)
    _initial_bound[1] >= _total_bound[1] && _initial_bound[2] <= _total_bound[2] ? nothing : throw(error("Initial bound is not inside the trajectory bound"))
    _final_bound[1] >= _total_bound[1] && _final_bound[2] <= _total_bound[2] ? nothing : throw(error("Final bound is not inside the trajectory bound"))
end

function input_argument_error(_args)
    if length(_args) == 0
        symbol_error()
    elseif length(_args) > 1
        println("dd")
        multiple_independent_var_error()
    end
end

function check_initial_guess(_info)
    # check for the potential errors in the input bounds

    if _info[1] !== nothing
        _info[1] >= _info[2][1] && _info[1] <= _info[2][2] ? nothing : throw(error("The initial guess is not inside the initial bound"))
    end
end    

### Error messages for the algebraic variables
algebraic_input_style_error() = throw(error("Argument input style incorrect, make sure 'symbol in bound' is used expressions"))