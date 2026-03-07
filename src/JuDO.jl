module JuDO

import JuMP
import JuMP: derivative
import MathOptInterface as MOI
import DynOptInterface as DOI
import JuMP.MOIU.CleverDicts as MOIU_cd
import Base: +, -, *, /, ^

using Unicode
using OrderedCollections: OrderedDict
using LinearAlgebra
using StaticArrays


const _Const = Union{Number,LinearAlgebra.UniformScaling}

include("datatypes.jl")
include("variable.jl")
include("operator-overload.jl")
include("derivative.jl")
include("boundary.jl")
include("objective.jl")
include("optimizer_interface.jl")
include("solutions.jl")

export @phase, DynModel, initial, final, DefinedOn, integral, dyn_value, phase_final, phase_initial, set_interpolant, optimize


end

