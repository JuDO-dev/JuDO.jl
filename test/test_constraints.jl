@testset "test_constraints" begin

    _model = JuDO.Dy_Model()
    @test _model isa JuDO.Dy_Model

    #registering the variables to the model, otherwise encountering any symbol unregistered will throw an error
    @independent( _model, t >= 0)
    @independent( _model,t0 = 0,type=initial)
    @independent( _model,tₚ = 10,type=final)
    @differential(_model,y(t),Initial_guess=10)
    @differential(_model,x(t),0<=Trajectory_bound<=100)

    @algebraic(_model,0<=a(t)<=10,Initial_guess=1)
    @algebraic(_model,A(t))
    @constant(_model,d=0.5)
    @constant(_model,p=1.5)
    @constant(_model,Q=[2 0;0 2])

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
    @independent( _model,t0 = 0,type=initial)
    @independent( _model,tₚ = 10,type=final)
    @differential(_model,y(t),Initial_guess=10)
    @differential(_model,x(t),0<=Trajectory_bound<=100)

    @algebraic(_model,a(t)>=0)
    @algebraic(_model,A(t),Interpolant=c)
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
 
## usecase for cartpole.jl
#= m=JuDO.Dy_Model()
JuDO.@independent( m,0 <= t <= 5)
JuDO.@independent( m,t0,type=initial)
JuDO.@independent( m,tf,type=final)
JuDO.@algebraic(m,-3<=u(t)<=3)
JuDO.@constant(m,Q = [0.01 0 0 0; 0 0.01 0 0; 0 0 0.01 0; 0 0 0 0.01])
JuDO.@constant(m,Qf = [100 0 0 0; 0 100 0 0; 0 0 100 0; 0 0 0 100])
JuDO.@constant(m,R = 0.1)
JuDO.@differential(m,xx(t)[1:4],Initial_value=0,Final_value=0)
JuDO.@objective_func(m,(xx(tf)-[0; pi; 0; 0])'*Qf*(xx(tf)-[0; pi; 0; 0])+∫((xx(t)-[0; pi; 0; 0])'*Q*(xx(t)-[0; pi; 0; 0])+R*u(t)*u(t)))
JuDO.set_final_value(xx[2],pi)
JuDO.set_meshpoints(m,101)
JuDO.optimize!(m)

