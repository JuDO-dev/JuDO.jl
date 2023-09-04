#check and store the lhs differential variable
function check_lhs_scalar(_model,_args)
    if (_args.args[2] == collect(keys(_model.Independent_var_index))[1])

        unicode = get_normalized_unicode(string(_args.args[1]))
        for i in collect_keys(_model.Differential_var_index)
            if unicode[1:end-1] == get_normalized_unicode(string(i))
                return findfirst(x->x==i,collect_keys(_model.Differential_var_index))
            end
        end
    end
    throw(error("The left hand side of the scalar dynamics must be a differential variable"))
end

#check and store the lhs differential vector
function check_lhs_vector(_model,_args)
    if (_args.args[1].args[2] == collect(keys(_model.Independent_var_index))[1])
        sym = _args.args[1].args[1]
        unicode = get_normalized_unicode(string(sym))

        for i in collect_keys(_model.Differential_var_index)
            if unicode[1:end-1] == get_normalized_unicode(string(i))
                #deal with ẋ(t)[1:3] and ẋ(t)[1] case
                (_args.args[2] isa Expr) ? (return _args.args[2].args[2]) : (return _args.args[2])
            end
        end
    end
    throw(error("The left hand side of the vector dynamics must be a differential variable"))
end

#a function that checks if _args[i] is a vector of algebraic variables
function check_rhs_vect(_model,_args,independent)
    #check single element in vectorized algebraic variable uu(t)[1]
    if (_args.args[2] isa Number) && (_args.args[1].args[1] in collect_keys(_model.Algebraic_var_index)) && (_args.args[1].args[2] == independent)
        #println("vector algebraic")
        index = findfirst(x->x==_args.args[1].args[1],collect_keys(_model.Algebraic_var_index))
        return Expr(:ref,:u,_args.args[2] + index - 1)

    #check single element in vectorized differential variable xx(t)[1]
    elseif (_args.args[2] isa Number) && (_args.args[1].args[1] in collect_keys(_model.Differential_var_index)) && (_args.args[1].args[2] == independent)
        #println("vector differential")
        index = findfirst(x->x==_args.args[1].args[1],collect_keys(_model.Differential_var_index))
        return Expr(:ref,:x,_args.args[2] + index - 1)

    #check partial vectorized algebraic variable uu(t)[1:3]
    elseif (_args.args[2] isa Expr) && (_args.args[1].args[1] in collect_keys(_model.Algebraic_var_index)) && (_args.args[1].args[2] == independent)
        
        index = findfirst(x->x==_args.args[1].args[1],collect_keys(_model.Algebraic_var_index))
        if index > 1
            prev = 0
            for i in 1:index-1
                var = _model.Algebraic_var_index[collect(keys(_model.Algebraic_var_index))[i]]
                (var isa Vector) ? (prev += length(var)) : (prev += 1)
            end
            first = _args.args[2].args[2]
            last = _args.args[2].args[3]

            return Expr(:ref,:u, Expr(:call,:(:), first + prev, last + prev))

        else
            first = _args.args[2].args[2]
            last = _args.args[2].args[3]

            return Expr(:ref,:u, Expr(:call,:(:), first + index - 1, last + index - 1))
        end
    #check partial vectorized differential variable xx(t)[1:3]
    elseif (_args.args[2] isa Expr) && (_args.args[1].args[1] in collect_keys(_model.Differential_var_index)) && (_args.args[1].args[2] == independent)
        
        index = findfirst(x->x==_args.args[1].args[1],collect_keys(_model.Differential_var_index))
        if index > 1
            prev = 0
            for i in 1:index-1
                var = _model.Differential_var_index[collect(keys(_model.Differential_var_index))[i]]
                (var isa Vector) ? (prev += length(var)) : (prev += 1)
            end
            first = _args.args[2].args[2]
            last = _args.args[2].args[3]

            return Expr(:ref,:x, Expr(:call,:(:), first + prev, last + prev))

        else
            first = _args.args[2].args[2]
            last = _args.args[2].args[3]

            return Expr(:ref,:x, Expr(:call,:(:), first + index - 1, last + index - 1))
        end

    end
    throw(error("Incorrect style of the right hand side vectorized variable"))
