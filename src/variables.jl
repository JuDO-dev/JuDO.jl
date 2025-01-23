"""
    Dynamic_Var_data

    A DataType for storing a collection of differential variables
"""
mutable struct Dynamic_Var_data <: variable_data
    Run_sym::Symbol

    Initial_bound::Vector{Real}
    Initial_value::Union{Real,Nothing}
    Final_bound::Vector{Real}
    Final_value::Union{Real,Nothing}
    Trajectory_bound::Vector{Real}

    function Dynamic_Var_data()
        return new(:NAN,[-Inf,Inf],0,[-Inf,Inf],0,[-Inf,Inf])
    end
    
end

"""
    find the number of phase that a symbol corresponds to
"""
function find_phase(phase_data::OrderedDict,target_phase::Symbol)
    index = 0
    for (i, (k,v)) in enumerate(phase_data)
        if k == target_phase
            index = i
            break
        end
    end
    return index
end

function add_new_dvar(_model,_expr::Array,range::Array)

    var_info = _expr[1]
    phase = _expr[2]

    #check_exist_phase_def(_expr)   #a function to check if the phase existing

    #check_bound(range) #check if the bound is valid 

    _model.Dynamic_var_index[var_info] = ['t']

    index = find_phase(_model.Independent_var_data, phase)

    data = Dynamic_Var_data()
    data.Initial_value = range[1]
    data.Final_value = range[2]

    #if the user is specifying the bound
    if range[1] != -Inf

        MOI.add_constraint(_model.Optimizer, DOI.Initial{DOI.DynamicVariableIndex(1,DOI.PhaseIndex(index))}, range[1])

    elseif range[2] != Inf

        #
    end

    #DOI.add_dynamic_variable(_model,DOI.PhaseIndex(index))   # no optimizer has been added yet

    return data
end