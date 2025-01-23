module JuDO

import JuMP
import MathOptInterface as MOI
import DynOptInterface as DOI
import JuMP.MOIU.CleverDicts as MOIU_cd

using Ipopt
using Unicode
using OrderedCollections: OrderedDict
using LinearAlgebra
using StaticArrays


const _Const = Union{Number,LinearAlgebra.UniformScaling}

include("datatypes.jl")
include("operator-overload.jl")
include("new_phase.jl")
include("macros.jl")
#include("variables.jl")
#include("DOI_wrapper.jl")
include("constraints_new.jl")

export @phase, @outer_macro

# show the information of the model


end