##usecase for car.jl
m=JuDO.Dy_Model()
JuDO.@independent( m,0 <= t <= 10)
JuDO.@independent( m,t0,type=initial)
JuDO.@independent( m,tf,type=final)
JuDO.@algebraic(m,-10<=u(t)[1:2]<=10)
JuDO.@constant(m,Q = [0.1 0 0; 0 0.01 0; 0 0 0.01])
JuDO.@constant(m,Qf = [0.1 0 0; 0 0.1 0; 0 0 0.1])
JuDO.@constant(m,R = [0.5 0;0 0.5])
JuDO.@differential(m,xx(t)[1:3],Initial_value=0,Final_value=5)
JuDO.@objective_func(m,((xx(tf)-[5; 5; 0])'*Qf*(xx(tf)-[5; 5; 0])+∫((xx(t)-[5; 5; 0])'*Q*(xx(t)-[5; 5; 0])+u(t)'*R*u(t))))
JuDO.set_final_value(xx[3],pi/2)
JuDO.set_meshpoints(m,101)
JuDO.optimize!(m)


## usecase for the 1 x 1 u model
m=JuDO.Dy_Model()
JuDO.@independent( m,0 <= t <= 15)
JuDO.@independent( m,t0,type=initial)
JuDO.@independent( m,tf,type=final)
JuDO.@algebraic(m,-10<=u(t)<=10)
JuDO.@constant(m,Q = 0.1)
JuDO.@constant(m,Qf = 0.1)
JuDO.@constant(m,R = 0.5)
JuDO.@differential(m,xx(t),Initial_value=0,Final_value=5)
JuDO.@objective_func(m,(Qf*(xx(tf)-5)^2+∫(Q*(xx(t)-5)^2+u(t)^2)))
JuDO.set_meshpoints(m,20)
JuDO.@dynamics(m, ẏ(t) == 2 + u(t))
JuDO.optimize!(m)


#
@parameter(m, 4.0 <= tf <= 5.0)
@ind(m, 0.0 <= t <= tf)

JuDO.@objective_func(m,xx(tf)'*Qf*xx(tf))
JuDO.@objective_func(m,xx(tf)'*[100 0 0 0; 0 100 0 0; 0 0 100 0; 0 0 0 100]*xx(tf))
JuDO.@objective_func(m,∫(xx(t)'*Q*xx(t)+0.1*u(t)*u(t)))
JuDO.@objective_func(m,∫(xx(t)'*[0.01 0 0 0; 0 0.01 0 0; 0 0 0.01 0; 0 0 0 0.01]*xx(t)+0.1*u(t)*u(t)))


JuDO.@objective_func(m,x(tf)^2+∫(u(t)^2+x(t)^2))
JuDO.set_meshpoints(m,101)


JuDO.@objective_func(m,6*x(t)^2)
JuDO.@objective_func(m,x(t)^2)
JuDO.@objective_func(m,2*(u(t)-9)^2+(x(t)-9)^2)
JuDO.@objective_func(m,∫(u(t)^2+x(t)^2))
JuDO.@objective_func(m,(u(t)-9)^2+5*x(t)^2)
JuDO.@objective_func(m,2*(u(t)-9)^2+(x(t)-9)^2-∫(u(t)^2+x(t)^2))

JuDO.@objective_func(m,u(t)+5*x(t)^2),
JuDO.@objective_func(m,u(t)+5*x(t))
JuDO.@objective_func(m,3*(6*x(t)^2))

JuDO.@algebraic(m,uop(t)[1:3],Initial_guess=1)
JuDO.@algebraic(m,v(t)[1:3]<=10)
JuDO.@algebraic(m,1<=vc(t)[1:3]<=10,Interpolant=c)

JuDO.@differential(m,xx(t)[1:3])
JuDO.@differential(m,xx1(t)[1:3],0<=Initial_bound<=15)

JuDO.@algebraic(m,u(t))
JuDO.@algebraic(m,v(t)<=10,Initial_guess=1)
JuDO.@algebraic(m,w(t),Initial_guess=1)
JuDO.@algebraic(m,0<=h(t)<=1)

JuDO.@independent(m,tf=100,type=final)
JuDO.@independent(m,t0=0,type=initial)
JuDO.@differential(m,n(t),0<=Initial_bound<=15)

JuDO.@constant(m,c=4)
JuDO.add_initial_bound(n,[0,5])
JuDO.add_trajectory_bound(n,[0,50])
JuDO.add_final_bound(n,[40,Inf])
JuDO.add_interpolant(n,:const)
JuDO.set_initial_bound(n,[-5,5],2)

JuDO.add_initial_bound(n,[-10,25])
JuDO.add_initial_bound(n,[-3,52])
JuDO.delete_initial_bound(n,1)
JuDO.delete_initial_bound(n,1)
JuDO.set_initial_guess(n,1)
JuDO.set_initial_bound(n,[-5,5],1)
JuDO.delete_initial_bound(n,1)

JuDO.full_info(m)
m.optimizer.diff_variables
m.optimizer.inde_variables

JuDO.@objective_func(m,x(t)+u(t)-1) =#
#= function _finalize_dy_macro(model, code, source::LineNumberNode)
    return Expr(
        :block,
        source,
        code,
    )
end =#

"""
julia> v=collect(values(d))[3]
1-element Vector{Vector{Int64}}:
 [3, 2]

julia> push!(v,[1,1])
2-element Vector{Vector{Int64}}:
 [3, 2]
 [1, 1]

julia> d
OrderedDict{Any, Any} with 3 entries:
  1   => 'c'
  'a' => 'e'
  3   => [[3, 2], [1, 1]]
"""
