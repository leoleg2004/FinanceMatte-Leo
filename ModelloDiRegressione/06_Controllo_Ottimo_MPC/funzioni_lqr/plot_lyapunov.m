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

function plot_lyapunov(P, A_cl)
    % =========================================================================
    % PLOT_LYAPUNOV - Ritratto di Fase e Funzione di Lyapunov 3D
    % Riceve in ingresso la matrice P e la matrice a ciclo chiuso A_cl
    % =========================================================================
    
    set(0,'DefaultLineLineWidth',1.5);
    set(0,'DefaultAxesFontSize',14);
    set(0,'DefaulttextInterpreter','latex');
    
    %% 1. Traiettorie (Solo dinamiche veloci)
    dxdt = @(t,x) A_cl * x;
    
    % Condizioni iniziali 
    % Matrice delle condizioni iniziali multiple (8 scenari di partenza)
% Ordine degli stati: [theta; q; u; w]
x0_mult = [
     0,    0,    0,    0,    0,    0,    0,    0;
     1.2, -1.2,  0.5, -0.5,  0.8, -0.8,  0.3, -0.3;
     0,    0,    0,    0,    0,    0,    0,    0;
    20,  -20,   15,  -15, -10,   10,   22,  -22
]; 
          
    figure('Name', 'Corto Periodo: w vs q', 'Color', 'w', 'Position', [50 100 800 600]);
    hold on; grid on;
    colori = {'r', 'g', 'b'}; 
    
    for i = 1:size(x0, 2)
        % Simuliamo solo per 3 secondi per il corto periodo
        [t, x] = ode45(dxdt, [0 3], x0(:, i)); 
        % Plot: Asse X = w (ft/s), Asse Y = q (deg/s)
        plot(x(:,4), rad2deg(x(:,2)), 'Color', colori{i});
        plot(x(1,4), rad2deg(x(1,2)), '*', 'Color', colori{i}, 'MarkerSize', 8); 
    end

    %% 2. Campo Vettoriale e Curve di Livello
    w_lim = 150;
    q_lim = 150;
    
    [W_grid, Q_deg] = meshgrid(linspace(-w_lim, w_lim, 35), linspace(-q_lim, q_lim, 35));
    Q_rad = deg2rad(Q_deg);
    
    W_dot = zeros(size(W_grid));
    Q_dot = zeros(size(Q_rad));
    V_contour = zeros(size(W_grid));
    
    for i = 1:numel(W_grid)
        % Slicing: imponiamo theta=0 e u=0
        stato = [0; Q_rad(i); 0; W_grid(i)];
        derivata = A_cl * stato;
        
        Q_dot(i) = derivata(2); 
        W_dot(i) = derivata(4); 
        V_contour(i) = stato' * P * stato;
    end
    
    % Campo vettoriale
    L = sqrt(W_dot.^2 + Q_dot.^2) + 1e-6;
    quiver(W_grid, Q_deg, W_dot./L, rad2deg(Q_dot)./L, 0.45, 'Color', [0.7 0.7 0.7]);
    
    % Curve di Livello (Spaziatura Logaritmica)
    val_min = min(V_contour(:));
    val_max = max(V_contour(:));
    livelli_log = logspace(log10(val_min + 1e-3), log10(val_max), 18);
    
    contour(W_grid, Q_deg, V_contour, livelli_log, 'LineWidth', 1.5);
    xlabel('Vertical Velocity $w$ [ft/s]') 
    ylabel('Pitch Rate $q$ [deg/s]') 
    title('Moto di Corto Periodo (Dinamica Veloce)')
    
    xlim([-w_lim, w_lim]); 
    ylim([-q_lim, q_lim]);
    legend({'Traiettoria 1', 'Start 1', 'Traiettoria 2', 'Start 2', 'Traiettoria 3', 'Start 3', ...
            'Direzione Flusso', 'Contour $V(x) = x^T P x$'}, 'Interpreter','latex', 'Location', 'bestoutside');

    %% 3. Visualizzazione 3D della Funzione di Lyapunov LQR
    figure('Name', 'Funzione di Lyapunov 3D - LQR', 'Color', 'w');
    hold on; grid on;
    
    % Superficie 3D
    V_surf = zeros(size(W_grid));
    for i = 1:size(W_grid, 1)
        for j = 1:size(W_grid, 2)
            stato_surf = [0; Q_rad(i,j); 0; W_grid(i,j)];
            V_surf(i,j) = stato_surf' * P * stato_surf;
        end
    end
    
    surf(W_grid, Q_deg, V_surf, 'EdgeColor', 'none', 'FaceAlpha', 0.7);
    colormap jet;
    colorbar;
    
    % Proiezione traiettorie 3D
    for i = 1:size(x0, 2)
        % Integrazione più fitta per fluidità visiva
        [t, x] = ode45(dxdt, linspace(0, 3, 300), x0(:, i));
        
        V_traiettoria = sum((x * P) .* x, 2); 
        
        plot3(x(:,4), rad2deg(x(:,2)), V_traiettoria, 'k-', 'LineWidth', 2);
        plot3(x(1,4), rad2deg(x(1,2)), V_traiettoria(1), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
    end
    
    title('Funzione di Lyapunov $V(x) = x^T P x$ (LQR)', 'Interpreter', 'latex')
    xlabel('$w$ [ft/s]', 'Interpreter', 'latex')
    ylabel('$q$ [deg/s]', 'Interpreter', 'latex')
    zlabel('$V(x)$', 'Interpreter', 'latex')
    view(-45, 30);
end