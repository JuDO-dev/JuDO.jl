symbol_error() = throw(error("A symbol is expected for the second argument"))

_bound_error() = throw(error("Initial/Final bound not in the total bound"))

input_style_error() = throw(error("Keyword argument input style incorrect, make sure all arguments are in the form of keyword = value"))

multiple_independent_var_error() = throw(error("Only one independent variable is allowed"))

function bound_lower_upper(_bound)
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
algebraic_input_style_error() = throw(error("Argument input style incorrect, make sure either 'in' or '=' is used expressions"))

contradicted_input(arg,flag) = throw(error("A $arg is provided, but 'discrete' is specified as $flag, please check the input arguments"))