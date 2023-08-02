module JuDO

import JuMP
import MathOptInterface as MOI
import DynOptInterface as DOI

import Base.Meta: isexpr
#activate C:/Users/THC/.julia/dev/JuDO.jl

using Ipopt
using Unicode
using OrderedCollections: OrderedDict

abstract type variable_data end

"""
    Differential_Var_data

    A DataType for storing a collection of differential variables
"""
mutable struct Differential_Var_data <: variable_data
    Run_sym::Union{Expr,Nothing}
    Initial_guess::Union{Real,Nothing}

    Initial_bound::Vector 
    Final_bound::Vector
    Trajectory_bound::Vector

    Interpolant::Union{Symbol,Nothing}
    
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

    Initial_guess::Union{Real,Nothing}
    Interpolant::Union{Symbol,Nothing}
end

"""
    Constant_data

    A DataType for storing a collection of constants
"""
mutable struct Constant_data <: variable_data
    Sym::Symbol
    Value::Union{Number,Array}
end

"""
    constraint_data

    A DataType for storing a collection of constraints
"""
mutable struct Constraint_data <: variable_data
    Equation::Expr
end

"""
    Dynamic_objective

    A DataType for storing the dynamic objective function
"""
mutable struct Dynamic_objective <: variable_data
    Expression::Expr
end

"""
    Dy_Model <: Abstract_Dynamic_Model

    An abstract supertype Abstract_Dynamic_Model, for its subtype Dy_Model displaying the information of the model
"""
abstract type Abstract_Dynamic_Model end

mutable struct Dy_Model <: Abstract_Dynamic_Model 

    #optimizer data
    optimizer::DOI.AbstractDynamicOptimizer     #currently using MOI for testing, should be optimizer::DOI.AbstractDynamicOptimizer

    #constant data
    Constant_index::Dict{Symbol,Constant_data}

    #variable data
    #Differential_vars::Vector{Differential_Var_data}
    Differential_var_index::OrderedDict{Expr,Differential_Var_data}
   # Independent_vars::Independent_Var_data
    Independent_var_index::OrderedDict{Symbol,Independent_Var_data}
    Initial_Independent_var_index::OrderedDict{Symbol,Union{Number,Nothing}}
    Final_Independent_var_index::OrderedDict{Symbol,Union{Number,Nothing}}

    Algebraic_var_index::OrderedDict{Expr,Algebraic_Var_data}
    #constraint data
    Constraints_index::OrderedDict{Symbol,Constraint_data}
    Constraints_type::OrderedDict{Symbol,Symbol}  

    #dynamic data
    Dynamic_objective::Expr
end 

Dy_Model() = Dy_Model(DOI.Optimizer(),OrderedDict(),OrderedDict(),OrderedDict(),
OrderedDict(),OrderedDict(),OrderedDict(),OrderedDict(),OrderedDict(),:())


include("macros.jl")
include("variables.jl")
include("errors.jl")
include("constants.jl") 
include("constraints.jl")
include("optimizer.jl")
include("dynamic_func.jl")

export @independent, @differential,@algebraic,@constant,@constraint,full_info,add_initial_bound,add_trajectory_bound,add_final_bound,
add_initial_guess,add_interpolant,set_initial_bound,set_trajectory_bound,set_final_bound,set_initial_guess,set_interpolant





Base.show(io::IO, model::Abstract_Dynamic_Model) = print_JuDO(io, model)

function print_JuDO(io::IO, model::Abstract_Dynamic_Model)
    println(io, "Dynamic Optimization Model $(model.optimizer)")
end

# show the information of the model
function full_info(model::Dy_Model)
    println("A $(model.optimizer)")
    println("Dynamic objective function: $(model.Dynamic_objective)")
    println("Constants:")
    for (key, value) in model.Constant_index
        println("Constant $(value.Sym) with value = $(value.Value)")
    end
    println("Variables:")
    for (key, value) in model.Differential_var_index
        println("Differential variable $(value.Run_sym) with")
        println("Initial guess = $(value.Initial_guess), Initial bounds = $(value.Initial_bound), Final bounds = $(value.Final_bound), Trajectory bounds = $(value.Trajectory_bound), Interpolant = $(value.Interpolant)")
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
        println("Algebraic variable $(value.Sym) with bound = $(value.Bound), initial guess = $(value.Initial_guess), interpolant = $(value.Interpolant)")
    end

    for (key, value) in model.Constraints_index
        println("Constraint $key :$(value.Equation)")
    end    

end

end


