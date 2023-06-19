@testset "test_differential_vars" begin

    _model = JuDO.Dy_Model()
    @test _model isa JuDO.Dy_Model

    function test_diff_vars(test_cond)
        vector_of_info = []

        push!(vector_of_info,test_cond.Run_sym)
        push!(vector_of_info,test_cond.Init_val)
        push!(vector_of_info,test_cond.Final_val)
        push!(vector_of_info,test_cond.Init_bound)
        push!(vector_of_info,test_cond.Final_bound)
        push!(vector_of_info,test_cond.trajectory_bound)
        push!(vector_of_info,test_cond.Interpolant_name)

        return vector_of_info
    end

    @test [:x₀,nothing,nothing,[-Inf,Inf],[-Inf,Inf],[-Inf,Inf],nothing] ==
    test_diff_vars(@differential_variable(_model,x₀))

    @test [:x₀,nothing,10,[-Inf,Inf],[-Inf,Inf],[-Inf,Inf],nothing] ==
    test_diff_vars(@differential_variable(_model,x₀,final_val=10))

    @test [:x₀,nothing,nothing,[0,5],[-Inf,Inf],[-Inf,Inf],nothing] ==
    test_diff_vars(@differential_variable(_model,x₀,initial_bound=[0,5]))

    @test [:x₀,nothing,10,[0,5],[-Inf,Inf],[-Inf,Inf],nothing] ==
    test_diff_vars(@differential_variable(_model,x₀,initial_bound=[0,5],final_val=10))

    @test [:x₀,nothing,nothing,[-Inf,Inf],[0,50],[0,100],nothing] ==
    test_diff_vars(@differential_variable(_model,x₀,trajectory_bound=[0,100],final_bound=[0,50]))

    @test [:x₀,8,90,[-Inf,Inf],[0,100],[-Inf,Inf],:L] ==
    test_diff_vars(@differential_variable(_model,x₀,final_val=90,initial_val=8,final_bound=[0,100],interpolant=L)) 

end

@testset "test_independent_vars" begin

    _model = JuDO.Dy_Model()
    @test _model isa JuDO.Dy_Model

    function test_inde_vars(test_cond)
        vector_of_info = []

        push!(vector_of_info,test_cond.sym)
        push!(vector_of_info,test_cond.bound)

        return vector_of_info
    end

    @test [:t,[-Inf,Inf]] == test_inde_vars(@independent_variable( _model, t))

    @test [:t,[0,Inf]] == test_inde_vars(@independent_variable( _model, t in [0,Inf]))

    @test [:t,[-Inf,10]] == test_inde_vars(@independent_variable( _model, t in [-Inf,10]))

    @test [:dist,[0,10]] == test_inde_vars(@independent_variable( _model, dist in [0,10]))

end