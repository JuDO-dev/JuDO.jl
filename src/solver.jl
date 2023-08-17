function optimize!(model::Dy_Model)
    DOI.Doptimize!(model.optimizer)
end

function set_meshpoints(model::Dy_Model, meshpoints::Int64)
    DOI.set_meshpoints(model.optimizer, meshpoints)
end