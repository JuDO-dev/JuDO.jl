@testset "test_constants" begin
    _model = JuDO.Dy_Model()
    @test _model isa JuDO.Dy_Model

    function test_const(test_cond)
        vector_of_info = []

        push!(vector_of_info,test_cond.Sym)
        push!(vector_of_info,test_cond.Value)

        return vector_of_info
    end

    @test [:g,9.81] == test_const(@constant( _model, g = 9.81)[:g])

    @test [:k,0.0069] == test_const(@constant( _model, k = 0.0069)[:k])

    @test [:k,0] == test_const(@constant( _model, k = 0)[:k])

    @test [:P,101000] == test_const(@constant( _model, P = 1.01e5)[:P])


end