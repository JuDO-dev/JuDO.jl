# Tests for derivative(), expression arithmetic, and ODE constraints (derivative.jl, operator-overload.jl)

@testset "derivative()" begin

    @testset "returns DerivativeTerm" begin
        m   = DynModel(Interesso.Optimizer)
        @phase(m, t)
        ref = @variable(m, x, DefinedOn(t))
        d   = derivative(ref)
        @test d isa JuDO.DerivativeTerm
    end

    @testset "coef defaults to 1.0" begin
        m   = DynModel(Interesso.Optimizer)
        @phase(m, t)
        ref = @variable(m, x, DefinedOn(t))
        d   = derivative(ref)
        @test d.coef == 1.0
    end

    @testset "var field matches original ref" begin
        m   = DynModel(Interesso.Optimizer)
        @phase(m, t)
        ref = @variable(m, x, DefinedOn(t))
        d   = derivative(ref)
        @test d.var === ref
    end
end

@testset "DynamicAffExpr arithmetic" begin

    @testset "var + Number" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        expr = x + 2.0
        @test expr isa JuDO.DynamicAffExpr
        @test expr.constant == 2.0
        @test length(expr.terms) == 1
    end

    @testset "var - Number" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        expr = x - 3.0
        @test expr isa JuDO.DynamicAffExpr
        @test expr.constant == -3.0
    end

    @testset "Number + var" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        expr = 4.0 + x
        @test expr isa JuDO.DynamicAffExpr
        @test expr.constant == 4.0
    end

    @testset "Number - var" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        expr = 1.0 - x
        @test expr isa JuDO.DynamicAffExpr
    end

    @testset "Number * var" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        expr = 3.0 * x
        @test expr isa JuDO.DynamicAffExpr
    end

    @testset "var * Number" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        expr = x * 5.0
        @test expr isa JuDO.DynamicAffExpr
    end

    @testset "unary minus" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        expr = -x
        @test expr isa JuDO.DynamicAffExpr
        @test expr.constant == 0.0
    end

    @testset "var + var yields two terms" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @variable(m, v, DefinedOn(t))
        expr = x + v
        @test expr isa JuDO.DynamicAffExpr
        @test length(expr.terms) == 2
    end

    @testset "var - var" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @variable(m, v, DefinedOn(t))
        expr = x - v
        @test expr isa JuDO.DynamicAffExpr
        @test length(expr.terms) == 2
    end

    @testset "zero coefficient multiplication" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        expr = 0.0 * x
        @test expr isa JuDO.DynamicAffExpr
        @test isempty(expr.terms)
    end

    @testset "affine expr + Number" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        expr = (x + 1.0) + 2.0
        @test expr isa JuDO.DynamicAffExpr
        @test expr.constant == 3.0
    end

    @testset "affine expr * Number" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        expr = (2.0 * x) * 3.0
        @test expr isa JuDO.DynamicAffExpr
    end

    @testset "two affine exprs added" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @variable(m, v, DefinedOn(t))
        e1 = x + 1.0
        e2 = v + 2.0
        expr = e1 + e2
        @test expr isa JuDO.DynamicAffExpr
        @test expr.constant == 3.0
        @test length(expr.terms) == 2
    end
end

@testset "DynamicQuadExpr arithmetic" begin

    @testset "var * var" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @variable(m, v, DefinedOn(t))
        expr = x * v
        @test expr isa JuDO.DynamicQuadExpr
    end

    @testset "var^2" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        expr = x^2
        @test expr isa JuDO.DynamicQuadExpr
    end

    @testset "Number * quadratic" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, u, DefinedOn(t))
        expr = 0.5 * u^2
        @test expr isa JuDO.DynamicQuadExpr
    end
end

@testset "NonlinearExpr (division, trig)" begin

    @testset "var / var yields NonlinearExpr" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @variable(m, v, DefinedOn(t))
        expr = x / v
        @test expr isa JuDO.NonlinearExpr
    end
end

@testset "Derivative @constraint (ODE specification)" begin

    @testset "derivative(x) == var" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @variable(m, v, DefinedOn(t))
        @test_nowarn @constraint(m, derivative(x) == v)
    end

    @testset "derivative(x) == affine expr" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @variable(m, v, DefinedOn(t))
        @test_nowarn @constraint(m, derivative(x) == v - x + 1.0)
    end

    @testset "double-integrator dynamics" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, -1.0 <= u <= 1.0, DefinedOn(t))
        @variable(m, x, DefinedOn(t))
        @variable(m, v, DefinedOn(t))
        @test_nowarn @constraint(m, derivative(x) == v)
        @test_nowarn @constraint(m, derivative(v) == u)
    end

    @testset "nonlinear ODE (Van der Pol)" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, -1.0 <= u <= 1.0, DefinedOn(t))
        @variable(m, x, DefinedOn(t))
        @variable(m, v, DefinedOn(t))
        @test_nowarn @constraint(m, derivative(x) == v)
        @test_nowarn @constraint(m, derivative(v) == (1 - x^2) * v + u - x)
    end
end
