
mutable struct PhaseVar <: JuMP.AbstractVariable
    Jumpinfo::JuMP.VariableInfo{Float64,Float64,Float64,Float64}

    #Sym::Symbol
    Initial::Union{Real,Nothing}
    Final::Union{Real,Nothing}
end

mutable struct PhaseVarData 
    variable::PhaseVar
    name::String
end

struct Phase end

struct PhaseIndex
    value::Int64
    phase::PhaseVarData
end

struct PhaseVarRef{M<:JuMP.AbstractModel} <: JuMP.AbstractVariableRef
    model::M
    Index::PhaseIndex
end

struct Dynamic
    Phase::PhaseVarRef
end

struct DynamicVar <: JuMP.AbstractVariable
    Jumpinfo::JuMP.VariableInfo{Float64,Float64,Float64,Float64}
    
    Phase::PhaseIndex
    Initial_bound::Vector{Real}
    Final_bound::Vector{Real}
    Final_value::Union{Real,Nothing}
end

mutable struct DynamicVarData 
    variable::DynamicVar
    name::String
end

"""
    DynModel <: Abstract_Dynamic_Model

    Storing, displaying the information of the model
"""
function DynModel(args...; kwargs...)
    model = JuMP.Model(args...; kwargs...)

    model.ext[:Phasenum] = Dict(:phase=>0)
    model.ext[:Phases] = OrderedDict{Int,PhaseVarData}()
    model.ext[:varnum] = Dict(:var=>0)
    model.ext[:variables] = OrderedDict{Int,DynamicVarData}()

    #create the option for creating the exact same struct as above when a new phase is desinged 

    return model
end

function get_phase(model)
    return model.ext[:Phases]
end

function get_phasenum(model)
    return model.ext[:Phasenum]
end

function get_var(model)
    return model.ext[:variables]
end

# _v = model.ext[:variables]
# if !haskey(_v,phasedata)
#     _v[phasedata] = OrderedDict{Int,DynamicVarData}()
#     return _v, false
# end
# return _v, true

function get_varnum(model)
    return model.ext[:varnum]
end



# mutable struct DynModel <: JuMP.AbstractModel
#     optimizer::Int

#     phasenum::Int
#     phases::OrderedDict{Int,Phase_data}#gai phase ding yi

#     varnum::Int
#     variables::OrderedDict{Int,DynamicVarData}      # Map varidx -> variable

#     var_to_name::Dict{Int,String}
#     name_to_var::Union{Dict{String,Int},Nothing}

#     # constraints::Dict{ConstraintIndex,JuMP.AbstractConstraint}
#     # con_to_name::Dict{ConstraintIndex,String}
#     # name_to_con::Union{Dict{String,ConstraintIndex},Nothing}
#     objective_sense::JuMP.MOI.OptimizationSense
#     # objective_function::Union{
#     #     JuMP.AbstractJuMPScalar,
#     #     Vector{<:JuMP.AbstractJuMPScalar},
#     # }
#     obj_dict::Dict{Symbol,Any}
    
# end

# DynModel() = DynModel(
#     1,
#     0,
#     OrderedDict{Int,Phase_data}(),
#     0,
#     OrderedDict{Int,DynamicVarData}(),
#     Dict{Int,String}(),
#     nothing,
#     # Dict{ConstraintIndex,JuMP.AbstractConstraint}(),
#     # Dict{ConstraintIndex,String}(),
#     # nothing,
#     JuMP.MOI.FEASIBILITY_SENSE,
#     #zero(JuMP.GenericAffExpr{Float64,MyVariableRef}),
#     Dict{Symbol,Any}()
# )

# JuMP.object_dictionary(model::DynModel) = model.obj_dict

# function Base.show(io::IO, model::DynModel)
#     print(io, "A Dynamic model")
# end