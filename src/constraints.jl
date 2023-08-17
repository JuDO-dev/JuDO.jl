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

function print_info(_type,_terms)
    #= println(_type," in ",_terms)
    println("check: ",_terms.args[1]) =#
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
                print_info(type,_terms)
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

    #parse the term until it is a symbol, check if the symbol is a registered constant or a number
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
                print_info(type,_side)
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
                        print_info(type,_terms)
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

function parse_and_separate(_model,true_terms,_side,sub,check_set,type)
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
                
                for element in parse_and_separate(_model,[],term,sub,check_set,type)[1]
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

#input a vector of unicode of the symbol, return the symbol without the dot operator
function detect_diff_alge(_model,_sym)

    isdefined(Base.Math,_sym) ? (return true) : nothing
    
    #get all the names of the registered differential variables
    diff_var_names = collect_keys(_model.Differential_var_index)
    diff_var_codes = []
    #store the unicode of all differential variables in diff_var_codes
    [push!(diff_var_codes,get_unicode(string(diff_var_names[i]))) for i in eachindex(diff_var_names)]

    alg_var_names = collect_keys(_model.Algebraic_var_index)
    alg_var_codes = []
    [push!(alg_var_codes,get_unicode(string(alg_var_names[i]))) for i in eachindex(alg_var_names)]

    #decompose input _sym into another string (in NFC sense), and store the unicode 
    target_code = get_normalized_unicode(string(_sym))

    if target_code[end] == 0x307
        #if a dot operator exists, then check if the symbol is a differential variable or an algebraic variable
        for i in eachindex(diff_var_codes)
            target_code[1:end-1] == diff_var_codes[i] ? (return true) : nothing
        end
        for i in eachindex(alg_var_codes)
            target_code[1:end-1] == alg_var_codes[i] ? (return true) : nothing
        end

    else
        #if no dot, then check if the symbol is an algebraic variable or a differential variable
        for i in eachindex(alg_var_codes)
            target_code == alg_var_codes[i] ? (return false) : nothing
        end
        for i in eachindex(diff_var_codes)
            target_code == diff_var_codes[i] ? (return false) : nothing
        end
    end


    throw(error("The symbol before the paranthesis of $_sym is not a valid, make sure it is a variable.\n If it is a derivative, make sure the dot is on top of a registered differential variable"))
end

function detect_const(_model,_sym)
    const_var_names = collect(keys(_model.Constant_index))

    _sym isa Number ? (return true) : nothing
    (isconst(MathConstants,_sym)==true) ? (return true) : nothing

    (_sym in const_var_names) ? (return true) : throw(error("The symbol $_sym without paranthesis is not a valid, make sure it is a registered constant.\nIf it is a variable, make sure it is followed by a paranthesis with independent variable inside"))
end

function call_trajectory(_model,_terms,_code_of_independent_var)
 
    verify = []
    len_of_independent_var = length(_code_of_independent_var) - 1

    for i in eachindex(_terms)
        if _terms[i] isa Expr
            check_term = get_unicode(string(_terms[i]))

            if (check_term[end] == 0x29) && (0x28 in check_term) && (check_term[end-1-len_of_independent_var:end-1] == _code_of_independent_var) 
                sym_with_paranthesis = _terms[i].args[1] 
                
                detect_diff_alge(_model,sym_with_paranthesis) == true ? nothing : push!(verify,sym_with_paranthesis) 
                
            elseif (check_term[end] == 0x29) && (0x28 in check_term) && (isconst(MathConstants,_terms[i].args[1]))
                sym_with_paranthesis = _terms[i].args[1] 

                (check_term[end-1-len_of_independent_var:end-1] == _code_of_independent_var) ? (return push!(verify,sym_with_paranthesis)) : nothing
                
                detect_const(_model,sym_with_paranthesis) ? push!(verify,sym_with_paranthesis) : nothing
            else
                throw(error("Invalid independent variable in the paranthesis"))
            end
            
        elseif _terms[i] isa Symbol
            detect_const(_model,_terms[i]) == true ? push!(verify,_terms[i]) : nothing
            
        end
    end
    #println("verify",verify)
end

function check_consistency(registered, input)

    registered != input ? throw(error("The input symbol $input is not consistent with the registered symbol $registered")) : nothing
    
end