end

#a function that checks if _args[i] is a number or symbol
function check_rhs_num(_model,_args)
    if (_args isa Symbol) 
        (_args in collect(keys(_model.Constant_index))) ? (return _model.Constant_index[_args].Value) : nothing
        (_args in [:+,:-,:*,:/,:^,:\,:∫]) ? (return _args) : nothing
        (isconst(MathConstants,_args)) ? (return eval(_args)) : nothing
        (mathematical_packages_functions(_args)) ? (return _args) : nothing

        if (length(collect(keys(_model.Initial_Independent_var_index))) != 0) && (_args == collect(keys(_model.Initial_Independent_var_index))[1])
            return _model.Independent_var_index.vals[1].Bound[1]
        elseif (length(collect(keys(_model.Final_Independent_var_index))) != 0) && (_args == collect(keys(_model.Final_Independent_var_index))[1])
            return _model.Independent_var_index.vals[1].Bound[2]
        end 

    elseif _args isa Number
        return _args

    end
    
end

#a function that checks if the expression is length 2 
function direct_expressions(_model,_expr,sym)
    if !(_expr isa Expr) || (length(_expr.args) == 2)
        return scalar_dynamics(_model,_expr,sym)
    elseif length(_expr.args) > 2
        return parse_dynamics_expression(_model,_expr.args[2:end],_expr.args[1],sym)
    end 
end

function check_num_sym_var(_model,_args)
    
end

##############################################################################################################

#a function used to parse a pure vector or matrix
function vector_dynamics(_model,_head,terms,sym)
    subs = []
    if all(expr -> (expr isa Expr) && (expr.head == :row), terms.args)
        # it is a matrix
        #println("f-matrix")
        rows = []
        for i in eachindex(terms.args)
            for j in eachindex(terms.args[i].args)
                push!(subs,direct_expressions(_model,terms.args[i].args[j],sym))
            end
            push!(rows,Expr(:row,subs...))
            subs = []
        end

        return Expr(:vcat,rows...)
    
    else
        #println("f-vector")
        for j in eachindex(terms.args)
            push!(subs,direct_expressions(_model,terms.args[j],sym))
        end
        return Expr(_head,subs...)
    end
end

#a function that checks if _args[i] is a diff or alge variable
function check_rhs_var(_model,_args,independent)
    if (_args.args[2] == independent) && (_args.args[1] in collect_keys(_model.Algebraic_var_index))
        index = findfirst(x->x==_args.args[1],collect_keys(_model.Algebraic_var_index))

        if _model.Algebraic_var_index[collect(keys(_model.Algebraic_var_index))[index]] isa Vector
            prev = 0
            for i in 1:index-1
                var = _model.Algebraic_var_index[collect(keys(_model.Algebraic_var_index))[i]]
                (var isa Vector) ? (prev += length(var)) : (prev += 1)
            end
            return Expr(:ref,:u,Expr(:call,:(:),prev+1,prev+length(_model.Algebraic_var_index[collect(keys(_model.Algebraic_var_index))[index]])))
        else
            return Expr(:ref,:u,index)
        end

    elseif (_args.args[2] == independent) && (_args.args[1] in collect_keys(_model.Differential_var_index))
        index = findfirst(x->x==_args.args[1],collect_keys(_model.Differential_var_index))

        if (_model.Differential_var_index[collect(keys(_model.Differential_var_index))[index]] isa Vector)
            prev = 0
            for i in 1:index-1
                var = _model.Differential_var_index[collect(keys(_model.Differential_var_index))[i]]
                (var isa Vector) ? (prev += length(var)) : (prev += 1)
            end
            return Expr(:ref,:x,Expr(:call,:(:),prev+1,prev+length(_model.Differential_var_index[collect(keys(_model.Differential_var_index))[index]])))
        else
            return Expr(:ref,:x,index)
        end
    end
    throw(error("Incorrect style of the right hand side variable"))
