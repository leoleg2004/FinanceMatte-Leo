function plot_mpt3_sets(CIS, x_ref, storia_x)
    % PLOT_MPT3_SETS Genera il plot 3D dei poliedri calcolati con MPT3
    % (Control Invariant Set) e vi sovrappone la 
    % traiettoria di simulazione nello spazio degli stati proiettato.
    
    disp('Generazione dei plot dei set Polyhedron MPT3...');

    CIS_shifted = CIS + x_ref; 

    % Essendo in 4D, estraiamo una "fetta" (slice) a theta = x_ref(1) invece 
    % di calcolare la proiezione. La proiezione di poliedri 4D complessi 
    % blocca MATLAB per via dell'elevato costo computazionale.
    disp('Estrazione di una slice 3D del poliedro 4D (a theta=x_ref) per consentire il plot...');
    CIS_3D = CIS_shifted.slice(1, x_ref(1));

    figure('Name', 'Traiettoria nel Set Invariante 3D', 'Color', 'w', 'Position', [100, 100, 1000, 700]);
    
    % Plot dei Poliedri con colori e trasparenze più eleganti
    hold on;
    CIS_3D.plot('Alpha', 0.4, 'Color', [0, 0.4470, 0.7410]); % Blu elegante

    % 1. Linea guida della traiettoria (continua e leggermente sfumata)
    plot3(storia_x(2,:), storia_x(3,:), storia_x(4,:), '-', 'LineWidth', 2.5, 'Color', [0.2 0.2 0.2 0.7]);
    
    % 2. Punti/Step dell'MPC colorati nel tempo
    scatter3(storia_x(2,:), storia_x(3,:), storia_x(4,:), 45, 1:size(storia_x,2), 'filled', 'MarkerEdgeColor', [0.3 0.3 0.3]);
    colormap(gca, parula); % Un bellissimo gradiente moderno
    cb = colorbar;
    cb.Label.String = 'Step di Simulazione MPC';
    cb.Label.FontSize = 12;

    % 3. Marker speciali per Partenza, Arrivo e Origine (Target)
    plot3(storia_x(2,1), storia_x(3,1), storia_x(4,1), 'rp', 'MarkerSize', 15, 'MarkerFaceColor', 'r'); % Stella rossa
    plot3(storia_x(2,end), storia_x(3,end), storia_x(4,end), 'gp', 'MarkerSize', 15, 'MarkerFaceColor', 'g'); % Stella verde
    plot3(0, 0, 0, 'kx', 'MarkerSize', 12, 'LineWidth', 3); % X nera all'origine

    % Testi esplicativi flottanti
    text(storia_x(2,1), storia_x(3,1), storia_x(4,1)+4, ' Start', 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'r');
    text(storia_x(2,end), storia_x(3,end), storia_x(4,end)-4, ' End', 'FontSize', 13, 'FontWeight', 'bold', 'Color', [0 0.5 0]);
    text(0, 0, -5, ' Target', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');

    title('\textbf{Traiettoria Ottima F-16 MPC \& MPT3 Sets}', 'Interpreter', 'latex', 'FontSize', 16);
    xlabel('Pitch Rate $q$ [rad/s]', 'Interpreter', 'latex', 'FontSize', 13);
    ylabel('Forward Velocity $U$ [ft/s]', 'Interpreter', 'latex', 'FontSize', 13);
    zlabel('Vertical Velocity $W$ [ft/s]', 'Interpreter', 'latex', 'FontSize', 13);
    
    % Abbellimenti grafici (Griglia, Illuminazione 3D e Angolazione)
    grid on; 
    view(135, 25); % Angolatura migliore
    camlight right; 
    lighting gouraud;
    
    legend({'Control Invariant Set ($\mathcal{O}_\infty$)', ...
            'Evoluzione Continua', 'Singoli Step MPC', 'Partenza', 'Arrivo', 'Target (Equilibrio)'}, ...
            'Interpreter', 'latex', 'FontSize', 11, 'Location', 'northeastoutside');
end
