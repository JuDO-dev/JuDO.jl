@testset "test_constants" begin
    _model = JuDO.Dy_Model()

    @constant( _model, g = 9.81)
    @constant( _model, k = 0.0069)
    @constant( _model, A = [1 2;3 4])
    @constant( _model, P = 1.01e5)

    @test 9.81 == _model.Constant_index[:g].Value
    @test 0.0069 == _model.Constant_index[:k].Value
    @test [1 2;3 4] == _model.Constant_index[:A].Value
    @test 101000 == _model.Constant_index[:P].Value

    @test_throws ErrorException @constant( _model, g = 9.81)
    println(_model.optimizer.constants)


end