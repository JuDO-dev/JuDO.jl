function optimize!(model::Dy_Model)
    DOI.optimize!(model.optimizer)
end

function set_discretization(model::Dy_Model, discretized_points::Int64)

    DOI.set_discretization(model.optimizer, discretized_points)

    return nothing
end

function set_initial_guess(ref::DifferentialRef,val::Real)

    DOI.set_initial_guess(ref.model.optimizer.diff_variables,ref.index.value,val)

    return nothing
end

function set_initial_guess(ref::AlgebraicRef,val::Real)

    DOI.set_initial_guess(ref.model.optimizer.alge_variables,ref.index.value,val)
    
    return nothing
end

function set_cost_tol(model::Dy_Model; tol::Float64 = 1e-4, tol_m::Float64 = 1e-4)

    DOI.set_cost_tol(model.optimizer, tol, tol_m)
    
   return nothing 
end

function set_grad_tol(model::Dy_Model; tol::Float64 = 10.0, tol_m::Float64 = 1.0)

    DOI.set_grad_tol(model.optimizer, tol, tol_m)
    
   return nothing 
    
end

function set_penalty(model::Dy_Model; pen_scale::Float64 = 10.0, pen_init::Float64 = 1.0)

    DOI.set_penalty(model.optimizer, pen_scale, pen_init)
    
   return nothing 
    
end


function set_parametrization(ref::DifferentialRef, parametrization::Int64)

    DOI.set_parametrization(ref.model.optimizer.diff_variables,ref.index.value,parametrization)

    return nothing
     
end

function set_parametrization(ref::AlgebraicRef, parametrization::Int64)

    DOI.set_parametrization(ref.model.optimizer.alge_variables,ref.index.value,parametrization)

    return nothing
     
end

function set_continuity(ref::DifferentialRef, continuity::Bool)

    DOI.set_continuity(ref.model.optimizer.diff_variables,ref.index.value,continuity)

    return nothing
    
end

function set_continuity(ref::AlgebraicRef, continuity::Bool)

    DOI.set_continuity(ref.model.optimizer.alge_variables,ref.index.value,continuity)

    return nothing
    
end

function set_flex_mesh(model::Dy_Model, flex_mesh::Tuple{Real, Real})
    DOI.set_flex_mesh(model.optimizer, flex_mesh)
    return nothing
end

function set_residual_quad_order(model::Dy_Model, residual_quad_order::Int64)
    DOI.set_residual_quad_order(model.optimizer, residual_quad_order)
    return nothing
end

function set_hessian_approx(model::Dy_Model, hessian_approx::Bool)
    DOI.set_hessian_approx(model.optimizer, hessian_approx)
    return nothing
end