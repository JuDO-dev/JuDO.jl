function get_unicode(string)
    return [codepoint(i) for i in string]
end

function get_normalized_unicode(string)
    decomposed = Unicode.normalize(string, decompose = true)
    return [codepoint(i) for i in decomposed]
end

function check_constraint_name(_model,_name)
    if _name isa Symbol
        if _name in keys(_model.Constraints_index)
            throw(error("The constraint name $_name is already used, please use another name"))
        end
    else
        throw(error("The constraint name $_name is not a valid symbol"))
    end
    
end

function collect_keys(_indices)
    collection = collect(keys(_indices))
    symbols = []

    [push!(symbols,i.args[1]) for i in collection if i isa Expr]

    return symbols
end

function check_diff_alge(_model,_term)
    if (_term in collect_keys(_model.Differential_var_index)) || (_term in collect_keys(_model.Algebraic_var_index)) 
        return true
    else 
        unicode = get_normalized_unicode(string(_term))
        if unicode[end] == 0x307
            for i in collect_keys(_model.Differential_var_index)
                if unicode[1:end-1] == get_normalized_unicode(string(i))
                    return true
                end
            end
            for i in collect_keys(_model.Algebraic_var_index)
                if unicode[1:end-1] == get_normalized_unicode(string(i))
                    return true
                end
            end
        end
    end
    return false
end

function check_vector_constraint(_model,term)
    diff_var_names = collect_keys(_model.Differential_var_index)
    alg_var_names = collect_keys(_model.Algebraic_var_index)

    for i in eachindex(diff_var_names)
        if term == diff_var_names[i]
           (_model.Differential_var_index[collect(keys(_model.Differential_var_index))[i]] isa Vector) ? (return true) : (return false)
        end
    end

    for i in eachindex(alg_var_names)
        if term == alg_var_names[i]
            (_model.Algebraic_var_index[collect(keys(_model.Algebraic_var_index))[i]] isa Vector) ? (return true) : (return false)
        end
    end
end

function check_division(_model,_side,type)
    if (_side.args[1] == :/) 
        possible_const = check_all_const(_side.args[end],[])
        for term in possible_const
            if check_diff_alge(_model,term)
                push!(type,:nonlinear)
                #println(type," in ",_terms)
                return type
                
            end
        end
    end

    return push!(type,:linear)

end

function check_hat(_model,_side,type)
    if (_side.args[1] == :^) 
        for i in 2:length(_side.args)
            possible_const = check_all_const(_side.args[i],[])
            for term in possible_const
                if check_diff_alge(_model,term)
                    push!(type,:nonlinear)
                    #println(type," in ",_terms)
                    return type
                    
                end
            end
        end
    end

    return push!(type,:linear)
end

function check_multiplication(_model,_side,type)
    (_side.args[1] in [:+,:-]) ? (return push!(type,:linear)) : nothing

    len = length(_side.args)
    _terms = _side.args

    #check if there exists a term in _terms that is x(t) like, record its position
    exist = false
    pos = 0
    for i in 1:len
        if (_terms[i] isa Expr) && (length(_terms[i].args) == 2) && check_diff_alge(_model,_terms[i].args[1])
            exist = true
            pos = i
        end
    end

    #if there is one x(t) like term, then check if there is another x(t) like term, or an expresssion that contains x(t) like term.
    if exist == true
        for i in 1:len
            if (i != pos) && (_terms[i] isa Expr) && (length(_terms[i].args) == 2) && check_diff_alge(_model,_terms[i].args[1])
                #if there is another x(t) like term, then it is nonlinear
                push!(type,:nonlinear)
                #print_info(type,_terms)
                return type
            elseif (i != pos) && (_terms[i] isa Expr) && (length(_terms[i].args) > 2)
                #if there is an expression that contains x(t) like term, then parse it
                possible_const = check_all_const(_terms[i],[]) 
                #a differential variable or algebraic variable or independent variable is found in the inner term, then it is nonlinear
                for term in possible_const
                    if check_diff_alge(_model,term)
                        push!(type,:nonlinear)
                        #println(type," in ",_terms)
                        return type
                        
                    end
                end
        
            end
        end
    end

    return push!(type,:linear)
