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

close all
clc
warning off all

%% Importo le librerie di Casadi
addpath('/Users/leonardoleggeri/Desktop/AutomationF16/prof.Russo/Studio_MIMO/MIMO/F16MIMO/casadi')
import casadi.*

%% 1. ESTRAZIONE VARIABILI CON FUNZIONE LQR CLASSICA (Per Simulink)
% Estraiamo le dimensioni dalle matrici presenti nel workspace
nx = size(A_long, 1);
nu = size(B_long, 2);

% Pesi logica pura (Aggressivo)
Q = 1 * eye(nx);
R = 5 * eye(nu);

% Usa la funzione ufficiale lqr per calcolare le 3 variabili che volevi
[K, P, E] = lqr(A_long, B_long, Q, R);

disp('--- Variabili LQR calcolate (Controlla il tuo Workspace) ---');
disp('Guadagno K calcolato. (Usalo nel Gain di Simulink come -K)');
disp('Matrice di Riccati P calcolata.');
disp('Autovalori a ciclo chiuso E calcolati.');
disp(' ');

%% 2. MODELLO CASADI (F-16 Longitudinal Dynamics)
x = MX.sym('x', nx);
u = MX.sym('u', nu);

ode = A_long * x + B_long * u;

Ts = 0.05; % tempo di campionamento
intg_options = struct;
intg_options.tf = Ts;
intg_options.number_of_finite_elements = 5;

dae = struct;
dae.x = x;
dae.p = u;
dae.ode = ode;

intg = integrator('intg', 'rk', dae, intg_options);
res = intg('x0', x, 'p', u); 
x_next = res.xf;
F = Function('F', {x, u}, {x_next}, {'x', 'p'}, {'x_next'}); 

%% 3. PROBLEMA DI CONTROLLO CASADI (Logica pura LQR)
opti = casadi.Opti();
N = 100;

% Optimization variables
xf = opti.variable(nx, N+1);
uf = opti.variable(nu, N);
xk = opti.parameter(nx, 1); 

%% Cost function
V = 0;
for j = 1:N
    L = (xf(:,j))' * Q * (xf(:,j)) + (uf(:,j))' * R * (uf(:,j));
    V = V + L;
end

% IL TRUCCO DELL'LQR IN CASADI: 
% Invece di usare Q per l'ultimo step, usiamo la matrice P calcolata prima!
% Questo fa sì che CasADi replichi in modo puro l'orizzonte infinito dell'LQR.
costo_terminale = (xf(:,N+1))' * P * (xf(:,N+1));
V = V + costo_terminale;

opti.minimize(V);

%% Constraints (Solo la dinamica del sistema)
opti.subject_to(xf(:,1) == xk);  
for j = 1:N
    opti.subject_to(xf(:,j+1) == F(xf(:,j), uf(:,j))); 
end
% --- All'interno del ciclo dei vincoli ---
for j = 1:N
    % 1. Vincolo Dinamico (fondamentale)
    opti.subject_to(xf(:,j+1) == F(xf(:,j), uf(:,j))); 
    
    % 2. Vincolo su q (Seconda variabile del vettore x)
    % Limitiamo la rotazione a +/- 0.4 rad/s
    opti.subject_to(-0.4 <= xf(2,j) <= 0.4);
    
    % 3. Vincolo opzionale su w (Quarta variabile)
    % w è legato all'angolo d'attacco (alpha). 
    % Se vuoi evitare che l'aereo "spanci" troppo verso il basso o l'alto:
     opti.subject_to(-10 <= xf(4,j) <= 10); 
end

%% Solver
p_opts = struct('expand', true);
s_opts = struct('max_iter', 1000, 'print_level', 0, 'sb', 'yes');
opti.solver('ipopt', p_opts, s_opts);
OPT_C = opti.to_function('OPT_C', {xk}, {uf, xf, V}, {'xk'}, {'uf_opt', 'xf_opt', 'V_opt'});

%% 4. SIMULAZIONE E PLOT
% Botta iniziale (perturbazione)
%x0 = [0.4; 0.2; 30; 15]; %teta,q,U,W simula un pull-up ho un  improvvisa corrente di vento che alza il muso sono in radianti
%teta=23 gradi in su , q=11.5 gradi ruota verso l'alto, U l'aereo accellera
%30 m/s, 15 m/s velocità verticale verso il basso per via del ned axis, 


%questa e una partenza disturbata da un movimento improvviso dell'assetto
%che porta l'areo di 45 gradi rispetto alla verticale 
x0=[0.785; 0.3; 10; 5];
[uf_sol, xf_sol, V_sol] = OPT_C(x0);

uf = full(uf_sol); 
xf = full(xf_sol);

%% Grafici
figure('Name', 'CasADi: Pura logica LQR con costo terminale P')

subplot(2, 1, 1)
plot(xf(1,:), 'LineWidth', 2); hold on;
plot(xf(2,:), 'LineWidth', 2);
plot(xf(3,:), 'LineWidth', 2);
plot(xf(4,:), 'LineWidth', 2);
legend('\theta (Beccheggio)', 'q (Vel. Beccheggio)', 'U (Vel. X)', 'W (Vel. Z)')
xlabel('samples') 
ylabel('Stati')
grid on;

subplot(2, 1, 2)
for k = 1:nu
    stairs(uf(k,:), 'LineWidth', 2); hold on;
end
xlabel('samples') 
ylabel('Comandi (u)')
grid on;