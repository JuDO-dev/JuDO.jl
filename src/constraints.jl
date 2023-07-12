function get_unicode(string)
    return [codepoint(i) for i in string]
end

function get_normalized_unicode(string)
    decomposed = Unicode.normalize(string, decompose = true)
    return [codepoint(i) for i in decomposed]
end

function check_var_in_paranthesis(_code_of_independent_var,_check_term)
    len_of_independent_var = length(_code_of_independent_var) - 1

    if (_check_term[end] == 0x29) && (0x28 in _check_term) && (_check_term[end-1-len_of_independent_var:end-1] == _code_of_independent_var) 
        
        return true
    else
        throw(error("Invalid independent variable in the paranthesis"))
    end

    throw(error("Ambiguous or Incorrect use of parentheses,\nI cannot tell if it is a () for multiplication or a () for indicating a variable with respect to the independent variable"))
    
end

#deal with the situation when the lhs or rhs is a number, or a single symbol, or a A(t) like term
function initial_parse(_side,container,_code_of_independent_var,_type_of_equation)

    (_side isa Number) ? (return _side) : nothing
    
    if _side isa Symbol 
        return push!(container,_side)

    elseif (_side isa Expr) && (length(_side.args) == 2) 

        check_term = get_unicode(string(_side))
        
        if _type_of_equation == :initial || _type_of_equation == :final
            (check_term[end] == 0x29) && (0x28 in check_term) && (findfirst(isequal(0x28), check_term) != 1) ? (return push!(container,_side)) : nothing

        else
            check_var_in_paranthesis(_code_of_independent_var,check_term) ? (return push!(container,_side)) : nothing
        end
    end
end

function parse_and_separate(_model,true_terms,_side,_code_of_independent_var,_type_of_equation)
    container = copy(true_terms)

    separating_ops = [:*,:/,:+,:-,:^] 
    
    (_side isa Number) ? (return _side) : nothing
    
    #parse -- check if separating_ops exist and exclude -- check if each term is an expression or a symbol -- if symbol then store, if expression then parse again
    terms = _side.args 
 
    for term in terms
        if  term isa Expr

            #check if this Expr is actually a A(t) like term
            check_term = get_unicode(string(term))
            
            ##check if the terms is a x(t)^T*Q*x(t) like term

            if _type_of_equation == :initial || _type_of_equation == :final
                (length(term.args) == 2) && (check_term[end] == 0x29) && (0x28 in check_term) && (findfirst(isequal(0x28), check_term) != 1) ? push!(container,term) : [push!(container,element) for element in parse_and_separate(_model,[],term,_code_of_independent_var,_type_of_equation)]
            else
                (length(term.args) == 2) && check_var_in_paranthesis(_code_of_independent_var,check_term) ? push!(container,term) : [push!(container,element) for element in parse_and_separate(_model,[],term,_code_of_independent_var,_type_of_equation)]
            end
         

        elseif term isa Symbol
            #store 
            term in separating_ops ? nothing : push!(container,term)
        else
            term isa Number ? nothing : throw(error("The expression is not a valid equation"))
        end

        ##check if the term is a "derivative" or a "differential variable" or a "algebraic variable" or a "constant"
    
    end
    
    return container
end

#input a vector of unicode of the symbol, return the symbol without the dot operator
function detect_diff_alge(_model,_sym,_type_of_equation)

    isdefined(Base.Math,_sym) ? (return true) : nothing
    
    #get all the names of the registered differential variables
    diff_var_names = collect(keys(_model.Differential_var_index))
    diff_var_codes = []
    #store the unicode of all differential variables in diff_var_codes
    [push!(diff_var_codes,get_unicode(string(diff_var_names[i]))) for i in eachindex(diff_var_names)]

    #get all the names of the registered algebraic variables
    alg_var_names = collect(keys(_model.Algebraic_var_index))
    alg_var_codes = []
    [push!(alg_var_codes,get_unicode(string(alg_var_names[i]))) for i in eachindex(alg_var_names)]

    #decompose input _sym into another string (in NFC sense), and store the unicode 
    target_code = get_normalized_unicode(string(_sym))

    if target_code[end] == 0x307
        #if a dot operator exists, then check if the symbol is a differential variable
        for i in eachindex(diff_var_codes)
            target_code[1:end-1] == diff_var_codes[i] ? (return true) : nothing

        end
    else
        #if not, then check if the symbol is an algebraic variable or a differential variable
        for i in eachindex(alg_var_codes)
            target_code == alg_var_codes[i] ? (return nothing) : nothing
        end
        for i in eachindex(diff_var_codes)
            target_code == diff_var_codes[i] ? (return nothing) : nothing
        end
    end


    throw(error("The symbol before the paranthesis of $_sym is not a valid, make sure it is a variable.\n If it is a derivative, make sure the dot is on top of a registered differential variable"))
end

function detect_const(_model,_sym)
    const_var_names = collect(keys(_model.Constant_index))

    (isconst(MathConstants,_sym)==true) ? (return false) : nothing

    (_sym in const_var_names) ? (return true) : throw(error("The symbol $_sym without paranthesis is not a valid, make sure it is a registered constant.\nIf it is a variable, make sure it is followed by a paranthesis with independent variable inside"))
end