end

function check_all_const(_expr,all_terms)


    if !(_expr isa Expr) && !(_expr in [:+,:-,:*,:/,:^])
        return push!(all_terms,_expr)
    end

    #parse the term until it is a symbol, check if the symbol is a registered parameter or a number
    terms = _expr.args
    
    for term in terms
        if ((term isa Number) || (term isa Symbol)) && !(term in [:+,:-,:*,:/,:^])
            push!(all_terms,term)

        elseif term isa Expr
            for element in check_all_const(term,[])  
                push!(all_terms,element)
                
            end
        end
    end

    return all_terms
   
end

function check_two_sides(_model,_side,type)
    
    if (_side isa Expr) && (length(_side.args) >= 3) && (_side.args[1] in [:*,:/,:^])

        #check if at least two args are expression that has more than 2 args, record their positions
        exist = false
        pos = []
        for i in 2:length(_side.args)
            if (_side.args[i] isa Expr) && (length(_side.args[i].args) >= 3)
                exist = true
                push!(pos,i)
            end
        end

        if exist == true

            len = length(_side.args)
            _terms = _side.args
            check = []
            for i in pos
        
                possible_const = check_all_const(_terms[i],[]) 
                #check if a differential variable or algebraic variable or independent variable is found in the inner term
                for term in possible_const
                    if check_diff_alge(_model,term)
                        push!(check,i)
                        #println(check,"",_terms[i])
                        
                    end
                end
                
            end

            unique_elements = unique(check)
            (length(unique_elements) >= 2) ? push!(type,:nonlinear) : push!(type,:linear)
            return type
        end
 
        
    end
    push!(type,:linear)
    return type
end

function check_math_func(_model,_side,type)
    
    if (_side isa Expr) && (length(_side.args) == 2) && isconst(MathConstants,_side.args[1]) && !(_side.args[1] in [:+,:-,:*,:/,:^,:%])
        possible_const = check_all_const(_side.args[2],[])
        #a differential variable or algebraic variable or independent variable is found in the inner term, then it is nonlinear
        for term in possible_const
            if check_diff_alge(_model,term)
                push!(type,:nonlinear)
                #print_info(type,_side)
                return type
                
            end
        end

        push!(type,:linear)
        return type
    else

        len = length(_side.args)
        _terms = _side.args

        for i in 1:len
            if (_terms[i] isa Expr) && isconst(MathConstants,_terms[i].args[1]) && !(_terms[i].args[1] in [:+,:-,:*,:/,:^,:%])
                
                possible_const = check_all_const(_terms[i].args[2],[]) 
                #a differential variable or algebraic variable or independent variable is found in the inner term, then it is nonlinear
                for term in possible_const
                    if check_diff_alge(_model,term)
                        push!(type,:nonlinear)
                        #print_info(type,_terms)
                        return type
                        
                    end
                end
        
                push!(type,:linear)
                return type
            end
        end

    end
    push!(type,:linear)
end

