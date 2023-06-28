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
    @test [:y, 10, [[-Inf, Inf]], [[-Inf, Inf]], [[-Inf, Inf]], nothing] == 
    test_diff_vars(@differential_variable(_model,y,Initial_guess=10)[:y])
    
    @test [:y, 10, [[0,15]], [[-Inf,Inf]], [[-Inf,Inf]], nothing] ==
    test_diff_vars(@differential_variable(_model,y,0<=Initial_bound<=15)[:y])

    @test [:y, 10, [[0,15],[0,20]], [[-Inf,Inf]], [[-100,100]], :c] ==
    test_diff_vars(@differential_variable(_model,y,Interpolant=c,0<=Initial_bound<=20,-100<=Trajectory_bound<=100)[:y])

    @test [:y, 15, [[0,15],[0,20]], [[8,12]], [[-100,100]], :c] ==
    test_diff_vars(@differential_variable(_model,y,Initial_guess=15,8<=Final_bound<=12)[:y])

    @test_throws ErrorException @differential_variable(_model,y)[:y]

    @test_throws ErrorException @differential_variable(_model,y,Final_bound<=5)[:y]

    @test_throws ErrorException @differential_variable(_model,y,60<=Trajectory_bound<=50)[:y]

    #test adding multiple variables
    @test [:z, nothing, [[-Inf, Inf]], [[-Inf, Inf]], [[-Inf, Inf]], nothing] ==
    test_diff_vars(@differential_variable(_model,z)[:z])

    @test [:z, 0, [[0,5]], [[100,Inf]], [[-Inf, Inf]], nothing] ==
    test_diff_vars(@differential_variable(_model,z,Initial_guess=0,100<=Final_bound,0<=Initial_bound<=5)[:z])

    @test [:x, nothing, [[-Inf, Inf]], [[-Inf, Inf]], [[-Inf, Inf]], nothing] == 
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

    @test [:t,[0,Inf]] == test_inde_vars(@independent_variable( _model,t >= 0)[:t])

    @test [:t,[2,Inf]] == test_inde_vars(@independent_variable( _model,2 <= t)[:t])

    @test [:t,[-Inf,10]] == test_inde_vars(@independent_variable( _model,t <= 10)[:t])

    @test [:t,[0,10]] == test_inde_vars(@independent_variable( _model,0 <= t <= 10)[:t])

    @test [:t,[-Inf,Inf]] == test_inde_vars(@independent_variable( _model,t)[:t])

    # Test for error when the first element of the bound is greater than the second element
    @test_throws ErrorException @independent_variable( _model, 10 <= t <= 0)[:t]

    @test_throws ErrorException @independent_variable( _model, t1)[:t1]

    @test_throws ErrorException @independent_variable( _model, t1 >= 0)[:t1]

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

    @test [:u,[0,10]] == test_alge_vars(@algebraic_variable( _model, 0 <= u <= 10)[:u])

    @test [:u,[0,Inf]] == test_alge_vars(@algebraic_variable( _model, u >= 0)[:u])

    @test [:u,[0,Inf]] == test_alge_vars(@algebraic_variable( _model, 0 <= u)[:u])

    @test [:u,[-Inf,Inf]] == test_alge_vars(@algebraic_variable( _model, u)[:u])

    # adding multiple variables
    @test [:v,[-Inf,Inf]] == test_alge_vars(@algebraic_variable( _model, v)[:v])

    @test [:w,[-Inf,Inf]] == test_alge_vars(@algebraic_variable( _model, w)[:w])

    # test for error when the first element of the bound is greater than the second element
    @test_throws ErrorException @algebraic_variable( _model, 10 <= u <= 0)[:u]


end