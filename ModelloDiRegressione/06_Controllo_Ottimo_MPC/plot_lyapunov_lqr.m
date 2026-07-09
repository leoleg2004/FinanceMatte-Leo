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

function plot_lyapunov_lqr(P, A_cl)
    % =========================================================================
    % PLOT_LYAPUNOV - Ritratto di Fase e Funzione di Lyapunov 3D
    % Riceve in ingresso la matrice P e la matrice a ciclo chiuso A_cl
    % =========================================================================
    
    set(0,'DefaultLineLineWidth',1.5);
    set(0,'DefaultAxesFontSize',14);
    set(0,'DefaulttextInterpreter','latex');
    
    %% 1. Traiettorie (Solo dinamiche veloci)
    dxdt = @(t,x) A_cl * x;
    
    % Matrice delle condizioni iniziali multiple (8 scenari di partenza)
    % Ordine degli stati: [theta; q; u; w]
    x0_mult = [
         0,    0,    0,    0,    0,    0,    0,    0;
         1.2, -1.2,  0.5, -0.5,  0.8, -0.8,  0.3, -0.3;
         0,    0,    0,    0,    0,    0,    0,    0;
        20,  -20,   15,  -15, -10,   10,   22,  -22
    ]; 
          
    figure('Name', 'Ritratto di Fase LQR', 'Color', 'w', 'Position', [50 100 800 600]);
    hold on; grid on;
    
    % Generiamo automaticamente una palette di colori per le N traiettorie
    num_simulazioni = size(x0_mult, 2);
    colori = lines(num_simulazioni); 
    
    for i = 1:num_simulazioni
        % Simuliamo solo per 3 secondi per il corto periodo
        [~, x] = ode45(dxdt, [0 3], x0_mult(:, i)); 
        
        % Salviamo gli handle solo della prima iterazione per una legenda pulita
        if i == 1
            h_traj = plot(x(:,4), rad2deg(x(:,2)), 'Color', colori(i,:));
            h_start = plot(x(1,4), rad2deg(x(1,2)), '*', 'Color', colori(i,:), 'MarkerSize', 8); 
        else
            plot(x(:,4), rad2deg(x(:,2)), 'Color', colori(i,:));
            plot(x(1,4), rad2deg(x(1,2)), '*', 'Color', colori(i,:), 'MarkerSize', 8); 
        end
    end
    
    %% 2. Campo Vettoriale e Curve di Livello
   
    % Riduciamo la griglia per "abbracciare" esattamente le tue condizioni iniziali
    w_lim = 45;  
    q_lim = 75;  
    [W_grid, Q_deg] = meshgrid(linspace(-w_lim, w_lim, 80), linspace(-q_lim, q_lim, 80));
   
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
    h_quiv = quiver(W_grid, Q_deg, W_dot./L, rad2deg(Q_dot)./L, 0.45, 'Color', [0.7 0.7 0.7]);
    
    % Curve di Livello (Spaziatura Logaritmica)
    val_min = min(V_contour(:));
    val_max = max(V_contour(:));
    livelli_log = logspace(log10(val_min + 1e-3), log10(val_max), 18);
    
    [~, h_cont] = contour(W_grid, Q_deg, V_contour, livelli_log, 'LineWidth', 1.5);
    
    xlabel('Vertical Velocity $w$ [ft/s]') 
    ylabel('Pitch Rate $q$ [deg/s]') 
    title('Ritratto di fase')
    
    xlim([-w_lim, w_lim]); 
    ylim([-q_lim, q_lim]);
    
    % Legenda dinamica e pulita (solo 4 voci invece di 18)
    legend([h_traj, h_start, h_quiv, h_cont], ...
           {'Traiettorie di Stato', 'Punti di Partenza', 'Direzione Flusso', 'Contour $V(x) = x^T P x$'}, ...
           'Interpreter','latex', 'Location', 'bestoutside');

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
    
    h_surf = surf(W_grid, Q_deg, V_surf, 'EdgeColor', 'none', 'FaceAlpha', 0.7);
    colormap jet;
    colorbar;
    
    % --- AGGIUNTA FONDAMENTALE: Inizializziamo max_v_traj ---
    max_v_traj = 0;
    
    % Proiezione traiettorie 3D
    for i = 1:num_simulazioni
        % Integrazione più fitta per fluidità visiva
        [~, x] = ode45(dxdt, linspace(0, 3, 300), x0_mult(:, i));
        
        V_traiettoria = sum((x * P) .* x, 2); 
        
        % --- Calcoliamo il picco di energia ---
        if max(V_traiettoria) > max_v_traj
            max_v_traj = max(V_traiettoria);
        end
        
        % Usiamo i colori estratti dalla palette per mantenere coerenza col 2D
        if i == 1
            h_traj3 = plot3(x(:,4), rad2deg(x(:,2)), V_traiettoria, '-', 'Color', colori(i,:), 'LineWidth', 2.5);
            h_start3 = plot3(x(1,4), rad2deg(x(1,2)), V_traiettoria(1), 'o', 'MarkerFaceColor', colori(i,:), 'MarkerEdgeColor', 'k', 'MarkerSize', 6);
        else
            plot3(x(:,4), rad2deg(x(:,2)), V_traiettoria, '-', 'Color', colori(i,:), 'LineWidth', 2.5);
            plot3(x(1,4), rad2deg(x(1,2)), V_traiettoria(1), 'o', 'MarkerFaceColor', colori(i,:), 'MarkerEdgeColor', 'k', 'MarkerSize', 6);
        end
    end
    
    title('Funzione di Lyapunov $V(x) = x^T P x$ a Ciclo Chiuso', 'Interpreter', 'latex')
    xlabel('Velocit\`a Verticale $w$ [ft/s]', 'Interpreter', 'latex')
    ylabel('Pitch Rate $q$ [deg/s]', 'Interpreter', 'latex')
    zlabel('Energia $V(x)$', 'Interpreter', 'latex')
    
    % Taglio dinamico dell'asse Z per non tagliare il paraboloide
    zmax_plot = max(max(V_surf(:)), max_v_traj);
    zlim([0, zmax_plot * 1.1]); 
    xlim([-w_lim, w_lim]);
    ylim([-q_lim, q_lim]);
    view(-45, 30);
    
    % Legenda 3D
    legend([h_surf, h_traj3, h_start3], ...
           {'Funzione di Lyapunov $V(x)$', 'Traiettoria di Stato', 'Condizione Iniziale'}, ...
           'Interpreter', 'latex', 'Location', 'bestoutside');
end