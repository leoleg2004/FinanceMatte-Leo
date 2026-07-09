function plot_risultati_portfolio(t_sim, storia_x, storia_u, U_min, U_max, x_ref, u_ref)
    if nargin < 6
        x_ref = [1/3; 1/3; 1/3];
        u_ref = zeros(3,1);
    end

    % PLOT_RISULTATI Disegna i grafici dell'evoluzione di stati e attuatori del Portafoglio
    figure('Name', 'Risultati MPC: Pesi del Portafoglio (Stati)', 'Color', 'w', 'Position', [100 100 900 400]);
    subplot(1,3,1); plot(0:t_sim, storia_x(1,:), '-b', 'LineWidth', 1.5); hold on; yline(x_ref(1), 'r--', 'LineWidth', 1.2); 
    title('Asset 1: VWCE'); ylabel('Peso (0-1)'); xlabel('Tempo (Mesi)'); grid on; 
    
    subplot(1,3,2); plot(0:t_sim, storia_x(2,:), '-r', 'LineWidth', 1.5); hold on; yline(x_ref(2), 'r--', 'LineWidth', 1.2); 
    title('Asset 2: SXRV'); xlabel('Tempo (Mesi)'); grid on; 
    
    subplot(1,3,3); plot(0:t_sim, storia_x(3,:), '-m', 'LineWidth', 1.5); hold on; yline(x_ref(3), 'r--', 'LineWidth', 1.2); 
    title('Asset 3: ZPRR'); xlabel('Tempo (Mesi)'); grid on;
    legend({'Evoluzione MPC', 'Target (x_{ref})'}, 'Location', 'best');

    figure('Name', 'Risultati MPC: Operazioni di Trading (Ingressi)', 'Color', 'w', 'Position', [150 150 900 400]);
    subplot(1,3,1); stairs(0:t_sim-1, storia_u(1,:), '-g', 'LineWidth', 1.5); hold on;
    yline(U_max(1), 'k--'); yline(U_min(1), 'k--'); yline(u_ref(1), 'r--', 'LineWidth', 1.2); 
    title('Trade VWCE'); ylabel('\Delta Peso'); xlabel('Tempo (Mesi)'); grid on; ylim([U_min(1)-0.05, U_max(1)+0.05]);
    
    subplot(1,3,2); stairs(0:t_sim-1, storia_u(2,:), '-g', 'LineWidth', 1.5); hold on;
    yline(U_max(2), 'k--'); yline(U_min(2), 'k--'); yline(u_ref(2), 'r--', 'LineWidth', 1.2);
    title('Trade SXRV'); xlabel('Tempo (Mesi)'); grid on; ylim([U_min(2)-0.05, U_max(2)+0.05]);
    
    subplot(1,3,3); stairs(0:t_sim-1, storia_u(3,:), '-g', 'LineWidth', 1.5); hold on;
    yline(U_max(3), 'k--'); yline(U_min(3), 'k--'); yline(u_ref(3), 'r--', 'LineWidth', 1.2);
    title('Trade ZPRR'); xlabel('Tempo (Mesi)'); grid on; ylim([U_min(3)-0.05, U_max(3)+0.05]);
end
