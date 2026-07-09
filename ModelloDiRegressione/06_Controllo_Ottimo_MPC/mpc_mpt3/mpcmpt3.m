% =========================================================================
% Tesi Triennale - MPC Longitudinale F-16
% Ing.Leggeri Leonardo
% Simulazione con Conversione Continuo-Discreto (c2d) e Radianti
% Implementazione esclusiva tramite funzioni MPT3 / Esercitazione 4
% =========================================================================



% Setup Path Progetto robusto
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);

% Spostati nella cartella principale per caricare tutti i percorsi
cd(project_dir);
if exist('startup_project', 'file')
    startup_project();
end
% Ritorna nella cartella mpc_mpt3 e dalle priorità (così carica il suo cis.m)
cd(script_dir);
addpath(script_dir, '-begin');

%% 1. Definizione del Sistema (TEMPO CONTINUO)
nx = 4; % Stati: [theta,q,U,W]'
nu = 3; % Ingressi: [T, dele, dlef]'
Ts = 0.05; % Tempo di campionamento in secondi

disp('Conversione del modello da Continuo a Discreto...');
[A_long_ds, B_ctrl_ds] = discretizza_modello(A_long, B_ctrl, nx, nu, Ts);

%% 2. Progetto LQR e Vincoli
disp('Progetto LQR discreto tramite funzione dedicata...');
[K, P, Q, R, A_cl] = progetta_LQR_discreto(A_long_ds, B_ctrl_ds);

%% 3. Vincoli Fisici (Ampiezza e Rateo)
disp('Impostazione dei vincoli fisici (Ampiezza e Rateo)...');
% Ingressi: [lb, deg, deg]
U_min = [-4000; -25; -12];  
U_max = [10000;  25;  12]; 
Rate_max = [10000; 60; 25]; 

% Stati: theta(rad), q(rad/s), u(ft/s), w(ft/s)
X_max = [ deg2rad(45);  deg2rad(60);  100;  85]; 
X_min = [-deg2rad(45); -deg2rad(60); -100; -85];

[Fx, fx, Fu, fu, dU_min, dU_max, Gx, gx] = imposta_vincoli(X_min, X_max, U_min, U_max, Rate_max, Ts);

% Riferimento di Default (Origine del sistema linearizzato)
%x_ref = zeros(nx, 1);
%u_ref = zeros(nu, 1);

% =========================================================================
% ESEMPIO DI TARGET NON NULLO (Scommenta le righe seguenti per provarlo)
% Affinché l'MPC funzioni correttamente sul modello linearizzato, il nuovo 
% target DEVE essere un punto di equilibrio valido: x_ref = A_ds*x_ref + B_ds*u_ref
%
 u_ref = [1000; deg2rad(-2); 0]; % Es: +1000 lbs di spinta e -2 gradi di equilibratore (a cabrare)
 x_ref = (eye(nx) - A_long_ds) \ (B_ctrl_ds * u_ref); % Stato di equilibrio esatto associato
% =========================================================================

%% 3. Calcolo Control Invariant Set (CIS) con Polyhedron
disp('--- CALCOLO O_INF (Control Invariant Set) ---');
% Utilizza la funzione cis.m dell'esercitazione 4 (che richiede MPT3)
[G_inf, g_inf] = cis(A_long_ds, B_ctrl_ds, x_ref, u_ref, Fx, fx, Fu, fu, Q, R);
CIS = Polyhedron(G_inf, g_inf);

%% 4. Setup Problema MPC (funzioni di Esercitazione 4)
Np = 30; % Orizzonte predittivo per il controllo
disp('--- Setup Problema MPC con mpc_ingredients ---');
mpc_ingr = mpc_ingredients(A_long_ds, B_ctrl_ds, Fx, fx, Fu, fu, ...
                           G_inf, g_inf, x_ref, u_ref, Q, R, Np);

%% 6. Simulazione MPC Completa
disp('--- Avvio Ottimizzazione e Simulazione MPC ---');
% Ordine: [theta; q; u; w]
x_iniziale = [deg2rad(5);  % theta: 25 gradi convertiti in rad
              deg2rad(5);  % q: velocità angolare
              10;           % u: +20 ft/s di velocità forward
              10];          % w: velocità verticale
t_sim = 700; % Aumentato a 700 passi (Ts=0.05s) per avere 35 secondi fisici di simulazione

% Esecuzione simulazione
[storia_x, storia_u, flags] = simula_mpc_mpt3(mpc_ingr, x_iniziale, x_ref, u_ref, t_sim, A_long_ds, B_ctrl_ds, dU_max, dU_min);

disp('Ottimizzazione Riuscita!');

%% 7. Plot con libreria MPT3
plot_mpt3_sets(CIS, x_ref, storia_x);

%% 8. Grafici Standard F-16
plot_risultati(t_sim, storia_x, storia_u, U_min, U_max);
%% 9. plot clf ljapunov function


plot_lyapunov_discrete(P,A_cl,Ts);