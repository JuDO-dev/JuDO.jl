@testset "test_objectives" begin

    _model = JuDO.Dy_Model()
    @independent( _model, t >= 0)
    @independent( _model,t0 = 0,type=initial)
    @independent( _model,tf = 10,type=final)
    @differential(_model,y(t),Initial_guess=10)
    @differential(_model,x(t),0<=Trajectory_bound<=100,Initial_value=0)

    @algebraic(_model,0<=u(t)<=10,Initial_guess=1,Final_value=6)
    @algebraic(_model,A(t))
    @constant(_model,d=0.5)
    @constant(_model,p=1.5)
    @constant(_model,Q=[2 0;0 2])

    @dynamic_func(_model,x(tf))
    @dynamic_func(_model,d*x(tf)*p*x(tf)*d + d*u(tf)*p*u(tf)*d) 
    @dynamic_func(_model,∫(d*x(t)*p*x(t)*d))
    @dynamic_func(_model,3*∫(d*x(t)*p*x(t)*d))
    @dynamic_func(_model,d*x(tf)*p*x(tf)*d + ∫(d*x(t)*p*x(t)*d))
    @dynamic_func(_model,d*x(tf)*p*x(tf)*d + ∫(d*x(t)*p*x(t)*d + d*u(t)*p*u(t)*d))

    @test_throws ErrorException @dynamic_func(_model,x(t))
    @test_throws ErrorException @dynamic_func(_model,d*x(tf)*p*x(t)*d)
    @test_throws ErrorException @dynamic_func(_model,∫(d*x(tf)*p*x(t)*d))

    #test for scalar quadratic term
    println("######")
    @dynamic_func(_model,x(tf)^2)
    @dynamic_func(_model,2*(u(tf)-1)^2)
    @dynamic_func(_model,2*(u(tf)-1)^2+(x(tf)-1)^2)
    @dynamic_func(_model,∫(u(t)^2+x(t)^2))
    @dynamic_func(_model,2*(u(tf)-9)^2+(x(tf)-9)^2-∫(u(t)^2+x(t)^2))
    @dynamic_func(_model,x(tf)*x(tf))
    @dynamic_func(_model,2*x(tf)*x(tf))
    @dynamic_func(_model,(u(tf)-9)*(u(tf)-9))
    @dynamic_func(_model,(u(tf)-9)*(u(tf)-9)+5*x(tf)*x(tf))
    @dynamic_func(_model,(u(tf)-9)*(u(tf)-9)+5*x(tf)*x(tf)-∫(u(t)^2+x(t)^2))

end