symbol_error() = throw(error("A symbol is expected for the second argument"))

_bound_error() = throw(error("Initial/Final bound not in the total bound"))

input_style_error() = throw(error("Keyword argument input style incorrect, make sure all arguments are in the form of keyword = value"))

multiple_independent_var_error() = throw(error("Only one independent variable is allowed"))

function var_not_inside_error(_val,_bound)  
    _val >= _bound[1] && _val <= _bound[2] ? nothing : throw(error("The initial/final value is not inside the initial/final bound"))
end

function bound_lower_upper(_bound)
    _bound[1] < _bound[2] ? nothing : throw(error("Initial value greater than final value in the bound"))
end

function bound_not_inside_error(_initial_bound,_final_bound,_total_bound)
    _initial_bound[1] >= _total_bound[1] && _initial_bound[2] <= _total_bound[2] ? nothing : throw(error("Initial bound is not inside the trajectory bound"))
    _final_bound[1] >= _total_bound[1] && _final_bound[2] <= _total_bound[2] ? nothing : throw(error("Final bound is not inside the trajectory bound"))
end

function check_final_diff_var(_info)
    # check for the potential errors in the input bounds
    _info[1] === nothing ? nothing : var_not_inside_error(_info[1],_info[3])
    _info[2] === nothing ? nothing : var_not_inside_error(_info[2],_info[4])
end    