function parse_and_separate(_model,true_terms,_side,type)
    container = copy(true_terms)

    separating_ops = [:*,:/,:+,:-,:^] 

    #if the side is a number, or a symbol, or a A(t) like term
    (_side isa Number) ? (return push!(container,_side),:linear) : nothing
    (_side isa Symbol) && !(_side in separating_ops) ? (return push!(container,_side),:linear) : nothing
    if (_side isa Expr) && (length(_side.args) == 2) 
        !(isconst(MathConstants,_side.args[1])) ? (return push!(container,_side),:linear) : nothing

        if (isconst(MathConstants,_side.args[1])) 
            possible_const = check_all_const(_side.args[2],[]) 
            #a differential variable or algebraic variable or independent variable is found in the inner term, then it is nonlinear
            for term in possible_const
                if check_diff_alge(_model,term)
                    push!(type,:nonlinear)
                    #no return?
                    
                end
            end
            (_side.args[2] isa Union{Symbol,Number}) ? (return push!(container,_side),:linear) : nothing
        end
    end

    !(:nonlinear in type) ? (type = check_math_func(_model,_side,type)) : nothing 

    !(:nonlinear in type) ? (type = check_division(_model,_side,type)) : nothing

    !(:nonlinear in type) ? (type = check_hat(_model,_side,type)) : nothing

    !(:nonlinear in type) ? (type = check_multiplication(_model,_side,type)) : nothing

    !(:nonlinear in type) ? (type = check_two_sides(_model,_side,type)) : nothing
    
    terms = _side.args 
    #println("terms",terms)

    for term in terms

        if  term isa Expr
 
            if (length(term.args) == 2) && !(isconst(MathConstants,term.args[1]))  

                push!(container,term) 
            else
                
                for element in parse_and_separate(_model,[],term,type)[1]
                    push!(container,element) 
                end

            end

        elseif term isa Symbol
            term in separating_ops ? nothing : push!(container,term)
        elseif term isa Number
            !(_side.args[1] in [:*,:\,:^]) ? push!(container,term) : nothing
        else
            throw(error("The expression is not a valid equation"))
        end
    
    end

    (:nonlinear in type) ? (return container,:nonlinear) : (return container,:linear)

end


function get_set( _type_of_equation, _operator,_vector)
    if _vector == false
        if _type_of_equation == :initial
            _operator == :(==) ? (return DOI.EqualToInitial) : nothing
            _operator == :(<=) ? (return DOI.NonpositiveForInitial) : (return DOI.NonnegativeForInitial)
            
        elseif _type_of_equation == :final
            _operator == :(==) ? (return DOI.EqualToFinal) : nothing
            _operator == :(<=) ? (return DOI.NonpositiveForFinal) : (return DOI.NonnegativeForFinal)
            
        elseif _type_of_equation == :trajectory
            _operator == :(==) ? (return DOI.ZeroForAll) : nothing
            _operator == :(<=) ? (return DOI.NonpositiveForAll) : (return DOI.NonnegativeForAll)
            
        end

    else
        if _type_of_equation == :initial
            _operator == :(==) ? (return DOI.EqualToInitials) : nothing
            _operator == :(<=) ? (return DOI.NonpositivesForInitial) : (return DOI.NonnegativesForInitial)

        elseif _type_of_equation == :final
            _operator == :(==) ? (return DOI.EqualToFinals) : nothing
            _operator == :(<=) ? (return DOI.NonpositivesForFinal) : (return DOI.NonnegativesForFinal)

        elseif _type_of_equation == :trajectory
            _operator == :(==) ? (return DOI.ZerosForAll) : nothing
            _operator == :(<=) ? (return DOI.NonpositivesForAll) : (return DOI.NonnegativesForAll)

        end

     end
end

function get_func(_vector,_linearity,_diff,_alge)
    if _vector == false
        if _linearity == :affine
            (_diff == true) && (_alge == true) ? (return DOI.ScalarAffineDifferentialAlgebraicFunction) : nothing
            (_diff == true) ? (return DOI.ScalarAffineDifferentialFunction) : nothing
            (_alge == true) ? (return DOI.ScalarAffineAlgebraicFunction) : nothing
        elseif _linearity == :nonlinear
            (_diff == true) && (_alge == true) ? (return DOI.ScalarNonlinearDifferentialAlgebraicFunction) : nothing
            (_diff == true) ? (return DOI.ScalarNonlinearDifferentialFunction) : nothing
            (_alge == true) ? (return DOI.ScalarNonlinearAlgebraicFunction) : nothing

        end

    else
        if _linearity == :affine
            (_diff == true) && (_alge == true) ? (return DOI.VectorAffineDifferentialAlgebraicFunction) : nothing
            (_diff == true) ? (return DOI.VectorAffineDifferentialFunction) : nothing
            (_alge == true) ? (return DOI.VectorAffineAlgebraicFunction) : nothing
        elseif _linearity == :nonlinear
            (_diff == true) && (_alge == true) ? (return DOI.VectorNonlinearDifferentialAlgebraicFunction) : nothing
            (_diff == true) ? (return DOI.VectorNonlinearDifferentialFunction) : nothing
            (_alge == true) ? (return DOI.VectorNonlinearAlgebraicFunction) : nothing

        end
    end
    
