% =========================================================================
% Copyright (c) 2026 Ing. Leggeri Leonardo
% Tutti i diritti riservati.
%
% ATTENZIONE: Questo software e il relativo codice sorgente sono di proprietà 
% esclusiva dell'Ing. Leggeri Leonardo. È severamente vietata la copia, 
% la distribuzione, la modifica o la vendita a terzi senza l'esplicito 
% consenso scritto dell'autore. La distribuzione o la vendita non autorizzata 
% costituisce reato ed è perseguibile penalmente secondo le leggi vigenti.
% =========================================================================

clear;
clc;
close all;

set(0, 'DefaultLineLineWidth', 1.5);
set(0, 'defaultAxesFontSize', 14);
set(0, 'DefaultFigureWindowStyle', 'docked');
set(0, 'defaulttextInterpreter', 'latex');
rng('default')


%% 0. Parametri del sistema
g_grav = 9.81;
l = 0.5;
m = 0.1;
b = 1e-2;



%% 1. Invariant set per il sistema controllato
% Sampling time
Ts = 0.1; 

% Define the controlled system dynamics
A = [1 Ts;
    Ts*g_grav/l -Ts*b/(m*l^2)];
B = [0;
    Ts/l];

% Vincoli su stato e ingresso
Hx = [eye(2); 
    -eye(2)];

hx = [pi/2;
      2;
      pi/2;
      2];

Hu = [1; -1];

hu = 5*ones(2,1);

% Q, R del costo quadratico (LQR)
Q = eye(2);
R = 1;

% Calcolo 
[G, g] = cis(A,B, [0; 0], 0, Hx, hx, Hu, hu, Q, R);
CIS  = Polyhedron(G,g);
figure(1)
CIS.plot()
title('Control Invariant Set del sistema linearizzato')
xlabel('$\theta$ [rad]')
ylabel('$\dot{\theta}$ [rad/s]')
xlim([-pi, pi])
ylim([-2,2])

%% 2. N-step-controllable set (del set invariante)
Np = 10; 

[Np_steps_H, Np_steps_h] = controllable_set(Hx,hx,Hu, hu, G,g, A, B, Np);
Np_step_set = Polyhedron(Np_steps_H, Np_steps_h);

figure(2)
Np_step_set.plot('Alpha', 0);
hold on;
CIS.plot()
title(sprintf('CIS e %d step controllable set', Np))
xlabel('$\theta$ [rad]')
ylabel('$\dot{\theta}$ [rad/s]')
xlim([-pi, pi])
ylim([-2,2])

legend({sprintf('%d-step-controllable set', Np), 'Control-invariant-set'})

%% 3. Design MPC e simulazione

% Tempo di simulazione
Tsim = 60;

% Riferimento (coordinate sistema non lineare) 
x_ref = [pi; 0];
u_ref = 0;

% Riferimento (coordinate sisteama LINEARIZZATO)
x_ref_lin = [0;0];
u_ref_lin = 0;

% Ingredienti MPC
mpc_ingr = mpc_ingredients(A, B, Hx, hx, Hu, hu, ...
                            G, g, x_ref_lin, u_ref_lin, Q, R, Np);


% Simulazione
x_log = zeros(2, Tsim+1);
u_log = zeros(1, Tsim);
flags = zeros(1, Tsim); % Variabile di debug interno (variabile di ritorno dell'ottimizzatore)

x_init = [pi-0.4;
          -0.2];
% Initialize il vettore degli stati
x_log(:, 1) = x_init;

for tt = 1:Tsim
    % Stato del sistema linearizzato
    x_lin = x_log(:, tt) - x_ref; % porto lo stato reale in coordinate del sistema linearizzato

    x_lin_shifted = x_lin - x_ref_lin; % errore di tracking

    % Impostazioni MPC relative a condizione iniziale all'istante tt
    f = mpc_ingr.f_base * x_lin_shifted;
    b_ineq = mpc_ingr.b_ineq_base - mpc_ingr.b_ineq_x0_factor * x_lin_shifted; 

    % Risoluzione MPC
    [delta_u_seq, ~, exitflag] = quadprog(mpc_ingr.F, f, mpc_ingr.A_ineq, b_ineq);

    % Log dei risultati
    flags(tt) = exitflag;

    u_log(tt) = delta_u_seq(1) + u_ref;

    % Avanzamento del sistema (NON LINEARE)
    dxdt = @(t,x) pendulum(t, x, u_log(tt), g_grav, l, m, b);
    [~, xx] = ode45(dxdt, [0 Ts], x_log(:, tt));
    x_log(:, tt + 1) = xx(end, :)'; 
end


% Plot dei risultati

CIS_shifted = CIS + x_ref; 
Np_step_set_shifted = Np_step_set + x_ref

figure(3)
Np_step_set_shifted.plot('Alpha',0);
hold on
CIS_shifted.plot();
plot(x_log(1,:), x_log(2, :), 'Color',[0 0 0.5]);
% Finalize the plot with labels and title
xlabel('$\theta$ [rad]');
ylabel('$\dot{\theta}$ [rad/s]');
xlim([0, 2*pi])
ylim([-2, 2])
title('Traiettoria del sistema simulato');
