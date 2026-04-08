# Tests for DynModel construction and core data types (datatypes.jl)

@testset "DynModel" begin

    @testset "ext fields are initialised on construction" begin
        m = DynModel(Interesso.Optimizer)
        @test haskey(m.ext, :Phases)
        @test haskey(m.ext, :Phasenum)
        @test haskey(m.ext, :phase_name_to_idx)
        @test haskey(m.ext, :variables)
        @test haskey(m.ext, :varnum)
        @test haskey(m.ext, :var_name_to_idx)
    end

    @testset "counters start at zero" begin
        m = DynModel(Interesso.Optimizer)
        @test m.ext[:Phasenum][:phase] == 0
        @test m.ext[:varnum][:var] == 0
    end

    @testset "registries start empty" begin
        m = DynModel(Interesso.Optimizer)
        @test isempty(m.ext[:Phases])
        @test isempty(m.ext[:variables])
        @test isempty(m.ext[:phase_name_to_idx])
        @test isempty(m.ext[:var_name_to_idx])
    end

    @testset "two models are independent" begin
        m1 = DynModel(Interesso.Optimizer)
        m2 = DynModel(Interesso.Optimizer)
        @phase(m1, t)
        @test m1.ext[:Phasenum][:phase] == 1
        @test m2.ext[:Phasenum][:phase] == 0
    end
end

@testset "PhaseVar" begin

    @testset "unbounded construction" begin
        pv = JuDO.PhaseVar(-Inf, Inf)
        @test pv.Initial == -Inf
        @test pv.Final   == Inf
    end

    @testset "bounded construction" begin
        pv = JuDO.PhaseVar(0.0, 10.0)
        @test pv.Initial == 0.0
        @test pv.Final   == 10.0
    end

    @testset "is mutable" begin
        pv = JuDO.PhaseVar(0.0, 1.0)
        pv.Final = 5.0
        @test pv.Final == 5.0
    end
end

@testset "PhaseVarRef" begin

    @testset "fields after @phase" begin
        m = DynModel(Interesso.Optimizer)
        ref = @phase(m, t)
        @test ref isa JuDO.PhaseVarRef
        @test ref.model === m
        @test ref.Index  == 1
        @test ref.name   == :t
    end

    @testset "second phase gets index 2" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, s)
        ref2 = @phase(m, r)
        @test ref2.Index == 2
        @test ref2.name  == :r
    end
end

@testset "DynamicVar" begin

    @testset "Phase field holds full PhaseVarRef after @variable" begin
        m    = DynModel(Interesso.Optimizer)
        tref = @phase(m, t)
        @variable(m, x, DefinedOn(t))
        dv = m.ext[:variables][1]
        @test dv isa JuDO.DynamicVar
        @test dv.Phase === tref
        @test dv.Phase.model === m
    end

    @testset "trajectory bounds stored from @variable" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, -3.0 <= u <= 7.0, DefinedOn(t))
        dv = m.ext[:variables][1]
        @test dv.Trajectory_bound[1] == -3.0
        @test dv.Trajectory_bound[2] ==  7.0
    end

    @testset "Initial_value and Final_value default to nothing" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        dv = m.ext[:variables][1]
        @test isnothing(dv.Initial_value)
        @test isnothing(dv.Final_value)
    end
end

@testset "Accessor helpers" begin

    @testset "get_phase" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        phases = JuDO.get_phase(m)
        @test length(phases) == 1
        @test phases[1] isa JuDO.PhaseVar
    end

    @testset "get_phasenum" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @test JuDO.get_phasenum(m)[:phase] == 1
    end

    @testset "get_var" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        vars = JuDO.get_var(m)
        @test length(vars) == 1
        @test vars[1] isa JuDO.DynamicVar
    end

    @testset "get_varnum" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @variable(m, v, DefinedOn(t))
        @test JuDO.get_varnum(m)[:var] == 2
    end
end
