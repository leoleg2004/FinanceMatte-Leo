function plot_mpc_cost_3d_portfolio(mpc_prob, P_ds, storia_x, storia_costo, x_ref)
    % =========================================================================
    % PLOT_MPC_COST_3D_PORTFOLIO - Visualizza il Funzionale di Costo Ottimo J*(x) 
    % Genera una griglia per x1 e x2, con x3 = 1 - x1 - x2 (Self-Financing)
    % e traccia la superficie di costo di Lyapunov
    % =========================================================================

    % Griglia per i pesi di VWCE e SXRV (0 to 1)
    x_grid = linspace(0, 1, 30);
    y_grid = linspace(0, 1, 30);
    [X1, X2] = meshgrid(x_grid, y_grid);
    
    V_surf = zeros(size(X1));
    for i = 1:size(X1, 1)
        for j = 1:size(X1, 2)
            x1 = X1(i,j);
            x2 = X2(i,j);
            x3 = 1 - x1 - x2; % Vincolo di fully-invested
            
            % Se sfora, costo altissimo (infeasible)
            if x3 < 0 || x3 > 1
                V_surf(i,j) = NaN; 
            else
                stato_surf = [x1; x2; x3] - x_ref;
                V_surf(i,j) = stato_surf' * P_ds * stato_surf;
            end
        end
    end

    %% --- FIGURA 3D ---
    figure('Name', 'Costo MPC 3D di Lyapunov', 'Color', 'w', 'Position', [150 150 850 650]);
    hold on; grid on;
    
    h_surf = surf(X1, X2, V_surf, 'EdgeColor', 'none', 'FaceAlpha', 0.65);
    colormap jet;
    cb = colorbar;
    ylabel(cb, 'Costo di Lyapunov $V(x) = x^T P x$', 'Interpreter', 'latex', 'FontSize', 12);
    
    max_v_traj = max(storia_costo);
    if isempty(max_v_traj) || isnan(max_v_traj) || max_v_traj == 0
        max_v_traj = max(V_surf(:));
    end

    % Traiettoria Simulata
    N_steps = length(storia_costo);
    
    % Per la z della traiettoria prendiamo storia_costo o il costo LQR effettivo
    V_traj = zeros(1, N_steps);
    for k = 1:N_steps
        dx = storia_x(:,k) - x_ref;
        V_traj(k) = dx' * P_ds * dx;
    end
    
    h_line = plot3(storia_x(1,1:N_steps), storia_x(2,1:N_steps), V_traj, '-r', 'LineWidth', 2);

    % Start (k=0)
    h_start = plot3(storia_x(1,1), storia_x(2,1), V_traj(1), 'o', ...
                    'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'MarkerSize', 10);
    
    % End
    h_end = plot3(storia_x(1,N_steps), storia_x(2,N_steps), V_traj(N_steps), 's', ...
          'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'MarkerSize', 10);

    title('\textbf{Funzione di Lyapunov $V(x)$ del Portafoglio}', 'Interpreter', 'latex', 'FontSize', 16);
    xlabel('Peso VWCE ($x_1$)', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel('Peso SXRV ($x_2$)', 'Interpreter', 'latex', 'FontSize', 12);
    zlabel('Costo (Loss)', 'Interpreter', 'latex', 'FontSize', 12);
    
    legend([h_surf, h_line, h_start, h_end], ...
           {'Superficie $V(x)$', 'Evoluzione Portafoglio', 'Partenza ($k=0$)', 'Arrivo'}, ...
           'Interpreter', 'latex', 'FontSize', 12, 'Location', 'northeast');
    
    zlim([0, max([V_surf(:); V_traj(:)]) * 1.1]); 
    xlim([0, 1]);
    ylim([0, 1]);
    view(-35, 30);
end
