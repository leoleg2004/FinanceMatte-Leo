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

%funzione per la creazione dei grafici dopo esecuzione script MPC.m
function plot_risultati(t_sim, storia_x, storia_u, U_min, U_max, x_ref, u_ref)
    if nargin < 6
        x_ref = zeros(4,1);
        u_ref = zeros(3,1);
    end

    % PLOT_RISULTATI Disegna i grafici dell'evoluzione di stati e attuatori
    figure('Name', 'Risultati MPC: Stati del Velivolo', 'Color', 'w', 'Position', [100 100 900 600]);
    subplot(2,2,1); plot(0:t_sim, storia_x(1,:), '-b', 'LineWidth', 1.5); hold on; yline(x_ref(1), 'r--', 'LineWidth', 1.2); title('Pitch Angle (\theta) [rad]'); grid on; 
    subplot(2,2,2); plot(0:t_sim, storia_x(2,:), '-r', 'LineWidth', 1.5); hold on; yline(x_ref(2), 'r--', 'LineWidth', 1.2); title('Pitch Rate (q) [rad/s]'); grid on; 
    subplot(2,2,3); plot(0:t_sim, storia_x(3,:), '-m', 'LineWidth', 1.5); hold on; yline(x_ref(3), 'r--', 'LineWidth', 1.2); title('Velocità Forward (u) [ft/s]'); grid on; 
    subplot(2,2,4); plot(0:t_sim, storia_x(4,:), '-c', 'LineWidth', 1.5); hold on; yline(x_ref(4), 'r--', 'LineWidth', 1.2); title('Velocità Verticale (w) [ft/s]'); grid on;
    legend({'Traiettoria', 'Target (x_{ref})'}, 'Location', 'best');

    figure('Name', 'Risultati MPC: Sforzo degli Attuatori', 'Color', 'w', 'Position', [150 150 700 800]);
    subplot(3,1,1); stairs(0:t_sim-1, storia_u(1,:), '-g', 'LineWidth', 1.5); hold on;
    yline(U_max(1), 'k--'); yline(U_min(1), 'k--'); yline(u_ref(1), 'r--', 'LineWidth', 1.2); title(' Spinta [lbf]'); grid on; ylim([U_min(1)-2000, U_max(1)+2000]);
    
    subplot(3,1,2); stairs(0:t_sim-1, rad2deg(storia_u(2,:)), '-g', 'LineWidth', 1.5); hold on;
    yline(rad2deg(U_max(2)), 'k--'); yline(rad2deg(U_min(2)), 'k--'); yline(rad2deg(u_ref(2)), 'r--', 'LineWidth', 1.2);
    title(' Elevatore [deg]'); grid on; ylim([rad2deg(U_min(2))-5, rad2deg(U_max(2))+5]);
    
    subplot(3,1,3); stairs(0:t_sim-1, rad2deg(storia_u(3,:)), '-g', 'LineWidth', 1.5); hold on;
    yline(rad2deg(U_max(3)), 'k--'); yline(rad2deg(U_min(3)), 'k--'); yline(rad2deg(u_ref(3)), 'r--', 'LineWidth', 1.2);
    title(' Flap [deg]'); grid on; ylim([rad2deg(U_min(3))-5, rad2deg(U_max(3))+5]);
end
