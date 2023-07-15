@testset "test_constraints" begin

    _model = JuDO.Dy_Model()
    @test _model isa JuDO.Dy_Model

    #registering the variables to the model, otherwise encountering any symbol unregistered will throw an error
    @independent_variable( _model, t >= 0)
    @differential_variable(_model,y,Initial_guess=10)
    @differential_variable(_model,x,0<=Trajectory_bound<=100)

    @algebraic_variable(_model,a,0<=Trajectory_bound<=1)
    @algebraic_variable(_model,A,0<=Trajectory_bound<=10)
    @constant(_model,d=0.5)
    @constant(_model,p=1.5)

    #test adding initial constraints
    @test [:(a(t0))] == @constraint(_model,c4,a(t0)<=10,initial)

    @test [:(ẏ(t0)),:(A(t0))] == @constraint(_model,c1,ẏ(t0)==A(t0),initial)

    @test [:(ẏ(t0)),:(x(t0)),:d] == @constraint(_model,c2,ẏ(t0)x(t0)>=d,initial)

    @test [:(y(t0))] == @constraint(_model,c3,y(t0)<=10,initial)

    @test [:(ẏ(t0)),:(a(t0)),:(x(t0)),:d] == @constraint(_model,c2,ẏ(t0)+5(a(t0)*x(t0)-1)>=d,initial)

    @test_throws ErrorException @constraint(_model,c5,ẏ(t₀)==A(t₀),initial)

    @test_throws ErrorException @constraint(_model,c6,ẏ(t0)x(t)==d,initial)

    #test adding final constraints
    @test [:(a(tₚ))] == @constraint(_model,c1,a(tₚ)>=0,final)

    @test [:(y(tₚ)),:(a(tₚ)),:p] == @constraint(_model,c2,y(tₚ)==a(tₚ)*p,final)

    @test [:(ẏ(tₚ)),:(x(tₚ)),:d] == @constraint(_model,c3,ẏ(tₚ)x(tₚ)>=d,final)

    @test [:(y(tₚ)),:ℯ] == @constraint(_model,c4,y(tₚ)<=2*ℯ,final)

    @test [:(exp(tₚ)),:(ẏ(tₚ))] == @constraint(_model,c1,10*exp(tₚ)>=ẏ(tₚ),final)

    @test [:(ẏ(tₚ)),:(a(tₚ)),:(x(tₚ)),:d] == @constraint(_model,c5,ẏ(tₚ)+5(a(tₚ)*x(tₚ)-1)>=d,final)

    @test_throws ErrorException @constraint(_model,c6,ẏ(t0)==A(t0),final)

    @test_throws ErrorException @constraint(_model,c7,ẏ(tₚ)x(t)==d,final)
    
    #test adding path constraints
    @test [:(a(t))] == @constraint(_model,c1,a(t)>=0,trajectory)

    @test [:(a(t)),:p] == @constraint(_model,c2,1==a(t)*p,trajectory)

    @test [:(x(t)),:(sin(t))] == @constraint(_model,c3,x(t)==2*sin(t),trajectory)

    @test [:(y(t)),:sin,:((x(t)))] == @constraint(_model,c4,y(t)<=2*sin(x(t)),trajectory)

    @test [:(y(t)),:(a(t)),:p] == @constraint(_model,c2,y(t)==a(t)*p,trajectory)

    @test [:(ẏ(t)),:(x(t)),:d] == @constraint(_model,c3,ẏ(t)x(t)>=d,trajectory)

    @test [:(y(t)),:π] == @constraint(_model,c4,y(t)<=10*π,trajectory)

    @test [:(ẏ(t)),:(A(t)),:(a(t)),:(x(t)),:d] == @constraint(_model,c5,ẏ(t)+5A(t)*(a(t)*x(t)-1)>=d,trajectory)

    @test [:(ẏ(t)),:(A(t)),:log,:(y(t)),:(x(t)),:(a(t)),:d,:p] == @constraint(_model,c6,ẏ(t)+5A(t)*log(y(t)-3*x(t))*(a(t)*x(t)-1)==d+p,trajectory)

    @test_throws ErrorException @constraint(_model,c7,ẏ(t0)x(t)>=d,trajectory)


    _model = JuDO.Dy_Model()
    @independent_variable( _model, time >= 0)
    @differential_variable(_model,y,Initial_guess=10)
    @differential_variable(_model,x,0<=Trajectory_bound<=100)

    @algebraic_variable(_model,a,0<=Trajectory_bound<=1)
    @algebraic_variable(_model,A,0<=Trajectory_bound<=10)
    @constant(_model,d=0.5)
    @constant(_model,p=1.5)

    #test adding path constraints
    @test [:(y(time)),:(a(time)),:p] == @constraint(_model,c2,y(time)==a(time)*p,trajectory)

    @test [:(ẏ(time)),:(x(time)),:d] == @constraint(_model,c3,ẏ(time)x(time)>=d,trajectory)

end
 

