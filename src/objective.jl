integrate_sym = [:integral,:∫]
quadratic_coeff = Any[0,0,0,0] #Q R Qf Rf

function check_inner_quad_term(_model,_expr,coeff)
    #check the term is about x(.) or u(.), t or tf, and give the coefficient to DOI
    (_expr isa Expr) ? nothing : (return false)
    diff_var_names = collect_keys(_model.Differential_var_index)
    alge_var_names = collect_keys(_model.Algebraic_var_index)
    if (_expr.head == :call) && (length(_expr.args) == 2) && ((_expr.args[1] in diff_var_names)||((_expr.args[1] in alge_var_names)))
        
        if (_expr.args[1] in diff_var_names)
            (coeff !== nothing) ? (quadratic_diff = coeff) : (quadratic_diff = 1)
            (_expr.args[2] == collect(keys(_model.Independent_var_index))[1]) ? (index = 1) : (index = 3)
            quadratic_coeff[index] = quadratic_diff
            #DOI.add_objective(_model.optimizer.Purequadratic_coeff,quadratic_diff,index)

        elseif (_expr.args[1] in alge_var_names) 
            (coeff !== nothing) ? (quadratic_alge = coeff) : (quadratic_alge = 1)
            (_expr.args[2] == collect(keys(_model.Independent_var_index))[1]) ? (index = 2) : (index = 4)
            quadratic_coeff[index] = quadratic_alge
            #DOI.add_objective(_model.optimizer.Purequadratic_coeff,quadratic_alge,index)

        end
        
        return true
    else
        return false
    end
    
end

function pure_qua_scalar(_model,_expr,coeff)
    (_expr isa Expr) ? nothing : (return false)
    if (_expr.head == :call) && (length(_expr.args) == 3)
        #check basic scalar quadratic term like x(t)^2 
        if (_expr.args[1] == :^) && (_expr.args[3] == 2) 
            (check_inner_quad_term(_model,_expr.args[2],coeff) == true) ? (return true) : (return false)

        #check basic scalar quadratic term like x(t)*x(t) 
        elseif (_expr.args[1] == :*) && (_expr.args[2] == _expr.args[3])
            (check_inner_quad_term(_model,_expr.args[2],coeff) == true) ? (return true) : (return false)

        #check composite scalar quadratic term like 3*x(t)^2
        elseif (_expr.args[1] == :*) && const_Number_array(_model,_expr.args[2])
            (_expr.args[2] isa Number) ? (coeff = _expr.args[2]) : (coeff = _model.Constant_index[_expr.args[2]].Value)
            (pure_qua_scalar(_model,_expr.args[3],coeff) == true) ? (return true) : (return false)
        end
    #check composite scalar quadratic term like 3*x(t)*x(t) 
    elseif (_expr.head == :call) && (length(_expr.args) == 4) && (_expr.args[1] == :*) && const_Number_array(_model,_expr.args[2]) && (_expr.args[3] == _expr.args[4])
        (_expr.args[2] isa Number) ? (coeff = _expr.args[2]) : (coeff = _model.Constant_index[_expr.args[2]].Value)
           (check_inner_quad_term(_model,_expr.args[3],coeff) == true) ? (return true) : (return false)
    end

    return false

end

function check_quad_term(_model,_expr,container,coeff)
    #check composite scalar and vector quadratic term like x(t)^2, if so then stop parsing
    if ((_expr isa Expr) && (length(_expr.args) == 2) && !(_expr.args[1] in [:∫,:integral])) || (_expr isa Number) || (_expr isa Symbol)
        return push!(container,false)

    elseif (pure_qua_scalar(_model,_expr,coeff) == true) || (pure_qua_vector(_model,_expr) == true)
        return push!(container,true)

    #continue parsing until the scalar or vector quadratic term is found
    elseif (_expr isa Expr) && (_expr.head == :call) && (((length(_expr.args) == 2) && (_expr.args[1] in [:∫,:integral])) || (length(_expr.args) >= 3))
        #if there is a explicit coefficient
        (_expr.args[1] == :*) && (_expr.args[2] isa Number) ? (coeff = _expr.args[2]) : nothing 
        (_expr.args[1] == :*) && (_expr.args[2] in collect(keys(_model.Constant_index))) ? (coeff = _model.Constant_index[_expr.args[2]].Value) : nothing    

        for term in _expr.args
            if !(term in [:+,:-,:*,:/,:^,:∫,:integral])
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
        #check basic vector quadratic term like x(t)'*Q*x(t) 
        (check_inner_quad_term(_model,_expr.args[4],coeff) == true) ? (return true) : (return false)

    #check composite vector quadratic term like [x(t);u(t)]'*Q*[x(t);u(t)] 
    elseif (_expr.args[2].args[1].head == :vcat) 
        len = length(_expr.args[2].args[1].args)
        for i in 1:len
            _expr.args[2].args[1].args[i] == _expr.args[4].args[i] ? nothing : (return false)
        end
        for i in 1:len
        (check_inner_quad_term(_model,_expr.args[4].args[i],coeff) == true) ? nothing : (return false) ###
        end
        return true
    end

    return false
    
