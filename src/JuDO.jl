module JuDO

using Unicode
using OrderedCollections: OrderedDict
using LinearAlgebra
using StaticArrays
using JuMP

import MathOptInterface as MOI
import DynOptInterface as DOI
import JuMP.MOIU.CleverDicts as MOIU_cd
import Base: +, -, *, /, ^
import JuMP: @variable, @constraint, @objective
export @variable, @constraint, @objective

const _Const = Union{Number,LinearAlgebra.UniformScaling}

include("datatypes.jl")
include("variable.jl")

include("constraints.jl")

include("operator-overload.jl")
include("derivative.jl")
include("boundary.jl")
include("objective.jl")
include("optimizer_interface.jl")
include("solutions.jl")

export @phase, DynModel, initial, final, DefinedOn, derivative, integral, dyn_value
export get_solutions, warmstart!, optimize!

end

