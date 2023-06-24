module JuDO

import JuMP
import MathOptInterface as MOI
#import DynOptInterface as DOI

import Base.Meta: isexpr
#activate C:/Users/THC/.julia/dev/JuDO.jl

using Ipopt

abstract type variable_data end

"""
    Differential_Var_data

    A DataType for storing a collection of differential variables
"""
mutable struct Differential_Var_data <: variable_data
    Run_sym::Symbol
    Initial_guess::Union{Real,Nothing}

    Initial_bound::Vector{T} where T<:Real    
    Final_bound::Vector{T} where T<:Real
    Trajectory_bound::Vector{T} where T<:Real

    Interpolant::Union{Symbol,Nothing}
    
end
"""
    Independent_Var_data

    A DataType for storing a collection of independent variables (currently for free/fixed time case)
        # free/fixed start/end problem
"""
mutable struct Independent_Var_data <: variable_data
    Sym::Union{Symbol,Nothing}
    Bound::Vector{T} where T<:Real
end

"""
    Algebraic_Var_data

    A DataType for storing a collection of algebraic variables

    # continuous/discrete algebraic variables

"""
mutable struct Algebraic_Var_data <: variable_data
    Sym::Symbol
    Bound::Vector{T} where T<:Real

end


"""
    Dy_Model <: Abstract_Dynamic_Model

    An abstract supertype Abstract_Dynamic_Model, for its subtype Dy_Model displaying the information of the model
"""
abstract type Abstract_Dynamic_Model end

mutable struct Dy_Model <: Abstract_Dynamic_Model 
    #optimizer data
    optimizer::MOI.AbstractOptimizer     #currently using MOI for testing, should be optimizer::DOI.AbstractDynamicOptimizer

    #variable data
    #Differential_vars::Vector{Differential_Var_data}
    Differential_var_index::Dict{Symbol,Differential_Var_data}
   # Independent_vars::Independent_Var_data
    Independent_var_index::Dict{Symbol,Independent_Var_data}
    Algebraic_var_index::Dict{Symbol,Algebraic_Var_data}
    #constraint data

    #dynamic data
    
end 

# currently using Ipopt as the default optimizer for testing, should be an optimizer with type DOI.AbstractDynamicOptimizer
Dy_Model() = Dy_Model(Ipopt.Optimizer(),Dict(),Dict(),Dict())


include("macros.jl")
include("variables.jl")
include("errors.jl")

export @independent_variable, @differential_variable,@algebraic_variable

end
