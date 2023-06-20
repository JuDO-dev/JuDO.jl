@testset "test_differential_vars" begin

    _model = JuDO.Dy_Model()
    @test _model isa JuDO.Dy_Model

    function test_diff_vars(test_cond)
        vector_of_info = []

        push!(vector_of_info,test_cond.Run_sym)
        push!(vector_of_info,test_cond.Initial_val)
        push!(vector_of_info,test_cond.Final_val)
        push!(vector_of_info,test_cond.Initial_bound)
        push!(vector_of_info,test_cond.Final_bound)
        push!(vector_of_info,test_cond.Trajectory_bound)
        push!(vector_of_info,test_cond.Interpolant)
        return vector_of_info
    end

    # test adding and then modifiying an existing variable "y", finally clearing the variable
    @test [:y, nothing, 10, [-Inf, Inf], [-Inf, Inf], [-Inf, Inf], nothing] == 
    test_diff_vars(@differential_variable(_model,y,Final_val=10)[:y])
    
    @test [:y, nothing, 10, [0,5], [-Inf,Inf], [-Inf,Inf], nothing] ==
    test_diff_vars(@differential_variable(_model,y,Initial_bound=[0,5])[:y])

    @test [:y, nothing, 10, [-10,10], [-Inf,Inf], [-100,100], :c] ==
    test_diff_vars(@differential_variable(_model,y,Interpolant=c,Initial_bound=[-10,10],Trajectory_bound=[-100,100])[:y])

    @test [:y, -5, 10, [-10,10], [8,12], [-100,100], :c] ==
    test_diff_vars(@differential_variable(_model,y,Initial_val=-5,Final_bound=[8,12])[:y])

    @test [:y, nothing, nothing, [-Inf, Inf], [-Inf, Inf], [-Inf, Inf], nothing] == 
    test_diff_vars(@differential_variable(_model,y)[:y])

    #test adding multiple variables
    @test [:z, nothing, nothing, [-Inf, Inf], [-Inf, Inf], [-Inf, Inf], nothing] ==
    test_diff_vars(@differential_variable(_model,z)[:z])

    @test [:x, nothing, nothing, [-Inf, Inf], [-Inf, Inf], [-Inf, Inf], nothing] == 
    test_diff_vars(@differential_variable(_model,x)[:x])

end

@testset "test_independent_vars" begin

    _model = JuDO.Dy_Model()
    @test _model isa JuDO.Dy_Model

    function test_inde_vars(test_cond)
        vector_of_info = []

        push!(vector_of_info,test_cond.Sym)
        push!(vector_of_info,test_cond.Bound)

        return vector_of_info
    end

    # creating a variable "t" with no bounds first, then modifying it, finally clearing it
    @test [:t,[-Inf,Inf]] == test_inde_vars(@independent_variable( _model,t)[:t])

    @test [:t,[0,Inf]] == test_inde_vars(@independent_variable( _model,t in [0,Inf])[:t])

    @test [:t,[-Inf,10]] == test_inde_vars(@independent_variable( _model,t in [-Inf,10])[:t])

    @test [:t,[0,10]] == test_inde_vars(@independent_variable( _model,t in [0,10])[:t])

    @test [:t,[-Inf,Inf]] == test_inde_vars(@independent_variable( _model,t)[:t])

end