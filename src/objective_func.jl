function check_inner_quad_term(_model,_expr,coeff)
    #check the term is about x(.) or u(.), t or tf, and give the coefficient to DOI
    (_expr isa Expr) ? nothing : (return false)
    diff_var_names = collect_keys(_model.Differential_var_index)
    alge_var_names = collect_keys(_model.Algebraic_var_index)
    if (_expr.head == :call) && (length(_expr.args) == 2) && ((_expr.args[1] in diff_var_names)||((_expr.args[1] in alge_var_names)))
        
        if (_expr.args[1] in diff_var_names)
            (coeff !== nothing) ? (quadratic_diff = coeff) : (quadratic_diff = 1)
            (_expr.args[2] == collect(keys(_model.Independent_var_index))[1]) ? (index = 1) : (index = 3)
            DOI.construct_pure_quadratic(_model.optimizer.Purequadratic_coeff,quadratic_diff,index)

            println("quadratic_diff = ",quadratic_diff,index)
        elseif (_expr.args[1] in alge_var_names) 
            (coeff !== nothing) ? (quadratic_alge = coeff) : (quadratic_alge = 1)
            (_expr.args[2] == collect(keys(_model.Independent_var_index))[1]) ? (index = 2) : (index = 4)
            DOI.construct_pure_quadratic(_model.optimizer.Purequadratic_coeff,quadratic_alge,index)

            println(" quadratic_alge = ",quadratic_alge,index)
        end
        
        return true
    else
        return false
    end
    
end

function check_inner_composite(_model,_expr,coeff)
    #check composite term like x(t)-x_ref, u(t)-u_ref
    if (_expr isa Expr) && (_expr.head == :call) && (length(_expr.args) == 3) && (_expr.args[1] == :-) 
        if (check_inner_quad_term(_model,_expr.args[2],coeff) == true) && const_Number_array(_model,_expr.args[3])
            return true
        end
    elseif  check_inner_quad_term(_model,_expr,coeff) == true
        return true
    end
end

function pure_qua_scalar(_model,_expr,coeff)
    
    (_expr isa Expr) ? nothing : (return false)
    if (_expr.head == :call) && (length(_expr.args) == 3)
        #check basic scalar quadratic term like x(t)^2 or (x(t)-x_ref)^2 
        if (_expr.args[1] == :^) && (_expr.args[3] == 2) 
            (check_inner_composite(_model,_expr.args[2],coeff) == true) ? (return true) : (return false)

        #check basic scalar quadratic term like x(t)*x(t) or (x(t)-x_ref)*(x(t)-x_ref) 
        elseif (_expr.args[1] == :*) && (_expr.args[2] == _expr.args[3])
            (check_inner_composite(_model,_expr.args[2],coeff) == true) ? (return true) : (return false)

        #check composite scalar quadratic term like 3*x(t)^2 or 3*(x(t)-x_ref)^2
        elseif (_expr.args[1] == :*) && const_Number_array(_model,_expr.args[2])
            (_expr.args[2] isa Number) ? (coeff = _expr.args[2]) : (coeff = _model.Constant_index[_expr.args[2]].Value)
            (pure_qua_scalar(_model,_expr.args[3],coeff) == true) ? (return true) : (return false)
        end
    #check composite scalar quadratic term like 3*x(t)*x(t) or 3*(x(t)-x_ref)*(x(t)-x_ref)
    elseif (_expr.head == :call) && (length(_expr.args) == 4) && (_expr.args[1] == :*) && const_Number_array(_model,_expr.args[2]) && (_expr.args[3] == _expr.args[4])
        (_expr.args[2] isa Number) ? (coeff = _expr.args[2]) : (coeff = _model.Constant_index[_expr.args[2]].Value)
           (check_inner_composite(_model,_expr.args[3],coeff) == true) ? (return true) : (return false)
    end

    return false

end

function check_quad_term(_model,_expr,container,coeff)
    #check composite scalar and vector quadratic term like x(t)^2 or (x(t)-x_ref)^2, if so then stop parsing
    if ((_expr isa Expr) && (length(_expr.args) == 2) && (_expr.args[1] != :∫)) || (_expr isa Number) || (_expr isa Symbol)
        return push!(container,false)

    elseif (pure_qua_scalar(_model,_expr,coeff) == true) || (pure_qua_vector(_model,_expr) == true)
        return push!(container,true)

    #continue parsing until the scalar or vector quadratic term is found
    elseif (_expr isa Expr) && (_expr.head == :call) && (((length(_expr.args) == 2) && (_expr.args[1] == :∫)) || (length(_expr.args) >= 3))
        #if there is a explicit coefficient
        (_expr.args[1] == :*) && (_expr.args[2] isa Number) ? (coeff = _expr.args[2]) : nothing 
        (_expr.args[1] == :*) && (_expr.args[2] in collect(keys(_model.Constant_index))) ? (coeff = _model.Constant_index[_expr.args[2]].Value) : nothing
        #= julia> m.optimizer.Purequadratic_coeff
        DynOptInterface.PureQuadraticCoefficients(Any[[0.01 0.0 0.0 0.0; 0.0 0.01 0.0 0.0; 0.0 0.0 0.01 0.0; 0.0 0.0 0.0 0.01], :R, [100 0 0 0; 0 100 0 0; 0 0 100 0; 0 0 
        0 100], 0])   =#      

        for term in _expr.args
            if !(term in [:+,:-,:*,:/,:^,:∫])
                check_quad_term(_model,term,container,coeff)
            end
        end
    end
    return container
