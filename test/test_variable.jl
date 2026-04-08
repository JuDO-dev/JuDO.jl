# Tests for @variable, DefinedOn, and DynamicVarRef (variable.jl)

@testset "DefinedOn" begin

    @testset "wraps a PhaseVarRef" begin
        m   = DynModel(Interesso.Optimizer)
        ref = @phase(m, t)
        don = DefinedOn(ref)
        @test don isa JuDO.DefinedOn
        @test don.Phase === ref
    end
end

@testset "@variable — basic registration" begin

    @testset "returns a DynamicVarRef" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        ref = @variable(m, x, DefinedOn(t))
        @test ref isa JuDO.DynamicVarRef
    end

    @testset "index, name, and model pointer" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        ref = @variable(m, x, DefinedOn(t))
        @test ref.Index == 1
        @test ref.name  == :x
        @test ref.model === m
    end

    @testset "counter incremented" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @test m.ext[:varnum][:var] == 1
    end

    @testset "name registered in lookup dict" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @test haskey(m.ext[:var_name_to_idx], :x)
        @test m.ext[:var_name_to_idx][:x] == 1
    end

    @testset "DynamicVar stored in registry" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @test haskey(m.ext[:variables], 1)
        @test m.ext[:variables][1] isa JuDO.DynamicVar
    end
end

@testset "@variable — trajectory bounds" begin

    @testset "symmetric bounds" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, -5.0 <= u <= 5.0, DefinedOn(t))
        dv = m.ext[:variables][1]
        @test dv.Trajectory_bound[1] == -5.0
        @test dv.Trajectory_bound[2] ==  5.0
    end

    @testset "asymmetric bounds" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, 0.0 <= r <= 2.0, DefinedOn(t))
        dv = m.ext[:variables][1]
        @test dv.Trajectory_bound[1] == 0.0
        @test dv.Trajectory_bound[2] == 2.0
    end

    @testset "one-sided lower bound" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x >= 0.0, DefinedOn(t))
        dv = m.ext[:variables][1]
        @test dv.Trajectory_bound[1] == 0.0
    end
end

@testset "@variable — multiple variables" begin

    @testset "sequential indices" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        r1 = @variable(m, x, DefinedOn(t))
        r2 = @variable(m, v, DefinedOn(t))
        @test r1.Index == 1
        @test r2.Index == 2
    end

    @testset "all names in lookup dict" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t)
        @variable(m, x, DefinedOn(t))
        @variable(m, v, DefinedOn(t))
        @variable(m, u, DefinedOn(t))
        @test m.ext[:varnum][:var] == 3
        @test haskey(m.ext[:var_name_to_idx], :x)
        @test haskey(m.ext[:var_name_to_idx], :v)
        @test haskey(m.ext[:var_name_to_idx], :u)
    end

    @testset "variables on different phases of same model" begin
        m = DynModel(Interesso.Optimizer)
        @phase(m, t1)
        @phase(m, t2)
        @test_nowarn @variable(m, x, DefinedOn(t1))
        @test_nowarn @variable(m, y, DefinedOn(t2))
    end
end

@testset "@variable — phase ownership" begin

    @testset "Phase field in DynamicVar matches PhaseVarRef" begin
        m    = DynModel(Interesso.Optimizer)
        tref = @phase(m, t)
        @variable(m, x, DefinedOn(t))
        dv = m.ext[:variables][1]
        @test dv.Phase === tref
    end

    @testset "cross-model phase throws an error" begin
        m1 = DynModel(Interesso.Optimizer)
        m2 = DynModel(Interesso.Optimizer)
        @phase(m1, t)
        @phase(m2, t0)
        @test_throws ErrorException @variable(m1, x, DefinedOn(t0))
    end

    @testset "error message names the offending phase" begin
        m1 = DynModel(Interesso.Optimizer)
        m2 = DynModel(Interesso.Optimizer)
        @phase(m1, t)
        @phase(m2, tau)
        err = try
            @variable(m1, x, DefinedOn(tau))
            nothing
        catch e
            e
        end
        @test err isa ErrorException
        @test occursin("tau", err.msg)
    end
end

@testset "JuMP.is_valid for DynamicVarRef" begin

    @testset "valid ref on its own model" begin
        m   = DynModel(Interesso.Optimizer)
        @phase(m, t)
        ref = @variable(m, x, DefinedOn(t))
        @test JuMP.is_valid(m, ref)
    end

    @testset "ref from different model is not valid" begin
        m1  = DynModel(Interesso.Optimizer)
        m2  = DynModel(Interesso.Optimizer)
        @phase(m1, t)
        ref = @variable(m1, x, DefinedOn(t))
        @test !JuMP.is_valid(m2, ref)
    end
end