end

mutable struct ConstraintRef <: AbstractDynamicRef
    model::Abstract_Dynamic_Model
    index::DOI.DynamicConstraintIndex
end

function parse_equation(_model,_expr)

    check_constraint_name(_model,_expr[1])

    expr = _expr[2]

    head = expr.head
    operator = expr.args[1]

    #check the constraint is scalarized or vectorized, as well as the type of the constraint (initial, final, or trajectory)
    vectorized = false
    type = nothing
    diff = nothing
    alge = nothing
    independent_var = nothing

    l_terms = check_all_const(expr.args[2],[])
    r_terms = check_all_const(expr.args[3],[])
    [push!(l_terms,r_terms[i]) for i in eachindex(r_terms)]
    for i in l_terms
        if (vectorized == false) && (check_vector_constraint(_model,i) == true)
            vectorized = true
        end

        if i in collect_keys(_model.Differential_var_index)
            diff = true
        elseif i in collect_keys(_model.Algebraic_var_index)
            alge = true
        end 

        if i in collect(keys(_model.Initial_Independent_var_index))
            (type === nothing) ? (type = :initial) : nothing
            (type != :initial) ? throw(error("The expression is not a valid equation")) : nothing
            independent_var =collect(keys(_model.Initial_Independent_var_index))[1]
        elseif i in collect(keys(_model.Final_Independent_var_index))
            (type === nothing) ? (type = :final) : nothing
            (type != :final) ? throw(error("The expression is not a valid equation")) : nothing
            independent_var =collect(keys(_model.Final_Independent_var_index))[1]
        elseif i in collect(keys(_model.Independent_var_index))
            (type === nothing) ? (type = :trajectory) : nothing
            (type != :trajectory) ? throw(error("The expression is not a valid equation")) : nothing
            independent_var =collect(keys(_model.Independent_var_index))[1]
        end
    end
    (type === nothing) ? throw(error("The expression is not a valid equation")) : nothing

    
    

    if head == :call
        #for expressions with one operator
        (operator == :(==) || operator == :(<=) || operator == :(>=)) && length(expr.args) == 3 ? nothing : throw(error("The expression is not a valid equation"))

        _lhs_terms,typel = parse_and_separate(_model,[],expr.args[2],[])
        _rhs_terms,typer = parse_and_separate(_model,[],expr.args[3],[])

        (typel == :nonlinear || typer == :nonlinear) ? (func_type = :nonlinear) : (func_type = :affine)

        # merge the lhs and rhs terms 
        all_terms = Any[]
        [push!(all_terms,element) for element in _lhs_terms]
        [push!(all_terms,element) for element in _rhs_terms]
        println(_expr[1])
        doi_set = get_set(type,operator,vectorized)
        doi_func = get_func(vectorized,func_type,diff,alge)

        #currently only support one-sided constraints with all terms on the left-hand-side
        constraint_output = scalar_dynamics(_model,expr.args[2],independent_var)
        if type == :trajectory
            index = DOI.add_constraint(_model.optimizer.constraints,doi_func,doi_set,constraint_output) 
        else
            index = DOI.add_constraint(_model.optimizer.instant_constraints,doi_func,doi_set,constraint_output) 
        end
        

    elseif head == :comparison
        #for expressions with two operators
        
    else
        throw(error("The expression is not a valid equation"))
    end

    #filter out the Number type elements from the lhs_terms
    all_terms = filter(x -> !(x isa Number),unique(all_terms))

    _model.Constraints_index[_expr[1]] = _expr[2];

    return #all_terms
end