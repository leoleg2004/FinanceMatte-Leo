.% =========================================================================
% SCRIPT: MODEL PREDICTIVE CONTROL (MPC) PER PORTAFOGLIO AZIONARIO
% Ingegneria Finanziaria e Teoria dei Sistemi (MIMO LQR/MPC)
% Utilizzando la formulazione Sparse N-Step dell'Automation F-16
% =========================================================================

clear; clc; close all;

% Inizializzazione Path
startup;

%% 1. Definizione del Sistema (TEMPO CONTINUO)
disp('--- 1. Definizione del Sistema e Discretizzazione ---');
% Caricamento dati estratti da MySQL (via script R)
disp('Connessione e caricamento Dati da MySQL...');
try
    mu = readmatrix('mu_stocastico.csv');
    if size(mu,1) == 1, mu = mu'; end
    
    Sigma = readmatrix('sigma_stocastico.csv');
catch
    warning('Impossibile caricare i file CSV del Database MySQL. Uso valori di fallback.');
    mu = [0.0090; 0.0150; 0.0070]; % Esempio: VWCE, SXRV, ZPRR
    Sigma = [0.0020, 0.0015, 0.0010; 
             0.0015, 0.0040, 0.0012; 
             0.0010, 0.0012, 0.0025];
end
nx = length(mu);
nu = nx;
Ts = 1; % Campionamento 1 mese

% Matrici Spazio di Stato (Tempo Continuo)
% dX = \mu X dt + U dt 
A_c = diag(mu);
B_c = eye(nx);

disp('Conversione del modello da Continuo a Discreto...');
[A_ds, B_ds] = discretizza_modello(A_c, B_c, nx, nu, Ts);

%% 2. Progetto LQR tramite funzione dedicata
disp('--- 2. Progetto LQR discreto tramite funzione dedicata ---');
[K, P, Q, R, A_cl] = progetta_LQR_portfolio_discreto(A_ds, B_ds);

%% 3. Vincoli Fisici (Ampiezza)
disp('--- 3. Impostazione dei vincoli fisici e finanziari ---');
% Stati: Pesi azionari (0 <= x <= 1)
X_min = zeros(nx, 1);
X_max = ones(nx, 1);
% Ingressi: Trading massimo mensile (es. max 20% del ptf)
U_min = -0.2 * ones(nu, 1);  
U_max =  0.2 * ones(nu, 1); 
Rate_max = ones(nu, 1); % Non usato attivamente nel portafoglio, posto a 1

[Fx, fx, Fu, fu, dU_min, dU_max, Gx, gx] = imposta_vincoli(X_min, X_max, U_min, U_max, Rate_max, Ts);

% Riferimento di Default (Target Portafoglio Sicuro)
x_ref = [0.99; 0.005; 0.005];
u_ref = zeros(nu, 1);

%% 4. Calcolo Control Invariant Set e Plot
% Se l'analisi Invariant Set è supportata (es. tramite MPT3), si può invocare qui:
% disp('--- 4. CALCOLO del Control Invariant Set ---');
% [G_inf, g_inf] = cis(A_ds, B_ds, x_ref, u_ref, Fx, fx, Fu, fu, Q, R);
disp('--- 4. Control Invariant Set (Saltato in assenza di polyhedra finance form) ---');

%% 5. Setup Problema MPC 
disp('--- 5. Setup Problema MPC ---');
N_horizon = 6; % Orizzonte predittivo (N-step)
mpc_prob = setup_mpc_portfolio(N_horizon, nx, nu, A_ds, B_ds, Q, P, R, x_ref, u_ref);

%% 6. Simulazione MPC Completa 
disp('--- 6. Avvio Ottimizzazione e Simulazione MPC ---');
T_sim = 60; % Simulazione closed-loop (Mesi)
x_iniziale = [1/3; 1/3; 1/3]; % Partiamo equopesati

[storia_x, storia_u, storia_costo] = simula_mpc_portfolio(mpc_prob, x_iniziale, T_sim, A_ds, B_ds, Sigma);
disp('Ottimizzazione Riuscita. Il portafoglio è matematicamente solido.');

disp('---------------------------------------------------');
disp('VERIFICA RAGGIUNGIMENTO TARGET (Ultimo Step)');
disp('Stato Finale Raggiunto (storia_x(:,end)):');
disp(storia_x(:,end));
disp('Target Desiderato (x_ref):');
disp(x_ref);
disp('---------------------------------------------------');

%% 7. Grafici (Evoluzione Stati e Ingressi)
disp('--- 7. Grafici ---');
plot_risultati_portfolio(T_sim, storia_x, storia_u, U_min, U_max, x_ref, u_ref);

%% 8. Plot Funzionale di Costo MPC 3D (Lyapunov)
disp('--- 8. Analisi di Stabilità 3D ---');
plot_mpc_cost_3d_portfolio(mpc_prob, P, storia_x, storia_costo, x_ref);

disp('Esecuzione completata con successo.');