end

#####################
function const_and_Number(_model,arg)
    (arg in collect(keys(_model.Constant_index))) || (arg isa Number) ? (return true) : (return false)
end

function const_and_array(_model,arg)
    (arg in collect(keys(_model.Constant_index))) || ((arg.head == :vcat) && (arg.args isa Array)) ? (return true) : (return false)
end

function const_Number_array(_model,arg)
    (arg in collect(keys(_model.Constant_index))) || (arg isa Number) || ((arg.head == :vcat) && (arg.args isa Array)) ? (return true) : (return false)
end

function pure_qua_vector(_model,_expr)
    
    (_expr isa Expr) && (_expr.head == :call) && (length(_expr.args) == 4) && (_expr.args[1] == :*) && (_expr.args[2].head == Symbol("'")) && const_and_array(_model,_expr.args[3]) ? nothing : (return false)
    (_expr.args[2].args[1] == _expr.args[4]) ? nothing : (return false)

    (_expr.args[3] isa Expr) && ((_expr.args[3].head == :vcat) && (_expr.args[3].args isa Array)) ? (coeff = _expr.args[3]) : (coeff = _model.Constant_index[_expr.args[3]].Value)
    if _expr.args[2].args[1].head == :call
        #check basic vector quadratic term like x(t)'*Q*x(t) or (x(t)-x_ref)'*Q*(x(t)-x_ref) 
        (check_inner_composite(_model,_expr.args[4],coeff) == true) ? (return true) : (return false)

    #check composite vector quadratic term like [x(t);u(t)]'*Q*[x(t);u(t)] or [x(t)-x_ref;u(t)-u_ref]'*Q*[x(t)-x_ref;u(t)-u_ref]
    elseif (_expr.args[2].args[1].head == :vcat) 
        len = length(_expr.args[2].args[1].args)
        for i in 1:len
            _expr.args[2].args[1].args[i] == _expr.args[4].args[i] ? nothing : (return false)
        end
        for i in 1:len
        (check_inner_composite(_model,_expr.args[4].args[i],coeff) == true) ? nothing : (return false) ###
        end
        return true
    end

    return false
    
end

function check_integral(_expr,sym)
    
    if (_expr isa Expr) && (_expr.head == :call) && (length(_expr.args) == 2) 
        (_expr.args[2] == sym) ? nothing : throw(error("Incorrect use of independent variable in the objective function"))
    end

    terms = _expr.args
    for term in terms
        if (term isa Expr) && (term.head == :call) && (length(term.args) == 2) 
            (term.args[2] == sym) ? nothing : throw(error("Incorrect use of independent variable in the objective function"))
        elseif (term isa Expr) && (length(term.args) > 2)
            check_integral(term,sym)  
        end
    end

end

function check_bolza_mayer(_model,_expr)
    run_sym = collect(keys(_model.Independent_var_index))[1]
    final_sym = collect(keys(_model.Final_Independent_var_index))[1]

    if (_expr isa Expr) && (_expr.head == :call) && (length(_expr.args) == 2)
        if (_expr.args[1] == :∫) 
            check_integral(_expr.args[2],run_sym)
        elseif (_expr.args[2] != final_sym) 
            throw(error("Incorrect use of independent variable in the objective function"))
        end
    end

    if (_expr isa Expr) && (_expr.head == :call) && (length(_expr.args) > 2)
        terms = _expr.args
    
        for term in terms
            check_bolza_mayer(_model,term)
        end
    end
end

function parse_objective_function(_model,_args)
    (_model.Dynamic_objective != :()) ? error("The objective function can only be added once in the model") : nothing
    (length(_args) != 1) ? error("Incorrect number of arguments") : nothing

    feasibility = false
    bolza = false
    mayer = false
    lagrange = false
    pure_quad = false
    # determine the type of the objective function, whether it is a mayer or lagrange function

    if (_args[1] isa Number) || (_args[1] === nothing)
        feasibility = true
    elseif ((length(_args[1].args) == 2) && (_args[1].args[1] == :∫)) || ((length(_args[1].args) == 3) && (_args[1].args[2] isa Number) && (_args[1].args[3].args[1] == :∫))
        
        (length(_args[1].args) == 2) ? (run_cost = _args[1].args[2]) : nothing
        (length(_args[1].args) == 3) ? (run_cost = _args[1].args[3].args[2]) : nothing
        check_integral(run_cost,collect(keys(_model.Independent_var_index))[1])

        lagrange = true
    elseif (length(_args[1].args) >= 2)
        (:∫ in check_all_const(_args[1],[])) ? (bolza = true) : (mayer = true)

        check_bolza_mayer(_model,_args[1])

    end


    !(false in check_quad_term(_model,_args[1],[],nothing)) ? (pure_quad = true) : (DOI.delete_quadratic(_model.optimizer.Purequadratic_coeff))

    #!(false in check_quad_term_vector(_model,_args[1],[])) ? (pure_quad = true) : (DOI.delete_quadratic(_model.optimizer.Purequadratic_coeff))
    println("feasibility =",feasibility," bolza =",bolza," mayer =",mayer," lagrange =",lagrange," pure_quad =",pure_quad)

    #= terms,type = parse_and_separate(_model,[],_args[1],nothing,[],[])

    code_of_independent_var = get_unicode(string(collect(keys(_model.Independent_var_index))[1]))
    call_trajectory(_model,unique(terms),code_of_independent_var)

    _model.Dynamic_objective = _args[1] =#

    return #terms,type
end