end

#iteratively parse the dynamics expression for scalar differential variables
function parse_dynamics_expression(_model,terms,operator,sym)
    expressions = []

    for i in eachindex(terms)
        #print(i,"  ",terms[i])
        #bottom level
        if (terms[i] isa Symbol) || (terms[i] isa Number)
            push!(expressions,check_rhs_num(_model,terms[i]))

        elseif (terms[i].head == :ref) && (length(terms[i].args) == 2) && (length(terms[i].args[1].args) == 2)
            push!(expressions,check_rhs_vect(_model,terms[i],sym))

        elseif (length(terms[i].args) == 2) && (terms[i].args[2] == sym)
            push!(expressions,check_rhs_var(_model,terms[i],sym))

        elseif (terms[i].head in [:vect,:vcat,:hcat,Symbol("'")])
            #println("in vector")
           
            if terms[i].head == Symbol("'")
                #head = terms[i].args[1].head
                push!(expressions,Expr(Symbol("'"), scalar_dynamics(_model,terms[i].args[1],sym)))
            else
                push!(expressions,vector_dynamics(_model,terms[i].head,terms[i],sym))
            end

        #upper level
        elseif length(terms[i].args) >= 2
            #println("here2")
            push!(expressions,parse_dynamics_expression(_model,terms[i].args[2:end],terms[i].args[1],sym))

        end
    end

    #println(Expr(:call, operator, expressions...))
    return Expr(:call, operator, expressions...)
end

#a function used to parse a scalar term (on rhs or inside a vector)
function scalar_dynamics(_model,_args,sym)
    #lower level: number, symbol, x(t), x(t)[m:n], [1,2,...]
    if (_args isa Symbol) || (_args isa Number)
        sub = check_rhs_num(_model,_args)

    elseif (_args.head == :ref) && (length(_args.args) == 2) && (length(_args.args[1].args) == 2)
        sub = check_rhs_vect(_model,_args,sym)

    elseif (length(_args.args) == 2) && (_args.args[2] == sym)    
        sub = check_rhs_var(_model,_args,sym) 

    elseif (length(_args.args) == 2) && (_args.head in [:vect,:vcat,:hcat,Symbol("'")]) 
        #deal with [1,2]' or [1,2]/ [1 2]' or [1 2]/ [1;2]'or [1;2]
        if _args.head == Symbol("'")
            #head = _args.args[1].head
            sub = Expr(Symbol("'"),scalar_dynamics(_model,_args.args[1],sym))
        else
            sub = vector_dynamics(_model,_args.head,_args,sym)
        end

        #upper level: ...+..., ...*... / -(...), sin(...), log(...)
#=     elseif (_args.args[1] isa Symbol) && isconst(MathConstants,_args.args[1]) && !(_args.args[1] in [:+,:-,:*,:/,:^,:\,:∫])
        if length(_args.args) == 2
            return Expr(:call,_args.args[1],scalar_dynamics(_model,_args.args[2],sym))
        else
            subs = []
            [push!(subs,scalar_dynamics(_model,_args.args[i],sym)) for i in 2:length(_args.args)]
            return Expr(:call,_args.args[1],subs...)
        end =#

    elseif length(_args.args) >= 2
        return parse_dynamics_expression(_model,_args.args[2:end],_args.args[1],sym)

    end

    return sub
end

