module JuDO

import JuMP
import MathOptInterface as MOI
#import DynOptInterface as DOI

import Base.Meta: isexpr
#activate C:/Users/THC/.julia/dev/JuDO.jl

using Ipopt
using Unicode

abstract type variable_data end

"""
    Differential_Var_data

    A DataType for storing a collection of differential variables
"""
mutable struct Differential_Var_data <: variable_data
    Run_sym::Union{Symbol,Nothing}
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
    Bound::Vector
end

"""
    Algebraic_Var_data

    A DataType for storing a collection of algebraic variables

"""
mutable struct Algebraic_Var_data <: variable_data
    Sym::Symbol
    Bound::Vector

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
mutable struct constraint_data <: variable_data
    Sym::Symbol
    Equation::Expr
end

"""
    Dy_Model <: Abstract_Dynamic_Model

    An abstract supertype Abstract_Dynamic_Model, for its subtype Dy_Model displaying the information of the model
"""
abstract type Abstract_Dynamic_Model end

mutable struct Dy_Model <: Abstract_Dynamic_Model 
    #optimizer data
    optimizer::MOI.AbstractOptimizer     #currently using MOI for testing, should be optimizer::DOI.AbstractDynamicOptimizer

    #constant data
    Constant_index::Dict{Symbol,Constant_data}

    #variable data
    #Differential_vars::Vector{Differential_Var_data}
    Differential_var_index::Dict{Symbol,Differential_Var_data}
   # Independent_vars::Independent_Var_data
    Independent_var_index::Dict{Symbol,Independent_Var_data}
    Initial_sym::Union{Symbol,Nothing}
    Final_sym::Union{Symbol,Nothing}

    Algebraic_var_index::Dict{Symbol,Algebraic_Var_data}
    #constraint data
    constraints_index::Dict{Symbol,Expr}

    #dynamic data
    
end 

# currently using Ipopt as the default optimizer for testing, should be an optimizer with type DOI.AbstractDynamicOptimizer
Dy_Model() = Dy_Model(Ipopt.Optimizer(),Dict(),Dict(),Dict(),nothing,nothing,Dict(),Dict())


include("macros.jl")
include("variables.jl")
include("errors.jl")
include("constants.jl")
include("constraints.jl")

export @independent_variable, @differential_variable,@algebraic_variable,@constant,@algebraic_expression,@constraint





Base.show(io::IO, model::Abstract_Dynamic_Model) = print_JuDO(io, model)

# show the information of the model
function print_JuDO(io::IO, model::Abstract_Dynamic_Model)
    println(io, "A $(model.optimizer)")
    println(io, "Constants:")
    for (key, value) in model.Constant_index
        println(io, "  Constant $(value.Sym) with value = $(value.Value)")
    end
    println(io, "Variables:")
    for (key, value) in model.Differential_var_index
        println(io, "  Differential variable $(value.Run_sym) with")
        println(io, "  Initial guess = $(value.Initial_guess), Initial bounds = $(value.Initial_bound), Final bounds = $(value.Final_bound), Trajectory bounds = $(value.Trajectory_bound), Interpolant = $(value.Interpolant)")
    end
    for (key, value) in model.Independent_var_index
        println(io, "  Independent variable $(value.Sym) with bound = $(value.Bound)")

    end
    for (key, value) in model.Algebraic_var_index
        println(io, "  Algebraic variable $(value.Sym) with bound = $(value.Bound)")
    end

end

end


