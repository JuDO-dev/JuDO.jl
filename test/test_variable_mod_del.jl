@testset "test_modify" begin
    _model = JuDO.Dy_Model()

    @independent(_model,t>=0)
    @differential(_model,zyn(t),Initial_guess=10)
    @differential(_model,n(t),0<=Initial_bound<=15)
    @algebraic(_model,u(t))

    @test [0.0, Inf] == _model.optimizer.inde_variables.traj_bound
    @test [0, Inf] == _model.Independent_var_index[:t].Bound
    @test_throws ErrorException @independent(_model,t<=10)

    @test_throws ErrorException @independent(_model,t0 =-10,type=initial)
    @test_throws ErrorException @independent(_model,0<= t0,type=initial)
    @independent(_model,t0 = 0,type=initial)
    @test [0.0, Inf] == _model.optimizer.inde_variables.traj_bound
    @test 0 == _model.Initial_Independent_var_index[:t0]

    @test_throws ErrorException @independent(_model,t0 >=-10,final)
    @independent(_model,t1 = 100,type=final)
    @test 100 == _model.Final_Independent_var_index[:t1]
    @test_throws ErrorException @independent(_model,t1 <=100,final)

    JuDO.set_independent(t0,0)
    JuDO.set_independent(t1,10)
    JuDO.set_independent(t,[90,110])
    @test [90.0,110.0]== _model.optimizer.inde_variables.traj_bound
    full_info(_model)

    JuDO.delete_independent(t0)
    JuDO.delete_independent(t1)
    JuDO.delete_independent(t)
    full_info(_model)
    @test_throws ErrorException JuDO.set_independent(t0,0)
    @test_throws ErrorException JuDO.set_independent(t1,10)
    @test_throws ErrorException JuDO.set_independent(t,[10,20])
    @independent(_model,t>=-10)
    @independent(_model,ti=-10,type=initial)
    @independent(_model,tf=100,type=final)
    @test -10 == _model.Initial_Independent_var_index[:ti]
    @test 100 == _model.Final_Independent_var_index[:tf]
    @test [-10.0, Inf] == _model.Independent_var_index[:t].Bound
    @test [-10.0, Inf] == _model.optimizer.inde_variables.traj_bound

    ########################################## test differential variables
    @test 0 == JuDO.add_initial_bound(n,[0,5])
    @test 0 == JuDO.add_trajectory_bound(n,[0,50])
    @test 0 == JuDO.add_final_bound(n,[40,Inf])
    @test 0 == JuDO.add_initial_guess(n,1)

    @test_throws ErrorException JuDO.add_initial_guess(zyn,1)

    @test 0 == JuDO.add_interpolant(n,:const)
    println(_model.Differential_var_index)
    println(_model.optimizer.diff_variables)

    @test_throws ErrorException JuDO.add_interpolant(n,:poly)

    @test 0 == JuDO.set_initial_bound(n,[-5,5],2)
    @test 0 == JuDO.set_trajectory_bound(n,[-50,50],1)
    @test 0 == JuDO.set_final_bound(zyn,[-100,100],1)
    @test 0 == JuDO.set_initial_guess(n,0)
    @test 0 == JuDO.set_interpolant(n,:poly)
    println(_model.Differential_var_index)
    println(_model.optimizer.diff_variables)

    @test_throws ErrorException JuDO.set_interpolant(zyn,:const)

    @test 0 == JuDO.delete_initial_bound(n,1)
    @test 0 == JuDO.delete_initial_bound(n,1)
    @test 0 == JuDO.add_initial_bound(n,[-10,25])
    println(_model.Differential_var_index)
    println(_model.optimizer.diff_variables)

    @test 0 == JuDO.delete_trajectory_bound(n,1)
    @test 0 == JuDO.delete_final_bound(zyn,1)
    @test 0 == JuDO.delete_initial_guess(n)
    @test 0 == JuDO.delete_interpolant(n)
    println(_model.Differential_var_index)
    println(_model.optimizer.diff_variables)

    #@test 
end

@testset "test_delete" begin
    _model = JuDO.Dy_Model()
    
end
