function optimize!(model::Dy_Model)
    DOI.Doptimize!(model.optimizer)
end

function set_discretization(model::Dy_Model, discretized_points::Int64)
    DOI.set_discretization(model.optimizer, discretized_points)
end

function set_initial_guess(var, value)
    DOI.set_initial_guess(var, value)
end

function set_discretization(model::Dy_Model, discretized_points)
    DOI.set_discretization(model.optimizer, discretized_points)
    
end

function set_parametrization(var, parametrization)
    DOI.set_parametrization(var, parametrization)
     
end

function set_continuity(var, continuity)
    DOI.set_continuity(var, continuity)
end

function set_flex_mesh(model::Dy_Model, flex_mesh::Bool)
    DOI.set_flex_mesh(model.optimizer, flex_mesh)
end

function set_residual_quad_order(model, residual_quad_order)
    DOI.set_residual_quad_order(model.optimizer, residual_quad_order)
end

function set_hessian_approx(model, hessian_approx)
    DOI.set_hessian_approx(model.optimizer, hessian_approx)
    
end