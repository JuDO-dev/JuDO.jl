# Tests for @phase macro and phase registration (datatypes.jl)

@testset "@phase — free (unbounded) phase" begin

    @testset "returns a PhaseVarRef" begin
        m   = DynModel(Interesso.Optimizer)
        ref = @phase(m, t)
        @test ref isa JuDO.PhaseVarRef
    end

    @testset "index, name, and model pointer" begin
        m   = DynModel(Interesso.Optimizer)
        ref = @phase(m, t)
        @test ref.Index == 1
        @test ref.name  == :t
        @test ref.model === m
    end

    @testset "PhaseVar bounds default to [-Inf, Inf]" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        pv = m.ext[:Phases][1]
        @test pv.Initial == -Inf
        @test pv.Final   == Inf
    end

    @testset "counter incremented" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @test m.ext[:Phasenum][:phase] == 1
    end

    @testset "name registered in lookup dict" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @test haskey(m.ext[:phase_name_to_idx], :t)
        @test m.ext[:phase_name_to_idx][:t] == 1
    end
end

@testset "@phase — bounded phase" begin

    @testset "PhaseVar bounds match arguments" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t, 0.0, 10.0)
        pv = m.ext[:Phases][1]
        @test pv.Initial == 0.0
        @test pv.Final   == 10.0
    end

    @testset "integer bounds accepted" begin
        m = DynModel(Interesso.Optimizer)
        @test_nowarn @phase(m, t, 0, 5)
    end

    @testset "start == stop accepted" begin
        m = DynModel(Interesso.Optimizer)
        @test_nowarn @phase(m, t, 1.0, 1.0)
    end

    @testset "start > stop throws ArgumentError" begin
        m = DynModel(Interesso.Optimizer)
        @test_throws ArgumentError @phase(m, t, 10.0, 0.0)
    end
end

@testset "@phase — multiple phases" begin

    @testset "indices are sequential" begin
        m  = DynModel(Interesso.Optimizer)
        r1 = @phase(m, s)
        r2 = @phase(m, r)
        @test r1.Index == 1
        @test r2.Index == 2
    end

    @testset "both names registered" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, s)
        @phase(m, r)
        @test haskey(m.ext[:phase_name_to_idx], :s)
        @test haskey(m.ext[:phase_name_to_idx], :r)
    end

    @testset "counter reflects total" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, p1)
        @phase(m, p2)
        @phase(m, p3)
        @test m.ext[:Phasenum][:phase] == 3
    end
end

@testset "@phase — error cases" begin

    @testset "duplicate phase name throws" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @test_throws ErrorException @phase(m, t)
    end

    @testset "duplicate name in different models is fine" begin
        m1 = DynModel(Interesso.Optimizer)
        m2 = DynModel(Interesso.Optimizer)
        @phase(m1, t)
        @test_nowarn @phase(m2, t)
    end
end

@testset "JuMP.is_valid for PhaseVarRef" begin

    @testset "valid ref on its own model" begin
        m   = DynModel(Interesso.Optimizer)
        ref = @phase(m, t)
        @test JuMP.is_valid(m, ref)
    end

    @testset "ref from different model is not valid" begin
        m1  = DynModel(Interesso.Optimizer)
        m2  = DynModel(Interesso.Optimizer)
        ref = @phase(m1, t)
        @test !JuMP.is_valid(m2, ref)
    end
end
