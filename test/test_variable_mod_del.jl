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
    @differential(_model,x(t))
    @differential(_model,y(t),0<=Trajectory_bound<=100)  
    @test_throws ErrorException @differential(_model,x(t))
    @test_throws ErrorException @differential(_model,x(t),Initial_guess=1)

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

    @differential(_model,x_new(t),Initial_value=1,Final_value=100,Initial_bound<=10)
    println(_model.Differential_var_index)

    ######### test vectorized diff_variables
    m=JuDO.Dy_Model()
    JuDO.@independent(m,t)
    JuDO.@differential(m,xx(t)[1:3])
    JuDO.@differential(m,xx1(t)[1:3],0<=Initial_bound<=15)
    JuDO.@differential(m,xx2(t)[1:2],0<=Trajectory_bound<=100,Initial_guess=1)

    println(m.Differential_var_index[:(xx_vect_1(t))])
    println(m.Differential_var_index[:(xx_vect_2(t))])
    println(m.Differential_var_index[:(xx_vect_3(t))])
    println(m.Differential_var_index[:(xx1_vect_1(t))])
    println(m.Differential_var_index[:(xx1_vect_2(t))])
    println(m.Differential_var_index[:(xx1_vect_3(t))])
    println(m.Differential_var_index[:(xx2_vect_1(t))])
    println(m.Differential_var_index[:(xx2_vect_2(t))])

    JuDO.@algebraic(m,uu(t)[1:2])
    JuDO.@algebraic(m,uu1(t)[1:3],Initial_guess=1)
    JuDO.@algebraic(m,vv(t)[1:3]<=10)
    JuDO.@algebraic(m,1<=vv1(t)[1:2]<=10,Interpolant=c,Final_value=0)

    @test_throws ErrorException @algebraic(m,0<=uut(t)<=-10)

    println(m.Algebraic_var_index[:(uu_vect_1(t))])
    println(m.Algebraic_var_index[:(uu_vect_2(t))])
    println(m.Algebraic_var_index[:(uu1_vect_1(t))])
    println(m.Algebraic_var_index[:(uu1_vect_2(t))])
    println(m.Algebraic_var_index[:(uu1_vect_3(t))])
    println(m.Algebraic_var_index[:(vv_vect_1(t))])
    println(m.Algebraic_var_index[:(vv_vect_2(t))])
    println(m.Algebraic_var_index[:(vv_vect_3(t))])
    println(m.Algebraic_var_index[:(vv1_vect_1(t))])
    println(m.Algebraic_var_index[:(vv1_vect_2(t))])

    ########################################## test algebraic variables
    @algebraic(_model,v(t)<=10,Initial_guess=1)
    @algebraic(_model,w(t),Initial_guess=1)
    @algebraic(_model,0<=h(t)<=1) 
    @algebraic(_model,j(t)>=0,Interpolant=c)
    @algebraic(_model,l(t)>=0,Interpolant=c,Initial_guess=1)

    @algebraic(_model,1<=v_new(t)<=10,Initial_value=1,Initial_guess=1)
    @algebraic(_model,v_new1(t),Final_value=0,Initial_guess=1,Interpolant=c)

    @test [-Inf, Inf] == _model.Algebraic_var_index[:(u(t))].Bound
    @test [-Inf, 10.0] == _model.Algebraic_var_index[:(v(t))].Bound
    @test 1 == _model.Algebraic_var_index[:(v(t))].Initial_guess
    @test [-Inf, Inf] == _model.Algebraic_var_index[:(w(t))].Bound
    @test 1 == _model.Algebraic_var_index[:(w(t))].Initial_guess
    @test [0.0, 1.0] == _model.Algebraic_var_index[:(h(t))].Bound
    @test [0.0, Inf] == _model.Algebraic_var_index[:(j(t))].Bound
    @test :c == _model.Algebraic_var_index[:(j(t))].Interpolant
    @test [0.0, Inf] == _model.Algebraic_var_index[:(l(t))].Bound
    @test 1 == _model.Algebraic_var_index[:(l(t))].Initial_guess
    @test :c == _model.Algebraic_var_index[:(l(t))].Interpolant
    @test 1 == _model.Algebraic_var_index[:(v_new(t))].Initial_value
    @test 1 == _model.Algebraic_var_index[:(v_new(t))].Initial_guess
    @test 0 == _model.Algebraic_var_index[:(v_new1(t))].Final_value

    println(_model.optimizer.alge_variables)

    @test_throws ErrorException @algebraic(_model,u(t))
    @test_throws ErrorException @algebraic(_model,100<=i(t)<=10,Initial_guess=1)
#=     @test_throws ErrorException @algebraic(_model,i(t),Initial_guess=p)
    @test_throws ErrorException @algebraic(_model,1<=i(t)<=10,Initial_guess=p)
    @test_throws ErrorException @algebraic(_model,1<=i(t)<=10,Initial_guess=1,Interpolant=1) =#

    JuDO.add_interpolant(v,:poly)
    @test :poly == _model.Algebraic_var_index[:(v(t))].Interpolant
    @test_throws ErrorException JuDO.add_interpolant(v,:c)
    @test_throws ErrorException JuDO.add_interpolant(j,:c)

    JuDO.add_trajectory_bound(w,[-10,10])
    @test [-10.0, 10.0] == _model.Algebraic_var_index[:(w(t))].Bound
    @test_throws ErrorException JuDO.add_trajectory_bound(v,[-10,10])

    JuDO.add_initial_guess(h,0.5)
    @test 0.5 == _model.Algebraic_var_index[:(h(t))].Initial_guess
    @test_throws ErrorException JuDO.add_initial_guess(v,0.5)
    @test_throws ErrorException JuDO.add_initial_guess(l,0.5)

    JuDO.set_interpolant(j,:poly)
    @test :poly == _model.Algebraic_var_index[:(j(t))].Interpolant
    JuDO.set_interpolant(l,:poly)
    @test :poly == _model.Algebraic_var_index[:(l(t))].Interpolant
    @test_throws ErrorException JuDO.set_interpolant(w,:poly)
    @test_throws ErrorException JuDO.set_interpolant(h,:c)
 
    JuDO.set_initial_guess(h,1)
    @test 1 == _model.Algebraic_var_index[:(h(t))].Initial_guess
    @test_throws ErrorException JuDO.set_initial_guess(j,1)

    JuDO.set_trajectory_bound(w,[-5,5])
    @test [-5.0, 5.0] == _model.Algebraic_var_index[:(w(t))].Bound
    @test_throws ErrorException JuDO.set_trajectory_bound(v,[10,Inf])

    println(_model.optimizer.alge_variables)
    #JuDO.delete_interpolant(v)

end

@testset "test_delete" begin
    _model = JuDO.Dy_Model()
    
end