function call_instantaneous(_model,_terms,_type_of_equation)
 
    verify = []
    for i in eachindex(_terms)
        if _terms[i] isa Expr
            check_term = get_unicode(string(_terms[i]))

            if (check_term[end] == 0x29) && (0x28 in check_term) && (findfirst(isequal(0x28), check_term) != 1)
                
                if _type_of_equation == :initial
                    check_consistency(collect(keys(_model.Initial_Independent_var_index))[1],_terms[i].args[2])

                elseif _type_of_equation == :final
                    check_consistency(collect(keys(_model.Final_Independent_var_index))[1],_terms[i].args[2])
                end 

                sym_with_paranthesis = _terms[i].args[1] 
                
                detect_diff_alge(_model,sym_with_paranthesis) == true ? nothing : push!(verify,sym_with_paranthesis)
            end
        elseif _terms[i] isa Symbol
            detect_const(_model,_terms[i])
        end
    end
    
    #println("verify",verify)
    #a constraint ref  
end

function get_set( _type_of_equation, _operator)
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
     
end

function _doi_add_constraint(_model,_terms,_func_type,_set)

    diff = []
    alge = []
    aff = []
    lin = []
    for i in _terms

        if i isa Expr
            unicode = get_normalized_unicode(string(i.args[1]))

            if i.args[1] in collect_keys(_model.Differential_var_index)
                push!(diff,true)
            elseif i.args[1] in collect_keys(_model.Algebraic_var_index)
                push!(alge,true)

            elseif unicode[end] == 0x307
                for i in collect_keys(_model.Differential_var_index)
                    if unicode[1:end-1] == get_normalized_unicode(string(i))
                        push!(diff,true)
                    end
                end
                for i in collect_keys(_model.Algebraic_var_index)
                    if unicode[1:end-1] == get_normalized_unicode(string(i))
                        push!(alge,true)
                    end
                end
            else
                push!(lin,true)
            end

        elseif i isa Symbol
            if (i in collect(keys(_model.Constant_index))) || (i isa Number)
                push!(aff,true)
            else
                push!(lin,true)
            end
            
        end
    end

    if _func_type == (:linear)
        println("linear   ",_set)
    elseif _func_type == (:nonlinear)
        (true in diff) && (true in alge) ? (println(DOI.ScalarNonlinearDifferentialAlgebraicFunction,"   ",_set); return) : nothing
        (true in diff) ? (println(DOI.ScalarNonlinearDifferentialFunction,"   ",_set); return) : nothing
        (true in alge) ? (println(DOI.ScalarNonlinearAlgebraicFunction,"   ",_set); return) : nothing

    end
end

function parse_equation(_model,_expr)

    check_constraint_name(_model,_expr[1])

    expr = _expr[2]
    type = _expr[3]

    head = expr.head
    operator = expr.args[1]

    #Uint 8 code of independent variable
    code_of_independent_var = get_unicode(string(collect(keys(_model.Independent_var_index))[1]))

    if head == :call
        #for expressions with one operator
        (operator == :(==) || operator == :(<=) || operator == :(>=)) && length(expr.args) == 3 ? nothing : throw(error("The expression is not a valid equation"))

        _lhs_terms,typel = parse_and_separate(_model,[],expr.args[2],nothing,[],[])
        _rhs_terms,typer = parse_and_separate(_model,[],expr.args[3],nothing,[],[])

        (typel == :nonlinear || typer == :nonlinear) ? (func_type = :nonlinear) : (func_type = :linear)

        # merge the lhs and rhs terms 
        all_terms = Any[]
        [push!(all_terms,element) for element in _lhs_terms]
        [push!(all_terms,element) for element in _rhs_terms]
        

        #println("all_terms",all_terms) 

        type == :initial || type == :final ? call_instantaneous(_model,unique(all_terms),type) : call_trajectory(_model,unique(all_terms),code_of_independent_var)

        doi_set = get_set(type,operator)
        println(_expr[1])
        _doi_add_constraint(_model,unique(all_terms),func_type,doi_set) 

    elseif head == :comparison
        #for expressions with two operators
        (operator == :(<=) || operator == :(>=)) && length(expr.args) == 5 ? nothing : throw(error("The expression is not a valid equation"))
        
        _lhs_terms,type = parse_and_separate(_model,[],expr.args[1],nothing,[],[])
        _center_terms,type = parse_and_separate(_model,[],expr.args[3],nothing,[],[])
        _rhs_terms,type = parse_and_separate(_model,[],expr.args[5],nothing,[],[])
 
        all_terms = Any[]
        [push!(all_terms,element) for element in _lhs_terms]
        [push!(all_terms,element) for element in _center_terms]
        [push!(all_terms,element) for element in _rhs_terms]
        

        println("all_terms",all_terms) 

        type == :initial || type == :final ? call_instantaneous(_model,unique(all_terms),type) : call_trajectory(_model,unique(all_terms),code_of_independent_var)

    else
        throw(error("The expression is not a valid equation"))
    end

    #filter out the Number type elements from the lhs_terms
    all_terms = filter(x -> !(x isa Number),unique(all_terms))

    constraint_func = Constraint_data(_expr[2])
    _model.Constraints_index[_expr[1]] = constraint_func

    return all_terms
end