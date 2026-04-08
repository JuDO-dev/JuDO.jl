# Tests for integral() and @objective (objective.jl)

@testset "integral()" begin

    @testset "returns Integral struct" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        ig = integral(x)
        @test ig isa JuDO.Integral
    end

    @testset "phase index is recorded" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        ig = integral(x)
        @test ig.phase == 1
    end

    @testset "second phase gets index 2" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, s)
        @phase(m, r)
        @variable(m, x, DefinedOn(s))
        @variable(m, y, DefinedOn(r))
        ig_x = integral(x)
        ig_y = integral(y)
        @test ig_x.phase == 1
        @test ig_y.phase == 2
    end

    @testset "integral of affine expr" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @variable(m, u, DefinedOn(t))
        ig = integral(x + u)
        @test ig isa JuDO.Integral
    end

    @testset "integral of quadratic expr" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, u, DefinedOn(t))
        ig = integral(u^2)
        @test ig isa JuDO.Integral
    end

    @testset "integral of scaled quadratic (Lagrange cost)" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, u, DefinedOn(t))
        ig = integral(0.5 * u^2)
        @test ig isa JuDO.Integral
    end
end

@testset "@objective — Lagrange cost (integral)" begin

    @testset "Min integral(u^2)" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @constraint(m, initial(t) == 0.0)
        @constraint(m, final(t)   == 1.0)
        @variable(m, u, DefinedOn(t))
        @test_nowarn @objective(m, Min, integral(u^2))
    end

    @testset "Min integral with affine integrand" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @constraint(m, initial(t) == 0.0)
        @constraint(m, final(t)   == 5.0)
        @variable(m, x, DefinedOn(t))
        @variable(m, u, DefinedOn(t))
        @test_nowarn @objective(m, Min, integral(x^2 + u^2))
    end

    @testset "Min integral with nonlinear integrand" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @constraint(m, initial(t) == 0.0)
        @constraint(m, final(t)   == 4.0)
        @variable(m, x, DefinedOn(t))
        @variable(m, v, DefinedOn(t))
        @test_nowarn @objective(m, Min, integral(0.5*x^2 + 0.5*v^2))
    end
end

@testset "@objective — Mayer cost (boundary)" begin

    @testset "Min final(x)" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @constraint(m, initial(t) == 0.0)
        @constraint(m, final(t)   == 1.0)
        @variable(m, x, DefinedOn(t))
        @test_nowarn @objective(m, Min, final(x))
    end

    @testset "Min initial(x)" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @constraint(m, initial(t) == 0.0)
        @constraint(m, final(t)   == 1.0)
        @variable(m, x, DefinedOn(t))
        @test_nowarn @objective(m, Min, initial(x))
    end
end
