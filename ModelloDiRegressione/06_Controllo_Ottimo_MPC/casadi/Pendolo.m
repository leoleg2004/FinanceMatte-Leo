
close all
clc

warning off all

%% importo le librerie di Casadi
addpath('/Users/leonardoleggeri/Desktop/rof.Russo/Ferramosca/casadi')
import casadi.*

%% Model

l=1;
g=9.81;
k=0.5;

x1=MX.sym('x1'); 
x2=MX.sym('x2');
x=[x1;x2];
nx=size(x,1);

u=MX.sym('u');
nu=size(u,1);

% dato che ho un modello tempo continuo:
ode=[x2;-g*sin(x1)-k*x2-u];

% continuous model
f=Function('f',{x,u},{ode},{'x','p'},{'ode'});

% discretize model with rk
Ts=.1; % tempo di campionamento
intg_options=struct;
intg_options.tf=Ts;
intg_options.simplify=true;
intg_options.number_of_finite_elements=5;

%DAE problem model
dae=struct;
dae.x=x;
dae.p=u;
dae.ode=f(x,u);
intg=integrator('intg','rk',dae,intg_options);

res=intg('x0',x,'p',u); %simbolico
x_next=res.xf;
F=Function('F',{x,u},{x_next},{'x','p'},{'x_next'}); %modello discreto (un passo)

%% control problem
opti = casadi.Opti();

N=100;

% optimzation variables
xf = opti.variable(nx,N+1);
uf = opti.variable(nu,N);
xk = opti.parameter(nx,1); %condizione iniziale

%% Cost function

Q=eye(nx);
R=eye(nu);

V=0;

for j=1:N
    L=(xf(:,j))'*Q*(xf(:,j))+(uf(:,j))'*R*(uf(:,j));
    %L=uf(:,j)^2+(xf(1,j)-xf(2,j)+5*uf(:,j))^2+2*xf(1,j);
    V=V+L;
end

m=(xf(:,N+1))'*Q*(xf(:,N+1));
V=V+m;

opti.minimize(V);

%% Constraints
opti.subject_to(xf(:,1)==xk);  %initial condition

for j=1:N
    opti.subject_to(xf(:,j+1)==F(xf(:,j),uf(:,j))); %predizione dinamica
end


%% solver
opti.solver('ipopt');
OPT_C=opti.to_function('OPT_C',{xk},{uf,xf,V},{'xk'},{'uf_opt','xf_opt','V_opt'});

%% simulation
V_track=0;
V_contr=0;

x0=[pi;0];
[uf_sol,xf_sol,V_sol]=OPT_C(x0);
uf=full(uf_sol); 
xf=full(xf_sol);
Vn=full(V_sol);

for j=1:N   
    V_track=V_track+(xf(:,j))'*(xf(:,j));
    V_contr=V_contr+(uf(:,j))'*(uf(:,j));
end

V_track=(V_track+(xf(:,N+1))'*(xf(:,N+1)))/N
V_contr=V_contr/N
%% plot

figure
subplot(2,1,1)
plot(xf(1,:),'LineWidth',2);
hold on
plot(xf(2,:),'LineWidth',2);
legend('posizione','velocità')
xlabel('samples') 
ylabel('x_1,x_2')
axis([0 100 -6 4])
subplot(2,1,2)
stairs(uf(1,:),'LineWidth',2);
legend('coppia')
xlabel('samples') 
ylabel('u')
