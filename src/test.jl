

macro my_variable(expr)

    sym = gensym()
    quote $sym = Expr(:call,10) end 

    quote $(esc(expr)) = $sym end

    return :(esc($expr))
end


