function optimize!(model::Dy_Model)
    DOI.Doptimize!(model.optimizer)
end

function set_meshpoints(model::Dy_Model, meshpoints::Int64)
    DOI.set_meshpoints(model.optimizer, meshpoints)
end

function set_initial_guess(var, value)
    DOI.set_initial_guess(var, value)
end

function set_diff_discretization(var, discretization)
    DOI.set_diff_discretization(var, discretization)
    
end

function set_alge_discretization(var, discretization)
    DOI.set_alge_discretization(var, discretization)
end

function set_parametrization(var, parametrization)
    DOI.set_parametrization(var, parametrization)
     
end

function set_continuity(var, continuity)
    DOI.set_continuity(var, continuity)
end

function set_flex_mesh(model, flex_mesh)
    DOI.set_flex_mesh(model.optimizer, flex_mesh)
end

function set_residual_quad_order(model, residual_quad_order)
    DOI.set_residual_quad_order(model.optimizer, residual_quad_order)
end

function set_hessian_approx(model, hessian_approx)
    DOI.set_hessian_approx(model.optimizer, hessian_approx)
    
end