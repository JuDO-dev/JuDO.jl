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
    Init_val::Union{Real,Nothing}
    Final_val::Union{Real,Nothing}

    Init_bound::Vector    
    Final_bound::Vector
    trajectory_bound::Vector

    Interpolant_name::Union{Symbol,Nothing}
    
end
"""
    Independent_Var_data

    A DataType for storing a collection of independent variables (currently for free/fixed time case)
        # free/fixed start/end problem
"""
mutable struct Independent_Var_data <: variable_data
    sym::Union{Symbol,Nothing}
    bound::Vector
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

    #constraint data

    #dynamic data
    
end 

# currently using Ipopt as the default optimizer for testing, should be an optimizer with type DOI.AbstractDynamicOptimizer
Dy_Model() = Dy_Model(Ipopt.Optimizer(),Dict{Symbol,Differential_Var_data}(),Dict{Symbol,Independent_Var_data}())


include("macros.jl")
include("variables.jl")

export @independent_variable, @differential_variable,output_macro

end
