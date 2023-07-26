@testset "test_constraints" begin

    _model = JuDO.Dy_Model()
    @test _model isa JuDO.Dy_Model

    #registering the variables to the model, otherwise encountering any symbol unregistered will throw an error
    @independent( _model, t >= 0)
    @independent( _model,t0 == 0,initial)
    @independent( _model,tₚ == 10,final)
    @differential(_model,y(t),Initial_guess=10)
    @differential(_model,x(t),0<=Trajectory_bound<=100)

    @algebraic(_model,a(t),0<=Trajectory_bound<=1)
    @algebraic(_model,A(t),0<=Trajectory_bound<=10)
    @constant(_model,d=0.5)
    @constant(_model,p=1.5)

    #test adding initial constraints
    @test [:(a(t0)), :sin,:p] == @constraint(_model,c1,(a(t0)+3)*sin(8-2*(p*a(t0)-9))<=0,initial)

    @test [:(ẏ(t0)),:(A(t0))] == @constraint(_model,c2,ẏ(t0)==A(t0),initial)

    @test [:(ẏ(t0)),:(x(t0)),:d] == @constraint(_model,c3,ẏ(t0)x(t0)>=d,initial)

    @test [:(y(t0))] == @constraint(_model,c4,y(t0)<=10,initial)

    @test [:(ẏ(t0)),:(a(t0)),:(x(t0)),:d] == @constraint(_model,c5,ẏ(t0)+5(a(t0)*x(t0)-1)>=d,initial)

    @test_throws ErrorException @constraint(_model,c6,ẏ(t₀)==A(t₀),initial)

    @test_throws ErrorException @constraint(_model,c7,ẏ(t0)x(t)==d,initial)

    #test adding final constraints
    @test [:(sin(tₚ))] == @constraint(_model,c8,sin(tₚ)>=0,final)

    @test [:(y(tₚ)),:(a(tₚ)),:p] == @constraint(_model,c9,y(tₚ)==a(tₚ)*p,final)

    @test [:(ẏ(tₚ)),:(x(tₚ)),:d] == @constraint(_model,c10,ẏ(tₚ)x(tₚ)>=d,final)

    @test [:(y(tₚ)),:ℯ] == @constraint(_model,c11,y(tₚ)<=2*ℯ,final)

    @test [:(exp(tₚ)),:(ẏ(tₚ))] == @constraint(_model,c12,10*exp(tₚ)>=ẏ(tₚ),final) 

    @test [:(ẏ(tₚ)),:(a(tₚ)),:(x(tₚ)),:d] == @constraint(_model,c13,ẏ(tₚ)+5(a(tₚ)*x(tₚ)-1)>=d,final)

    @test_throws ErrorException @constraint(_model,c10,ẏ(tₚ)+5(a(tₚ)*x(tₚ)-1)>=d,final)

    @test_throws ErrorException @constraint(_model,c14,ẏ(t0)==A(t0),final)

    @test_throws ErrorException @constraint(_model,c15,ẏ(tₚ)x(t)==d,final)
    
    #test adding path constraints
    @test [:(a(t))] == @constraint(_model,c16,a(t)>=0,trajectory)

    @test [:(a(t)),:p] == @constraint(_model,c17,1==a(t)*p,trajectory)

    @test [:(x(t)),:log,:π,:(y(t))] == @constraint(_model,c18,x(t)==2*log(π*y(t)),trajectory)

    @test [:(y(t)),:(sin(4))] == @constraint(_model,c19,y(t)<=2*sin(4),trajectory)

    @test [:(y(t)),:(a(t)),:p] == @constraint(_model,c20,y(t)==a(t)*p,trajectory)

    @test [:(ẏ(t)),:(x(t)),:d] == @constraint(_model,c21,ẏ(t)x(t)>=d,trajectory)

    @test [:(y(t)),:π] == @constraint(_model,c22,y(t)<=10*π,trajectory)

    @test [:(ẏ(t)), :p, :(x(t)), :(A(t)), :d] == @constraint(_model,c23,ẏ(t)+5*(2-2*(p+3*(x(t)+2)*A(t)))>=d,trajectory)

    @test [:(ẏ(t)),:(A(t)),:(a(t)),:(x(t)),:d] == @constraint(_model,c25,ẏ(t)+A(t)*(a(t)*x(t)-1)>=d,trajectory)

    @test [:(ẏ(t)), :(y(t)), :(x(t)), :(a(t)), :(A(t)), :d, :p] == @constraint(_model,c24,ẏ(t)+(y(t)-3*x(t))*5*(a(t)*x(t)-1)/A(t)==d+p,trajectory)

    @test_throws ErrorException @constraint(_model,c25,ẏ(t0)x(t)>=d,trajectory)



    _model = JuDO.Dy_Model()
    @independent( _model, t >= 0)
    @independent( _model,t0 == 0,initial)
    @independent( _model,tₚ == 10,final)
    @differential(_model,y(t),Initial_guess=10)
    @differential(_model,x(t),0<=Trajectory_bound<=100)

    @algebraic(_model,a(t),0<=Trajectory_bound<=1)
    @algebraic(_model,A(t),0<=Trajectory_bound<=10)
    @constant(_model,d=0.5)
    @constant(_model,p=1.5)

    #test for checking nonlinear constraints
    @test [] == @constraint(_model,c1,2==2,trajectory)

    @test [:p,:d] == @constraint(_model,c2,p*d^3>=2,trajectory)

    @test [:p,:log,:d] == @constraint(_model,c3,p*log(d+2*(p^2-2))>=2,trajectory)

    @test [:(x(t))] == @constraint(_model,c4,x(t)>=2,trajectory)

    @test [:(x(t)),:(y(t))] == @constraint(_model,c5,x(t)*y(t)>=2,trajectory)

    @test [:(x(t)),:(y(t)),:(a(t))] == @constraint(_model,c6,x(t)*y(t)*a(t)>=2,trajectory)

    @test [:(x(t)),:(y(t)),:(a(t)),:(A(t))] == @constraint(_model,c7,x(t)/y(t)*a(t)^A(t)>=2,trajectory)

    @test [:(x(t)),:(y(t)),:(a(t))] == @constraint(_model,c8,x(t)+(y(t)*a(t))>=2,trajectory)

    @test [:(x(t)),:(y(t)),:(a(t))] == @constraint(_model,c9,x(t)+y(t)*(4*a(t))>=2,trajectory)

    @test [:(x(t)),:(y(t)),:(a(t))] == @constraint(_model,c10,x(t)+y(t)*(1-4*(a(t)+2))>=2,trajectory)

    @test [:(y(t)),:(x(t))] == @constraint(_model,c11,(1+y(t))*(1-4*(x(t)+2))>=2,trajectory)

    @test [:(y(t)),:(x(t))] == @constraint(_model,c12,y(t)*(1+2)*(1-4*(x(t)+2))>=2,trajectory)

    @test [:(y(t)),:(x(t))] == @constraint(_model,c13,y(t)/(1+3)*(1-4*(x(t)+2))>=2,trajectory)

    @test [:(x(t)),:p] == @constraint(_model,c14,(x(t)+3)/(1+3)*(1-4*(p+2*(3+2*x(t))))>=2,trajectory)

    @test [:(y(t)),:(a(t)),:p] == @constraint(_model,c15,y(t)==a(t)*p,trajectory)

    @test [:(a(t)),:(A(t)),:d] == @constraint(_model,c16,a(t)A(t)>=d,trajectory)

    @test [:(A(t)),:π] == @constraint(_model,c17,8/A(t)==π,trajectory)

    @test [:(A(t)),:π] == @constraint(_model,c18,(4-9)/((A(t)-3)*2+3)==π,trajectory)

    @test [:(x(t))] == @constraint(_model,c19,x(t)^2>=2,trajectory)

    @test [:(x(t)),:(a(t)),:p] == @constraint(_model,c20,((x(t)-1)*a(t)+9)^(p+2)>=2,trajectory)

    @test [:p,:(x(t))] == @constraint(_model,c21,(p+9)^x(t)>=2,trajectory)
end
 

#= JuDO.@independent(m,t)
JuDO.@differential(m,x(t))
JuDO.@algebraic(m,u(t))
JuDO.@constant(m,c=4)
JuDO.@dynamic_func(m,x(t)+u(t)-1) =#

