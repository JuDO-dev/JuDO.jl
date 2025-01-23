using JuMP
using DynOptInterface
using Interesso
@testset "test_var" begin
    m=JuDO.DynModel(Interesso.Optimizer)
    JuMP.@variable(m, t, JuDO.Phase)
    JuMP.@variable(m, x<=10.0, JuDO.Dynamic(t))
    JuMP.@variable(m, y>=-2.0, JuDO.Dynamic(t))
    JuMP.@constraint(m,c1,t==1,DynOptInterface.Initial)
    JuMP.@constraint(m,c2,t==10,DynOptInterface.Final)

    JuDO.@phase(m,t)
    JuMP.@variable(m, x, JuDO.Dynamic(t))
    JuMP.@variable(m, y, JuDO.Dynamic(t))
    JuMP.@constraint(m,c1,t==1,DynOptInterface.Initial)
    # @test t.Sym == :t
    # @test t.Initial == -Inf
    # @test t.Final == Inf
    
    
    # JuDO.@dynamic_variable(m,x,t)

    # x1=JuDO.LinearDynamicTerm(2,d)
    # x2=JuDO.LinearDynamicTerm(5,d)
    # x3=JuDO.LinearDynamicTerm(9,d)

    # t1 = x1+x2
    # t2 = x2+x1
    # t3 = (x1+x2)*3
    # t4 = (x1+x3) + x2
    # @test t1.coefficient == 7
    # @test t2.coefficient == 7
    # @test t3.coefficient == 21
    # @test t4.coefficient == 16
    # @test t1.dyn_var == d
    # @test t2.dyn_var == d
    # @test t3.dyn_var == d
    # @test t4.dyn_var == d

    # t1 = x1 - x2
    # t2 = x2 - x1
    # t3 = 2*(x1-x3)
    # @test t1.coefficient == -3
    # @test t2.coefficient == 3
    # @test t3.coefficient == -14
    # @test t1.dyn_var == d
    # @test t2.dyn_var == d
    # @test t3.dyn_var == d

    # # Multiplication
    # t1 = x1 * x2
    # t2 = x2 * x1
    # t3 = x1 * 3 * x3
    # @test t1.coefficient == 10
    # @test t2.coefficient == 10
    # @test t3.coefficient == 54
    # @test t1.dyn_var == d
    # @test t2.dyn_var == d
    # @test t3.dyn_var == d

    # # Division
    # t1 = x1 / x2
    # t2 = x2 / x1
    # @test t1 == 0.4
    # @test t2 == 2.5

    # # Scalar multiplication
    # t1 = 3 * x1
    # t2 = x1 * 3
    # @test t1.coefficient == 6
    # @test t2.coefficient == 6
    # @test t1.dyn_var == d
    # @test t2.dyn_var == d

    # m=JuDO.Dy_Model()
    # JuDO.@phase(m,t)

    # @test m.Independent_var_index["t"]
end

# @testset "test extension" begin
#     m = Model()
#     @variable(m, x[i=1:2], variable_type = Dy_var, kw = i)
# end