end

#####################

#parse the expression outside or inside the integral
function check_mayer_lagrange(_model,_args,sym)
    
    return scalar_dynamics(_model,_args,sym)

end

function check_bolza_mayer(_model,_args,_has_integrand,type)
    if (_args isa Number) || (_args isa Symbol) || (_args === nothing)
        m_func = check_mayer_lagrange(_model,_args,collect(keys(_model.Independent_var_index))[1])

    #check mayer function
    elseif (!_has_integrand) && (length(collect(keys(_model.Final_Independent_var_index))) != 0)
        m_func = check_mayer_lagrange(_model,_args,collect(keys(_model.Final_Independent_var_index))[1])
        type[2] = m_func

    #check lagrange function ∫() 
    elseif (length(_args.args) == 2) && (_args.args[1] in integrate_sym) 
        l_func = check_mayer_lagrange(_model,_args.args[2],collect(keys(_model.Independent_var_index))[1])
        type[1] = l_func
        
    #-∫() 
    elseif ((length(_args.args) == 2) && (_args.args[1] == :-) && (_args.args[2].args[1] in integrate_sym))
        l_func = check_mayer_lagrange(_model,_args.args[2].args[2],collect(keys(_model.Independent_var_index))[1])
        expression = Expr(:call,:-,l_func)
        type[1] = expression

    #a*∫(), ()/()...*∫()
    elseif (length(_args.args) > 2) && !(_args.args[1] in [:+,:-]) 
        l_func = []
        
        lagrange = false
        for i in 2:length(_args.args)
            if (_args.args[i] isa Expr) && (_args.args[i].args[1] in integrate_sym) && length(_args.args[i].args) == 2
                lagrange = true
                push!(l_func, check_mayer_lagrange(_model,_args.args[i].args[2],collect(keys(_model.Independent_var_index))[1]))
                break
            end
            
            push!(l_func, check_mayer_lagrange(_model,_args.args[i],collect(keys(_model.Independent_var_index))[1]))
 
        end
        
        (lagrange == true) ? (l_func = Expr(:call,_args.args[1],l_func...)) : (l_func = nothing)
        type[1] = l_func

    elseif (length(_args.args) > 2) && _has_integrand
        
        if (length(_args.args) > 3) && (length(collect(keys(_model.Final_Independent_var_index))) != 0)
            total = Expr(:call,_args.args[1],_args.args[2:end-1]...)
            type[1] = check_mayer_lagrange(_model,total,collect(keys(_model.Final_Independent_var_index))[1])
        
        elseif length(collect(keys(_model.Final_Independent_var_index))) != 0
            type[1] = check_mayer_lagrange(_model,_args.args[2],collect(keys(_model.Final_Independent_var_index))[1])
        end

        type[2] = check_mayer_lagrange(_model,_args.args[end].args[2],collect(keys(_model.Independent_var_index))[1])
    end

    return type

end

function parse_objective_function(_model,_args)
    (_model.Objective_index != :()) ? error("The objective function can only be added once in the model") : nothing

    has_integrand = (:∫ in check_all_const(_args[1],[])) || (:integral in check_all_const(_args[1],[]))
    type = Any[:(),:()]

    lagrange, mayer = check_bolza_mayer(_model,_args[1],has_integrand,type)
    println(lagrange)
    println(mayer)

    u_limit = _model.Independent_var_index.vals[1].Bound[2]
    l_limit = _model.Independent_var_index.vals[1].Bound[1]
    #if user has specified the limits of integration 
    if (lagrange != :()) && (length(_args) > 1)
        for i in 2:length(_args)
            (_args[i].args[1] == :initial) ? (l_limit = eval(scalar_dynamics(_model,_args[i].args[2],_model.Initial_Independent_var_index.vals))) : nothing

            (_args[i].args[1] == :final) ? (u_limit = eval(scalar_dynamics(_model,_args[i].args[2],_model.Final_Independent_var_index.vals))) : nothing
        end
    end

    #check pure quadratic term and store the coefficient
    !(false in check_quad_term(_model,_args[1],[],nothing)) ? (pure_quad = true) : (pure_quad = false)
    (pure_quad == true) ? (DOI.add_objective(_model.optimizer.Purequadratic_coeff,quadratic_coeff)) : nothing

    _model.Objective_index = _args[1];

    
    return 
end

