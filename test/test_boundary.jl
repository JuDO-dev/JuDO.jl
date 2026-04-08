# Tests for initial/final operators and boundary constraints (boundary.jl)

@testset "BoundaryOperator construction" begin

    @testset "initial(phase) returns BoundaryOperator" begin
        m   = DynModel(Interesso.Optimizer)
        ref = @phase(m, t)
        b   = initial(ref)
        @test b isa JuDO.BoundaryOperator
        @test b.op  == :initial
        @test b.arg === ref
    end

    @testset "final(phase) returns BoundaryOperator" begin
        m   = DynModel(Interesso.Optimizer)
        ref = @phase(m, t)
        b   = final(ref)
        @test b isa JuDO.BoundaryOperator
        @test b.op  == :final
        @test b.arg === ref
    end

    @testset "initial(var) returns BoundaryOperator" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        ref = @variable(m, x, DefinedOn(t))
        b   = initial(ref)
        @test b isa JuDO.BoundaryOperator
        @test b.op  == :initial
        @test b.arg === ref
    end

    @testset "final(var) returns BoundaryOperator" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        ref = @variable(m, x, DefinedOn(t))
        b   = final(ref)
        @test b isa JuDO.BoundaryOperator
        @test b.op  == :final
        @test b.arg === ref
    end
end

@testset "BoundaryConditionExpr arithmetic" begin

    @testset "BoundaryOperator - Number" begin
        m   = DynModel(Interesso.Optimizer)
        ref = @phase(m, t)
        b   = initial(ref)
        expr = b - 0.0
        @test expr isa JuDO.BoundaryConditionExpr
        @test expr.op  == :initial
        @test expr.rhs == 0.0
    end

    @testset "BoundaryOperator + Number" begin
        m   = DynModel(Interesso.Optimizer)
        ref = @phase(m, t)
        b   = final(ref)
        expr = b + 5.0
        @test expr isa JuDO.BoundaryConditionExpr
        @test expr.rhs == -5.0   # stored as negation for == comparison
    end

    @testset "BoundaryConditionExpr - Number shifts rhs" begin
        m   = DynModel(Interesso.Optimizer)
        ref = @phase(m, t)
        b   = initial(ref)
        expr1 = b - 3.0
        expr2 = expr1 - 1.0
        @test expr2 isa JuDO.BoundaryConditionExpr
    end

    @testset "BoundaryOperator - BoundaryOperator (linkage)" begin
        m   = DynModel(Interesso.Optimizer)
        t1  = @phase(m, s)
        t2  = @phase(m, r)
        expr = final(t1) - initial(t2)
        @test expr isa JuDO.BoundaryConditionExpr
        @test expr.op       == :final
        @test expr.rhs      isa JuDO.BoundaryOperator
        @test expr.rhs.op   == :initial
        @test expr.rhs.arg  === t2
    end
end

@testset "Phase boundary @constraint" begin

    @testset "initial(t) == value" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @test_nowarn @constraint(m, initial(t) == 0.0)
    end

    @testset "final(t) == value" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @test_nowarn @constraint(m, final(t) == 10.0)
    end

    @testset "initial and final on the same phase" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @test_nowarn @constraint(m, initial(t) == 0.0)
        @test_nowarn @constraint(m, final(t)   == 5.0)
    end
end

@testset "Variable boundary @constraint" begin

    @testset "initial(x) == value" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @test_nowarn @constraint(m, initial(x) == 0.0)
    end

    @testset "final(x) == value" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @test_nowarn @constraint(m, final(x) == 1.0)
    end

    @testset "initial and final on multiple variables" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @variable(m, v, DefinedOn(t))
        @test_nowarn @constraint(m, initial(x) == 0.0)
        @test_nowarn @constraint(m, initial(v) == 1.0)
        @test_nowarn @constraint(m, final(x)   == 5.0)
        @test_nowarn @constraint(m, final(v)   == 0.0)
    end

    @testset "negative rhs value" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @test_nowarn @constraint(m, initial(x) == -1.0)
    end
end

@testset "Phase linkage @constraint" begin

    @testset "final(t1) == initial(t2)" begin
        m  = DynModel(Interesso.Optimizer)
        t1 = @phase(m, s)
        t2 = @phase(m, r)
        @test_nowarn @constraint(m, final(t1) == initial(t2))
    end
end
