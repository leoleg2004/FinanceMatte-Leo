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

% =========================================================================
% Ritratto di Fase F-16: MOTO FUGOIDE (Phugoid)
% Variabili isolate: theta (deg) vs u (ft/s)
% Ing: Leggeri Leonardo
% =========================================================================


set(0,'DefaultLineLineWidth',1.5);
set(0,'DefaultAxesFontSize',14);
set(0,'DefaulttextInterpreter','latex');

% Verifica matrici
if ~exist('A_long','var') || ~exist('B_ctrl','var')
    error('Le matrici A_long e B_ctrl non sono presenti.');
end

%% 1. Progetto LQR
Q = diag([1/deg2rad(10)^2, 1/deg2rad(20)^2, 1/40^2, 1/30^2]); 
R = diag([1/5000^2, 1/25^2, 1/25^2]); 

[K, P] = lqr(A_long, B_ctrl, Q, R);
A_cl = A_long - B_ctrl * K; 

%% 2. Traiettorie (Dinamiche Lente)
dxdt = @(t,x) A_cl * x;

% Condizioni iniziali [theta_alta, q=0, u_alta, w=0]
x0 = [deg2rad(15), 0,  40, 0;   
     -deg2rad(20), 0, -30, 0;   
      deg2rad(25), 0, -20, 0]';  

figure('Name', 'Fugoide: theta vs u', 'Color', 'w', 'Position', [900 100 800 600]);
hold on; grid on;

colori = {'r', 'g', 'b'}; 
for i = 1:size(x0, 2)
    % Simuliamo per 50 secondi! Il fugoide è lentissimo.
    [t, x] = ode45(dxdt, [0 50], x0(:, i)); 
    % Plot: Asse X = theta (deg), Asse Y = u (ft/s)
    plot(rad2deg(x(:,1)), x(:,3), 'Color', colori{i});
    plot(rad2deg(x(1,1)), x(1,3), '*', 'Color', colori{i}, 'MarkerSize', 8); 
end

%% 3. Campo Vettoriale e Lyapunov del Fugoide
[THETA_deg, U_grid] = meshgrid(-100:3:100, -50:2:50);
THETA_rad = deg2rad(THETA_deg);

THETA_dot = zeros(size(THETA_rad));
U_dot = zeros(size(U_grid));
V_contour = zeros(size(THETA_rad));

for i = 1:numel(THETA_rad)
    % Isoliamo il moto: q=0 e w=0
    stato = [THETA_rad(i); 0; U_grid(i); 0];
    derivata = A_cl * stato;
    
    THETA_dot(i) = derivata(1); 
    U_dot(i) = derivata(3); 
    V_contour(i) = stato' * P * stato;
end

% Normalizziamo le frecce per vedere bene il flusso
L = sqrt(THETA_dot.^2 + U_dot.^2) + 1e-6;
quiver(THETA_deg, U_grid, rad2deg(THETA_dot)./L, U_dot./L, 0.5, 'Color', [0.7 0.7 0.7]);

% Livelli logaritmici per vedere bene il "canyon" di energia
livelli = logspace(log10(min(V_contour(:))+1e-3), log10(max(V_contour(:))), 15);
contour(THETA_deg, U_grid, V_contour, livelli, 'LineWidth', 1.5);

xlabel('Pitch Angle $\theta$ [deg]') 
ylabel('Forward Velocity $u$ [ft/s]') 
title('Moto Fugoide (Dinamica Lenta)')
xlim([-30, 30]); ylim([-50, 50]);


%% 3b. Visualizzazione 3D della Funzione di Lyapunov LQR
figure('Name', 'Funzione di Lyapunov 3D - LQR', 'Color', 'w');
hold on; grid on;

% 1. Superficie 3D V(w, q) fissando theta=0 e u=0
% Usiamo la stessa griglia usata per il contour (W_grid, Q_rad)
V_surf = zeros(size(W_grid));
for i = 1:size(W_grid, 1)
    for j = 1:size(W_grid, 2)
        stato_surf = [0; Q_rad(i,j); 0; W_grid(i,j)];
        V_surf(i,j) = stato_surf' * P * stato_surf;
    end
end

% Disegniamo la superficie
surf(W_grid, Q_deg, V_surf, 'EdgeColor', 'none', 'FaceAlpha', 0.7);
colormap jet;
colorbar;

% 2. Proiezione delle traiettorie sulla superficie 3D
for i = 1:size(x0, 2)
    [t, x] = ode45(dxdt, [0 3], x0(:, i));
    
    % Calcolo del valore di V lungo la traiettoria:
    % x è (N x 4). Dobbiamo fare x * P * x' per ogni riga.
    % Usiamo la funzione diag(x * P * x') per estrarre i risultati sulla diagonale
    V_traiettoria = sum((x * P) .* x, 2); 
    
    % Plot 3D della traiettoria
    plot3(x(:,4), rad2deg(x(:,2)), V_traiettoria, 'k-', 'LineWidth', 2);
    % Punto di inizio
    plot3(x(1,4), rad2deg(x(1,2)), V_traiettoria(1), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
end

% Grafica e Labels
title('Funzione di Lyapunov $V(x) = x^T P x$ (LQR)', 'Interpreter', 'latex')
xlabel('$w$ [ft/s]', 'Interpreter', 'latex')
ylabel('$q$ [deg/s]', 'Interpreter', 'latex')
zlabel('$V(x)$', 'Interpreter', 'latex')
view(-45, 30);

