function set_dynamic_optimizer(model, optimizer)
    model.optimizer = optimizer()
    
end

function set_dynamic_optimizer_attribute(model, args::Pair)

    for (key,value) in args
        DOI.set_dynamic(model.optimizer, key, value)
    end
end

#= 
set_attribute(model, "presolve", "off")
set_attribute(model, "output_flag", false)
in attributes.jl 
https://github.com/jump-dev/MathOptInterface.jl/blob/dab02e5f2f9018c324bf251a46b41d4ccb86ac36/src/attributes.jl#L20
=#

