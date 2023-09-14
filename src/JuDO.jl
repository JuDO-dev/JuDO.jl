module JuDO

import JuMP
import MathOptInterface as MOI
import DynOptInterface as DOI

import Base.Meta: isexpr

using Ipopt
using Unicode
using OrderedCollections: OrderedDict
using LinearAlgebra
using StaticArrays

abstract type variable_data end

"""
    Differential_Var_data

    A DataType for storing a collection of differential variables
"""
mutable struct Differential_Var_data <: variable_data
    Run_sym::Union{Expr,Nothing}

    Initial_bound::Vector 
    Initial_value::Union{Real,Nothing}
    Final_bound::Vector
    Final_value::Union{Real,Nothing}
    Trajectory_bound::Vector
    
end

"""
    Independent_Var_data

    A DataType for storing a collection of independent variables (currently for free/fixed time case)
        # free/fixed start/end problem
"""
mutable struct Independent_Var_data <: variable_data
    Sym::Union{Symbol,Nothing}
    Bound::Union{Vector,Number}
end

"""
    Algebraic_Var_data

    A DataType for storing a collection of algebraic variables

"""
mutable struct Algebraic_Var_data <: variable_data
    Sym::Expr
    Bound::Vector

    Initial_value::Union{Real,Nothing}
    Final_value::Union{Real,Nothing}
end

"""
    Constant_data

    A DataType for storing a collection of Constants
"""
mutable struct Constant_data <: variable_data
    Sym::Symbol
    Value::Any #to allow types defined from other packages (e.g. StaticArrays)
end

"""
    Parameter_data

    A DataType for storing a collection of Parameters
"""
mutable struct Parameter_data <: variable_data
    Sym::Symbol
    Value::Any 
end

"""
    Dy_Model <: Abstract_Dynamic_Model

    An abstract supertype Abstract_Dynamic_Model, for its subtype Dy_Model displaying the information of the model
"""
abstract type Abstract_Dynamic_Model end

mutable struct Dy_Model <: Abstract_Dynamic_Model 

    #optimizer data
    optimizer::DOI.AbstractDynamicOptimizer    

    #variable data
    #Differential_vars::Vector{Differential_Var_data}
    Differential_var_index::OrderedDict{Expr,Union{Differential_Var_data,Array}}
   # Independent_vars::Independent_Var_data
    Independent_var_index::OrderedDict{Symbol,Independent_Var_data}
    Initial_Independent_var_index::OrderedDict{Symbol,Union{Number,Nothing}}
    Final_Independent_var_index::OrderedDict{Symbol,Union{Number,Nothing}}

    Algebraic_var_index::OrderedDict{Expr,Union{Algebraic_Var_data,Array}}
    #constraint data
    Constraints_index::OrderedDict{Symbol,Expr}

    #constant data
    Constant_index::OrderedDict{Symbol,Constant_data}
    Parameter_index::OrderedDict{Symbol,Parameter_data}

    #dynamics
    Dynamics_index::Vector

    #objective function data
    Objective_index::Expr
end 

Dy_Model() = Dy_Model(DOI.Altro_Optimizer(),OrderedDict(),OrderedDict(),OrderedDict(),OrderedDict(),
OrderedDict(),OrderedDict(),OrderedDict(),OrderedDict(),[],:())


include("macros.jl")
include("variables.jl")
include("errors.jl")
include("constant_parameter.jl") 
include("constraints.jl")
include("optimizer.jl")
include("objective.jl")
include("solver.jl")
include("dynamics.jl")

export @independent, @differential,@algebraic,@constant,@parameter,@constraint,@objective,@dynamics,full_info,optimize!,
add_final_value,set_final_value,delete_final_value,
set_constant,set_parameter,delete_constant,delete_parameter
#= add_initial_bound,add_trajectory_bound,add_final_bound,
set_initial_bound,set_trajectory_bound,set_final_bound,
delete_initial_bound,delete_ =#

export set_dyn_optimizer,set_meshpoints,set_initial_guess,set_discretization,set_parametrization,set_continuity,set_flex_mesh,set_residual_quad_order,set_hessian_approx




Base.show(io::IO, model::Abstract_Dynamic_Model) = print_JuDO(io, model)

function print_JuDO(io::IO, model::Abstract_Dynamic_Model)
    println(io, "Dynamic Optimization Model $(model.optimizer)")
end

# show the information of the model
function full_info(model::Dy_Model)
    #println("A $(model.optimizer)")
    println("System dynamics:")
    for i in eachindex(model.Dynamics_index)
        println("$(model.Dynamics_index[i])")
    end

    println("Objective function: $(model.Objective_index)")
    println("Constants:")
    for (key, value) in model.Constant_index
        println("Constant $(value.Sym) with value = $(value.Value)")
    end
    println("Parameters:")
    for (key, value) in model.Parameter_index
        println("Parameter $(value.Sym) with value = $(value.Value)")
    end
    println("Variables:")
    for (key, value) in model.Differential_var_index
        if value isa Array
            for i in eachindex(value)
                println("Differential variable $(key)[$i] with")
                println("Initial value = $(value[i].Initial_value), Initial bounds = $(value[i].Initial_bound), \nFinal value = $(value[i].Final_value), Final bounds = $(value[i].Final_bound), Trajectory bounds = $(value[i].Trajectory_bound)")
            end
        else
            println("Differential variable $(key) with")
            println("Initial value = $(value.Initial_value), Initial bounds = $(value.Initial_bound), \nFinal value = $(value.Final_value), Final bounds = $(value.Final_bound), Trajectory bounds = $(value.Trajectory_bound)")
        end
    end
    for (key, value) in model.Independent_var_index
        println("Independent variable $(value.Sym) with bound = $(value.Bound)")

    end
    for (key, value) in model.Initial_Independent_var_index
        println("Initial independent variable $key with value = $value")

    end
    for (key, value) in model.Final_Independent_var_index
        println("Final independent variable $key with value = $value")

    end

    for (key, value) in model.Algebraic_var_index
        if value isa Array
            for i in eachindex(value)
                println("Algebraic variable $(value[i].Sym)[$i] with bound = $(value[i].Bound), Initial value = $(value[i].Initial_value),  Final value = $(value[i].Final_value)")
            end
        else
            println("Algebraic variable $(value.Sym) with bound = $(value.Bound), Initial value = $(value.Initial_value), Final value = $(value.Final_value)")
        end
    end

    for (key, value) in model.Constraints_index
        println("Constraint $key : $value")
    end    

end


end
