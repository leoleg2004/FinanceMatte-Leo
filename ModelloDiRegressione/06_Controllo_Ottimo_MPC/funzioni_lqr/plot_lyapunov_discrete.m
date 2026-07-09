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

function plot_lyapunov_discrete(P_ds, A_cl_ds, Ts)
    % =========================================================================
    % PLOT_LYAPUNOV_DISCRETE - Funzione di Lyapunov 3D per sistemi a tempo discreto
    % Grafico migliorato: Traiettoria interpolata fluida + Campionamenti discreti
    % =========================================================================
    
    if nargin < 3
        Ts = 0.05; 
    end
    
    rad2deg = 180 / pi;
    
    % --- 1. DEFINIZIONE LIMITI VISIVI ---
    w_lim = 50;  % ft/s
    q_lim = 50;  % deg/s
    
    [W_grid, Q_deg] = meshgrid(linspace(-w_lim, w_lim, 80), linspace(-q_lim, q_lim, 80));
    Q_rad = Q_deg / rad2deg; 
    
    % --- 2. CALCOLO SUPERFICIE DI LYAPUNOV ---
    V_surf = zeros(size(W_grid));
    for i = 1:size(W_grid, 1)
        for j = 1:size(W_grid, 2)
            stato_surf = [0; Q_rad(i,j); 0; W_grid(i,j)];
            V_surf(i,j) = stato_surf' * P_ds * stato_surf;
        end
    end
    
    % --- 3. DINAMICA DISCRETA E CONDIZIONI INIZIALI ---
    N_steps = round(10 / Ts); 
    
    x0 = [0,  0.5, 0,  30;   
          0, -0.6, 0, -40;   
          0,  0.8, 0, -20]';

    %% --- FIGURA 3D ---
    figure('Name', sprintf('Lyapunov 3D Discreto (Ts = %g s)', Ts), 'Color', 'w', 'Position', [150 150 850 650]);
    hold on; grid on;
    
    % 1. Disegno Superficie
    h_surf = surf(W_grid, Q_deg, V_surf, 'EdgeColor', 'none', 'FaceAlpha', 0.65);
    colormap jet;
    cb = colorbar;
    ylabel(cb, 'Energia $V(x_k)$', 'Interpreter', 'latex', 'FontSize', 12);
    
    colori = {'r', 'g', 'b'};
    max_v_traj = 0; 
    
    % 2. Simulazione e Disegno Traiettorie
    for i = 1:size(x0, 2)
        x_traj = zeros(4, N_steps);
        x_traj(:, 1) = x0(:, i);
        
        for k = 1:N_steps-1
            x_traj(:, k+1) = A_cl_ds * x_traj(:, k);
        end
        
        V_traj = zeros(N_steps, 1);
        for k = 1:N_steps
            V_traj(k) = x_traj(:, k)' * P_ds * x_traj(:, k);
        end
        
        if max(V_traj) > max_v_traj
            max_v_traj = max(V_traj);
        end
        
        % --- MAGIA VISIVA: INTERPOLAZIONE FLUIDA DELLA TRAIETTORIA ---
        % Usiamo 'pchip' (interpolazione cubica che non crea finti rimbalzi) 
        % per generare 10 volte più punti e rendere la curva morbidissima
        t_discrete = 1:N_steps;
        t_fine = linspace(1, N_steps, N_steps * 10);
        
        W_smooth = pchip(t_discrete, x_traj(4,:), t_fine);
        Q_smooth = pchip(t_discrete, x_traj(2,:) * rad2deg, t_fine);
        V_smooth = pchip(t_discrete, V_traj, t_fine);
        
        % 1. Disegniamo prima la SCIA FLUIDA (linea continua)
        if i == 1
            h_line = plot3(W_smooth, Q_smooth, V_smooth, '-', 'Color', colori{i}, 'LineWidth', 2);
        else
            plot3(W_smooth, Q_smooth, V_smooth, '-', 'Color', colori{i}, 'LineWidth', 2);
        end
        
        % 2. Disegniamo sopra i PUNTI DISCRETI (solo pallini, senza linee)
        plot3(x_traj(4,:), x_traj(2,:) * rad2deg, V_traj, 'o', ...
              'MarkerEdgeColor', colori{i}, 'MarkerFaceColor', 'w', 'MarkerSize', 4);
              
        % Partenza (Start)
        if i == 1
            h_start = plot3(x_traj(4,1), x_traj(2,1) * rad2deg, V_traj(1), 'o', ...
                            'MarkerFaceColor', colori{i}, 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
        else
            plot3(x_traj(4,1), x_traj(2,1) * rad2deg, V_traj(1), 'o', ...
                  'MarkerFaceColor', colori{i}, 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
        end
        
        % Arrivo (End)
        plot3(x_traj(4,end), x_traj(2,end) * rad2deg, V_traj(end), 's', ...
              'MarkerFaceColor', colori{i}, 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
    end
    
    % --- ORIGINE ---
    h_end = plot3(0, 0, 0, 'p', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k', 'MarkerSize', 16);
    
    % --- FORMATTAZIONE E LEGENDA ---
    title(sprintf('\\textbf{Funzione di Lyapunov $V(x_k)$ a Tempo Discreto ($T_s = %g$ s)}', Ts), 'Interpreter', 'latex', 'FontSize', 16);
    xlabel('Velocit\`a Verticale $w$ [ft/s]', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel('Pitch Rate $q$ [deg/s]', 'Interpreter', 'latex', 'FontSize', 12);
    zlabel('Energia $V(x_k) = x_k^T P_d x_k$', 'Interpreter', 'latex', 'FontSize', 12);
    
    legend([h_surf, h_line, h_start, h_end], ...
           {'Superficie $V(x_k)$', 'Evoluzione di Stato (Interpolata)', 'Partenza ($k=0$)', 'Origine ($k \to \infty$)'}, ...
           'Interpreter', 'latex', 'FontSize', 12, 'Location', 'northeast');
    
    zlim([0, max_v_traj * 1.2]); 
    xlim([-w_lim, w_lim]);
    ylim([-q_lim, q_lim]);
    view(-35, 30);
end