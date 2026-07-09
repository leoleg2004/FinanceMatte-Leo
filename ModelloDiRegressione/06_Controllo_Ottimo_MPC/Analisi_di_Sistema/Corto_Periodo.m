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
% Ritratto di Fase F-16: MOTO DI CORTO PERIODO (Short Period)
% Variabili isolate: w (ft/s) vs q (deg/s)
% Ing: Leggeri Leonardo
% =========================================================================


set(0,'DefaultLineLineWidth',1.5);
set(0,'DefaultAxesFontSize',14);
set(0,'DefaulttextInterpreter','latex');



%% 1. Progetto LQR
% Ordine stati: [theta, q, u, w]
Q = diag([1/deg2rad(10)^2, 1/deg2rad(20)^2, 1/40^2, 1/30^2]); 
R = diag([1/5000^2, 1/25^2, 1/25^2]); 

[K, P] = lqr(A_long, B_ctrl, Q, R);
A_cl = A_long - B_ctrl * K; 

%% 2. Traiettorie (Solo dinamiche veloci)
dxdt = @(t,x) A_cl * x;

% Condizioni iniziali [theta=0, q_alta, u=0, w_alta]
x0 = [0.785,  0.3, 10,  5;   
      0, -0.6, 0, -40;   
      0.2,  0.4, 20, -20]';  

figure('Name', 'Corto Periodo: w vs q', 'Color', 'w', 'Position', [50 100 800 600]);
hold on; grid on;

colori = {'r', 'g', 'b'}; 
for i = 1:size(x0, 2)
    % Simuliamo solo per 3 secondi! Il corto periodo è velocissimo.
    [t, x] = ode45(dxdt, [0 3], x0(:, i)); 
    % Plot: Asse X = w (ft/s), Asse Y = q (deg/s)
    plot(x(:,4), rad2deg(x(:,2)), 'Color', colori{i});
    plot(x(1,4), rad2deg(x(1,2)), '*', 'Color', colori{i}, 'MarkerSize', 8); 
end

%% 3. Campo Vettoriale e Lyapunov del Corto Periodo
% ---> GRIGLIA ALLARGATA: da -150 a 150
w_lim = 150;
q_lim = 150;
% Usiamo linspace per avere una griglia uniforme e non troppo fitta per il quiver
[W_grid, Q_deg] = meshgrid(linspace(-w_lim, w_lim, 35), linspace(-q_lim, q_lim, 35));
Q_rad = deg2rad(Q_deg);

W_dot = zeros(size(W_grid));
Q_dot = zeros(size(Q_rad));
V_contour = zeros(size(W_grid));

for i = 1:numel(W_grid)
    % Isoliamo il moto: theta=0 e u=0
    stato = [0; Q_rad(i); 0; W_grid(i)];
    derivata = A_cl * stato;
    
    Q_dot(i) = derivata(2); 
    W_dot(i) = derivata(4); 
    V_contour(i) = stato' * P * stato;
end

% Normalizziamo le frecce per vedere bene il flusso senza "macchie" di colore
L = sqrt(W_dot.^2 + Q_dot.^2) + 1e-6;
quiver(W_grid, Q_deg, W_dot./L, rad2deg(Q_dot)./L, 0.45, 'Color', [0.7 0.7 0.7]);

% ---> CURVE DI LIVELLO OTTIMIZZATE (Spaziatura Logaritmica)
val_min = min(V_contour(:));
val_max = max(V_contour(:));
% Calcoliamo 18 livelli logaritmici per una resa visiva eccellente
livelli_log = logspace(log10(val_min + 1e-3), log10(val_max), 18);

% Plot delle curve
contour(W_grid, Q_deg, V_contour, livelli_log, 'LineWidth', 1.5);

xlabel('Vertical Velocity $w$ [ft/s]') 
ylabel('Pitch Rate $q$ [deg/s]') 
title('Moto di Corto Periodo (Dinamica Veloce)')

% ---> IMPOSTAZIONE DEI NUOVI LIMITI DEGLI ASSI
xlim([-w_lim, w_lim]); 
ylim([-q_lim, q_lim]);

% Aggiungiamo la legenda coerente
legend({'Traiettoria 1', 'Start 1', 'Traiettoria 2', 'Start 2', 'Traiettoria 3', 'Start 3', ...
        'Direzione Flusso', 'Contour $V(x) = x^T P x$'}, 'Interpreter','latex', 'Location', 'bestoutside');

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
view(-45, 30); questo codcie funziona perfettament eusalo nella funzione 