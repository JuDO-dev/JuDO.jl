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

#a function that checks if _args[i] is a vector of algebraic variables
function check_rhs_vect(_model,_args)
    if (_args.args[2] isa Number) && (_args.args[1].args[1] in collect_keys(_model.Algebraic_var_index)) && (_args.args[1].args[2] == collect(keys(_model.Independent_var_index))[1])
        println("vector algebraic")
        index = findfirst(x->x==_args.args[1].args[1],collect_keys(_model.Algebraic_var_index))
        return Expr(:ref,:u,_args.args[2] + index - 1)
    end
    throw(error("Incorrect style of the right hand side vectorized variable"))
end

#a function that checks if _args[i] is a number or symbol
function check_rhs_num(_model,_args)
    if (_args isa Symbol) && (_args in collect(keys(_model.Constant_index)))
        return _model.Constant_index[_args].Value
    elseif _args isa Number
        return _args
    elseif (_args isa Symbol) && (_args in [:+,:-,:*,:/,:^])
        return _args
    end
    
end

#a function that checks if _args[i] is a diff or alge variable
function check_rhs_var(_model,_args,_lhs_terms)
    if (_args.args[2] == collect(keys(_model.Independent_var_index))[1]) && (_args.args[1] in collect_keys(_model.Algebraic_var_index))
        index = findfirst(x->x==_args,collect(keys(_model.Algebraic_var_index)))
        return Expr(:ref,:u,index)

    elseif (_args.args[2] == collect(keys(_model.Independent_var_index))[1]) && (_args.args[1] in collect_keys(_model.Differential_var_index))
        index = findfirst(x->x==_args,collect(keys(_model.Differential_var_index)))
        return Expr(:ref,:x,index)

    end
    throw(error("Incorrect style of the right hand side variable"))
end

#iteratively parse the dynamics expression for scalar differential variables
function parse_dynamics_expression(_model,_lhs_terms,terms,operator)
    expressions = []

    for i in eachindex(terms)

        # a term like 1 or q
        if (terms[i] isa Symbol) || (terms[i] isa Number)
            push!(expressions,check_rhs_num(_model,terms[i]))

        elseif (terms[i].head == :ref) && (length(terms[i].args) == 2) && (length(terms[i].args[1].args) == 2)
            push!(expressions,check_rhs_vect(_model,terms[i]))

        # a term like x(t) or u(t)
        elseif (length(terms[i].args) == 2) && (terms[i].args[2] == collect(keys(_model.Independent_var_index))[1])
            push!(expressions,check_rhs_var(_model,terms[i],_lhs_terms))

        # a term including mathematical functions like sin() (to do: include mathematical functions with more than 1 argument like log(1,2))
        elseif (length(terms[i].args) == 2) && (terms[i].args[1] isa Symbol) && isconst(MathConstants,terms[i].args[1])
            if (terms[i].args[2] isa Symbol) || (terms[i].args[2] isa Number)
                println("here")
                push!(expressions,eval(Expr(:call,terms[i].args[1],check_rhs_num(_model,terms[i].args[2]))))
            
            elseif (length(terms[i].args[2].args) == 2) && (terms[i].args[2].args[2] == collect(keys(_model.Independent_var_index))[1])
                println("here0")
                push!(expressions,Expr(:call,terms[i].args[1],check_rhs_var(_model,terms[i].args[2],_lhs_terms)))

            else
                println("here1")
                push!(expressions,Expr(:call,terms[i].args[1],parse_dynamics_expression(_model,_lhs_terms,terms[i].args[2].args[2:end],terms[i].args[2].args[1])))
            end


        elseif (length(terms[i].args) > 2)
            println("here2")
            push!(expressions,parse_dynamics_expression(_model,_lhs_terms,terms[i].args[2:end],terms[i].args[1]))
        end
    end


    return Expr(:call, operator, expressions...)
end

function parse_dynamics(_model,_args)
    #each element in _args is an expression of equation
    type = :scalarized
    for i in eachindex(_args)
        if _args[i].args[2].head == :ref
            type = :vectorized
            break
        end
    end

    #parse the input mathematical expression into the form of the elements in sub
    sub = []
    lhs_terms = []
    for i in eachindex(_args)
        lhs = _args[i].args[2]
        push!(lhs_terms,check_lhs_scalar(_model,lhs))
    end
    
    if type == :scalarized
        for i in eachindex(_args)
            #each expression (_args[i]) must have the first argument as :(==), and the second as the derivative term
            rhs = _args[i].args[3]
            
            #create a function that checks if _args[i] is a number or symbol or x(t) like term
            if (rhs isa Symbol) || (rhs isa Number)
                push!(sub,check_rhs_num(_model,rhs))

            elseif (rhs.head == :ref) && (length(rhs.args) == 2) && (length(rhs.args[1].args) == 2)
                push!(sub,check_rhs_vect(_model,rhs))

            elseif (length(rhs.args) == 2) && (rhs.args[2] == collect(keys(_model.Independent_var_index))[1])    
                push!(sub,check_rhs_var(_model,rhs,lhs_terms)) #or x, add [n]
    
            elseif (length(rhs.args) == 2) && (terms[i].args[1] isa Symbol) && isconst(MathConstants,rhs.args[1])
                if (rhs.args[2] isa Symbol) || (rhs.args[2] isa Number)
                    push!(sub,eval(Expr(:call,rhs.args[1],check_rhs_num(_model,rhs.args[2]))))

                elseif (length(rhs.args[2].args) == 2) && (rhs.args[2].args[2] == collect(keys(_model.Independent_var_index))[1])
                    push!(sub,Expr(:call,rhs.args[1],check_rhs_var(_model,rhs.args[2],lhs_terms)))

                else
                    push!(sub,Expr(:call,rhs.args[1],parse_dynamics_expression(_model,lhs_terms,rhs.args[2].args[2:end],rhs.args[2].args[1])))
                end

            elseif (length(rhs.args) > 2)
                println("rhs is expr >2")
                push!(sub,parse_dynamics_expression(_model,lhs_terms,rhs.args[2:end],rhs.args[1]))
            end
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

    elseif type == :vectorized



    end

    
    
    #return D
    return DOI.add_dynamic(_model.optimizer, eval(D))
end 

