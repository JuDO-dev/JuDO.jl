@testset "test_differential_vars" begin

    _model = JuDO.Dy_Model()
    @test _model isa JuDO.Dy_Model

    function test_diff_vars(test_cond)
        vector_of_info = []

        push!(vector_of_info,test_cond.Run_sym)
        push!(vector_of_info,test_cond.Initial_guess)
        push!(vector_of_info,test_cond.Initial_bound)
        push!(vector_of_info,test_cond.Final_bound)
        push!(vector_of_info,test_cond.Trajectory_bound)
        push!(vector_of_info,test_cond.Interpolant)
        return vector_of_info
    end

    # test adding and then modifiying an existing variable "y", finally clearing the variable
    @test [:y, 10, [-Inf, Inf], [-Inf, Inf], [-Inf, Inf], nothing] == 
    test_diff_vars(@differential_variable(_model,y,Initial_guess=10)[:y])
    
    @test [:y, 10, [0,15], [-Inf,Inf], [-Inf,Inf], nothing] ==
    test_diff_vars(@differential_variable(_model,y,Initial_bound in [0,15])[:y])

    @test [:y, 10, [0,20], [-Inf,Inf], [-100,100], :c] ==
    test_diff_vars(@differential_variable(_model,y,Interpolant=c,Initial_bound in [0,20],Trajectory_bound in [-100,100])[:y])

    @test [:y, 15, [0,20], [8,12], [-100,100], :c] ==
    test_diff_vars(@differential_variable(_model,y,Initial_guess=15,Final_bound in [8,12])[:y])

    @test [:y, nothing, [-Inf, Inf], [-Inf, Inf], [-Inf, Inf], nothing] == 
    test_diff_vars(@differential_variable(_model,y)[:y])

    #test adding multiple variables
    @test [:z, nothing, [-Inf, Inf], [-Inf, Inf], [-Inf, Inf], nothing] ==
    test_diff_vars(@differential_variable(_model,z)[:z])

    @test [:x, nothing, [-Inf, Inf], [-Inf, Inf], [-Inf, Inf], nothing] == 
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

    # Test for error when the first element of the bound is greater than the second element
    @test_throws ErrorException @independent_variable( _model, t in [10,0])[:t]

    # Test for error when the user input style is wrong
    @test_throws UndefVarError @independent_variable( _model, t in [a,10])[:t]

    @test_throws ErrorException @independent_variable( _model, t in (0,10))[:t]

end

@testset "test_algebraic_vars" begin
    _model = JuDO.Dy_Model()
    @test _model isa JuDO.Dy_Model

    function test_alge_vars(test_cond)
        vector_of_info = []

        push!(vector_of_info,test_cond.Sym)
        push!(vector_of_info,test_cond.Bound)

        return vector_of_info
    end
    # creating a variable "u" with no bounds first, then modifying it, finally clearing it
    @test [:u,[-Inf,Inf]] == test_alge_vars(@algebraic_variable( _model, u)[:u])

    @test [:u,[0,10]] == test_alge_vars(@algebraic_variable( _model, u in [0,10])[:u])

    @test [:u,[0,Inf]] == test_alge_vars(@algebraic_variable( _model, u in [0,Inf])[:u])

    @test [:u,[-Inf,Inf]] == test_alge_vars(@algebraic_variable( _model, u)[:u])

    # adding multiple variables
    @test [:v,[-Inf,Inf]] == test_alge_vars(@algebraic_variable( _model, v)[:v])

    @test [:w,[-Inf,Inf]] == test_alge_vars(@algebraic_variable( _model, w)[:w])

    # test for error when the first element of the bound is greater than the second element
    @test_throws ErrorException @algebraic_variable( _model, x in [10,0])[:x]

    # test for error when the user input style is wrong
    @test_throws UndefVarError @algebraic_variable( _model, x in [a,10])[:x]

    @test_throws ErrorException @algebraic_variable( _model, x in (0,10))[:x] 

end