function parse_dynamics(_model,_args)
    #each element in _args is an expression of equation
    type = :scalarized
    for i in eachindex(_args)

        if _args[i].args[2].head == :ref
            target_code = get_normalized_unicode(string(_args[i].args[2].args[1].args[1]))
        elseif length(_args[i].args[2].args) == 2
            target_code = get_normalized_unicode(string(_args[i].args[2].args[1]))
        else
            throw(error("Incorrect style of the left hand side of the dynamics"))
        end

        (target_code[end] == 0x307) ? nothing : throw(error("Dot operator not recognized"))

        diff_var_names = collect_keys(_model.Differential_var_index)
        diff_var_codes = []
        #store the unicode of all differential variables in diff_var_codes
        [push!(diff_var_codes,get_unicode(string(diff_var_names[i]))) for i in eachindex(diff_var_names)]

        for i in eachindex(diff_var_codes)
            if target_code[1:end-1] == diff_var_codes[i] 
                key = collect(keys(_model.Differential_var_index))[i]
                (_model.Differential_var_index[key] isa Vector) ? (type = :vectorized) : nothing
            end
        end

    end
    
    #parse the input mathematical expression into the form of the elements in sub
    lhs_terms = []
    if type == :scalarized

        for i in eachindex(_args)
            lhs = _args[i].args[2]
            push!(lhs_terms,check_lhs_scalar(_model,lhs))
        end
        
        sub = []
        for i in eachindex(_args)
            #each expression (_args[i]) must have the first argument as :(==), and the second as the derivative term
            rhs = _args[i].args[3]
            push!(sub,scalar_dynamics(_model,rhs,collect(keys(_model.Independent_var_index))[1]))

        end

        ordered = []
        for i in lhs_terms
            push!(ordered,sub[i])
        end

        #the head of each expression is all :(=), the first arg is :ẋ (the diff variable vector)
        #the second args is modified from the user's input
        #sub = [Expr(:(=), :x, Expr(:call, :+, :u, 1)),Expr(:(=), :y, Expr(:call, :+, :x, 2))]
        D = Expr(:block, 
        Expr(:function, 
            Expr(:call, :t3, :model, :x, :u), 
            Expr(:block, Expr(:(=), :ẋ, Expr(:vect,ordered...))),
            Expr(:return , :ẋ)
            ))


    ### vectorized differential variable on the left hand side
    elseif type == :vectorized
        for i in eachindex(_args)
            lhs = _args[i].args[2]
            push!(lhs_terms,check_lhs_vector(_model,lhs))
        end

        sub = []
        for i in eachindex(_args)
            #each expression (_args[i]) must have the first argument as :(==), and the second as the derivative term
            rhs = _args[i].args[3]
            
            #bottom level
            if (rhs isa Symbol) || (rhs isa Number)
                push!(sub,check_rhs_num(_model,rhs))

            elseif (rhs.head == :ref) && (length(rhs.args) == 2) && (length(rhs.args[1].args) == 2)
                push!(sub,check_rhs_vect(_model,rhs,collect(keys(_model.Independent_var_index))[1]))

            elseif (length(rhs.args) == 2) && (rhs.args[2] == collect(keys(_model.Independent_var_index))[1])   #need?
                push!(sub,check_rhs_var(_model,rhs,collect(keys(_model.Independent_var_index))[1])) 

            elseif (rhs.head in [:vect,:vcat,:hcat,Symbol("'")]) 
                #deal with [1,2]' or [1,2]/ [1 2]' or [1 2]/ [1;2]'or [1;2]
                if rhs.head == Symbol("'")
                    #head = rhs.args[1].head
                    push!(sub,Expr(Symbol("'"),scalar_dynamics(_model,rhs.args[1],collect(keys(_model.Independent_var_index))[1])))
                else
                    push!(sub,vector_dynamics(_model,rhs.head,rhs,collect(keys(_model.Independent_var_index))[1]))
                end
    
            #upper level
            elseif length(rhs.args) >= 2
                push!(sub,parse_dynamics_expression(_model,rhs.args[2:end],rhs.args[1],collect(keys(_model.Independent_var_index))[1]))

            end

            
        end

        ordered = []
        for i in sortperm(lhs_terms)
            push!(ordered,sub[i])
        end

        #each element in sub is now a vector, hence ordered is now a collection of vectors, 

        D = Expr(:block, 
        Expr(:function, 
            Expr(:call, :altro_dynamic, :model, :x, :u), 
            Expr(:block, Expr(:(=), :ẋ, Expr(:vect,ordered...))),
            Expr(:return , :ẋ)
            ))
        
    end

    
    #return D
    #return ordered
    DOI.add_dynamics(_model.optimizer, ordered)
    push!(_model.Dynamics_index,_args);
    return 
end 