function collect_keys(_model)
    # collect all the keys of Differential_var_index, Independent_var_index, Constant_index, Algebraic_var_index if they exist
    all_keys = [collect(keys(_model.Differential_var_index)), collect(keys(_model.Independent_var_index)), 
    collect(keys(_model.Algebraic_var_index)), collect(keys(_model.Constant_index))]

    variable_keys = [collect(keys(_model.Differential_var_index)), collect(keys(_model.Algebraic_var_index))]

    vect_keys=[]
    for i in eachindex(all_keys)
        [push!(vect_keys,element) for element in all_keys[i] if length(all_keys[i]) != 0]
    end

    return vect_keys,variable_keys
end

function call_trajectory(_model,_terms,_code_of_independent_var,_type_of_equation)
 
    verify = []
    len_of_independent_var = length(_code_of_independent_var) - 1

    for i in eachindex(_terms)
        if _terms[i] isa Expr
            check_term = get_unicode(string(_terms[i]))

            if (check_term[end] == 0x29) && (0x28 in check_term) && (check_term[end-1-len_of_independent_var:end-1] == _code_of_independent_var) 
                sym_with_paranthesis = _terms[i].args[1] 
                
                detect_diff_alge(_model,sym_with_paranthesis,_type_of_equation) == true ? nothing : push!(verify,sym_with_paranthesis) 
                
            else
                @warn("Potential error in the parsing function")
            end
            
        elseif _terms[i] isa Symbol
            detect_const(_model,_terms[i]) == true ? push!(verify,_terms[i]) : nothing
            
        end
    end

    vect_keys,variable_keys = collect_keys(_model)
    [(verify[i] in vect_keys) || (verify[i] isa Number) ? nothing : @warn("The input symbol $(verify[i]) is not yet registered") for i in eachindex(verify)]

end

function check_consistency(registered, input)

    registered != input ? throw(error("The input symbol $input is not consistent with the registered symbol $registered")) : nothing
    
end

function call_instantaneous(_model,_terms,_code_of_independent_var,_type_of_equation)
 
    verify = []
    for i in eachindex(_terms)
        if _terms[i] isa Expr
            check_term = get_unicode(string(_terms[i]))

            if (check_term[end] == 0x29) && (0x28 in check_term) && (findfirst(isequal(0x28), check_term) != 1)
                ([check_term[end-1]] == _code_of_independent_var) ? nothing : @info("Symbol $(_terms[i].args[2]) used in $_type_of_equation condition differs with $(collect(keys(_model.Independent_var_index))[1]), make sure the consistency of the independent variable in $_type_of_equation condition")
                
                if _type_of_equation == :initial
                    _model.Initial_sym === nothing ? (_model.Initial_sym = _terms[i].args[2]) : check_consistency(_model.Initial_sym,_terms[i].args[2])

                elseif _type_of_equation == :final
                    _model.Final_sym === nothing ? (_model.Final_sym = _terms[i].args[2]) : check_consistency(_model.Final_sym,_terms[i].args[2])
                end

                sym_with_paranthesis = _terms[i].args[1] 
                
                detect_diff_alge(_model,sym_with_paranthesis,_type_of_equation) == true ? nothing : push!(verify,sym_with_paranthesis)
            end
        elseif _terms[i] isa Symbol
            detect_const(_model,_terms[i]) == true ? push!(verify,_terms[i]) : nothing
        end
    end
    
    vect_keys,variable_keys = collect_keys(_model)

    [(verify[i] in vect_keys) || (verify[i] isa Number) ? nothing : @warn("The input symbol $(verify[i]) is not yet registered") for i in eachindex(verify)]
    

    #a constraint ref  
end

function parse_equation(_model,_expr)
    expr = _expr[2]
    type = _expr[3]

    head = expr.head
    operator = expr.args[1]

    #Uint 8 code of independent variable
    code_of_independent_var = get_unicode(string(collect(keys(_model.Independent_var_index))[1]))

    if head == :call
        #for expressions with one operator
        (operator == :(==) || operator == :(<=) || operator == :(>=)) && length(expr.args) == 3 ? nothing : throw(error("The expression is not a valid equation"))

        _lhs_terms = initial_parse(expr.args[2],[],code_of_independent_var,type)
        _lhs_terms === nothing ? (_lhs_terms = parse_and_separate(_model,[],expr.args[2],code_of_independent_var,type)) : nothing

        _rhs_terms = initial_parse(expr.args[3],[],code_of_independent_var,type)
        _rhs_terms === nothing ? (_rhs_terms = parse_and_separate(_model,[],expr.args[3],code_of_independent_var,type)) : nothing

        # merge the lhs and rhs terms 
        all_terms = Any[]
        [push!(all_terms,element) for element in _lhs_terms]
        [push!(all_terms,element) for element in _rhs_terms]

        println("all_terms",all_terms) 

        type == :initial || type == :final ? call_instantaneous(_model,unique(all_terms),code_of_independent_var,type) : call_trajectory(_model,unique(all_terms),code_of_independent_var,type)

    elseif head == :comparison
        #for expressions with two operators
        (operator == :(<=) || operator == :(>=)) && length(expr.args) == 5 ? nothing : throw(error("The expression is not a valid equation"))
        #parse_and_separate(_model,expr)
    else
        throw(error("The expression is not a valid equation"))
    end

    #filter out the Number type elements from the lhs_terms
    all_terms = filter(x -> !(x isa Number),all_terms)

    constraint_func = Constraint_data(_expr[2])
    _model.Constraints_index[_expr[1]] = constraint_func

    return all_terms
end

