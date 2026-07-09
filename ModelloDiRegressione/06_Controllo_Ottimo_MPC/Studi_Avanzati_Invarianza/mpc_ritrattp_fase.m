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
% Script Separato: Ritratto di Fase e Funzione di Lyapunov per MPC
% Tesi Triennale - F-16
% (Eseguire DOPO lo script principale dell'MPC)
% =========================================================================

disp('--- Simulazione Condizioni Multiple per Ritratto di Fase MPC ---');

%% 1. Definizione della Griglia e Funzione di Costo (Lyapunov)
w_range = linspace(-25, 25, 50);   % ft/s
q_range_rad = linspace(-1.5, 1.5, 50); % rad/s
[W_grid, Q_rad] = meshgrid(w_range, q_range_rad);
Q_deg = Q_rad * rad2deg; 

% Calcolo della superficie di Lyapunov usando la P dell'LQR (costo terminale)
V_surf = zeros(size(W_grid));
for i = 1:size(W_grid, 1)
    for j = 1:size(W_grid, 2)
        % Fissiamo theta=0 e U=0
        stato_surf = [0; Q_rad(i,j); 0; W_grid(i,j)];
        V_surf(i,j) = stato_surf' * P * stato_surf;
    end
end

%% 2. Condizioni Iniziali Multiple
% Limitiamo i picchi di q a 0.9 rad/s per non violare i vincoli (q_max = 60 deg/s = 1.04 rad/s)
x0_mult = [
    0,   0,    0,   0,    0,   0,    0,   0;      % theta
    0.9, -0.9, 0.5, -0.5, 0.8, -0.8, 0.3, -0.3;   % q (rad/s)
    0,   0,    0,   0,    0,   0,    0,   0;      % U
    20,  -20,  15,  -15, -10,  10,   22,  -22     % W (ft/s)
];

t_sim_phase = 40; % Passi di simulazione per mostrare la convergenza
traiettorie_mult = cell(1, size(x0_mult, 2));

%% 3. Simulazione del ciclo MPC per ogni traiettoria
options = optimoptions('quadprog', 'Display', 'off');

for i = 1:size(x0_mult, 2)
    x_curr = x0_mult(:, i);
    X_traj = zeros(nx, t_sim_phase+1);
    X_traj(:,1) = x_curr;
    u_prev = [0;0;0];
    
    for t = 1:t_sim_phase
        beq = zeros(N*nx, 1);
        beq(1:nx) = A_long_ds * x_curr; 
        
        A_rate = zeros(nu*2*N, n_vars); 
        b_rate = zeros(nu*2*N, 1);
        for k = 1:N
            idx_u = (k-1)*nu+1:k*nu;
            A_rate((k-1)*2*nu+1:k*2*nu, idx_u) = [eye(nu); -eye(nu)];
            if k == 1
                b_rate((k-1)*2*nu+1:k*2*nu) = [dU_max + u_prev; dU_max - u_prev];
            else
                idx_u_prev = (k-2)*nu+1:(k-1)*nu;
                A_rate((k-1)*2*nu+1:k*2*nu, idx_u_prev) = [-eye(nu); eye(nu)];
                b_rate((k-1)*2*nu+1:k*2*nu) = [dU_max; dU_max];
            end
        end
        
        [z_opt, ~, exitflag] = quadprog(H, f, [A_ineq_stat; A_rate], [b_ineq_stat; b_rate], Aeq_base, beq, lb, ub, [], options);
        
        if exitflag < 0
            warning('Condizione %d infeasible allo step %d.', i, t);
            X_traj = X_traj(:, 1:t); % Tronca se viola vincoli severi e si ferma
            break;
        end
        
        u_app = z_opt(1:nu);
        x_curr = A_long_ds * x_curr + B_ctrl_ds * u_app;
        X_traj(:, t+1) = x_curr;
        u_prev = u_app;
    end
    traiettorie_mult{i} = X_traj;
end
disp('Calcolo delle traiettorie MPC completato.');

%% 4. FIGURA: RITRATTO DI FASE 2D CON CURVE DI LIVELLO
figure('Name', 'Ritratto di Fase 2D MPC', 'Color', 'w', 'Position', [250, 250, 700, 500]);
hold on; grid on;
contour(W_grid, Q_deg, V_surf, 40, 'LineWidth', 1);
colormap jet; 
colorbar;

for i = 1:length(traiettorie_mult)
    x_traj = traiettorie_mult{i};
    % Plotto le traiettorie discrete (segmenti con marcatori puntiformi)
    plot(x_traj(4,:), x_traj(2,:) * rad2deg, 'k.-', 'LineWidth', 1.5, 'MarkerSize', 8);
    % Segno il punto di partenza
    plot(x_traj(4,1), x_traj(2,1) * rad2deg, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
end

title('Ritratto di Fase MPC e Costo Terminale $V(x)$', 'Interpreter', 'latex');
xlabel('W (Velocità Verticale) [ft/s]', 'Interpreter', 'latex');
ylabel('q (Pitch Rate) [deg/s]', 'Interpreter', 'latex');
axis tight;

%% 5. FIGURA: FUNZIONE DI LYAPUNOV 3D CON TRAIETTORIE
figure('Name', 'Funzione di Lyapunov 3D - MPC', 'Color', 'w', 'Position', [300, 300, 800, 600]);
hold on; grid on;
surf(W_grid, Q_deg, V_surf, 'EdgeColor', 'none', 'FaceAlpha', 0.6);
colormap jet;

for i = 1:length(traiettorie_mult)
    x_traj = traiettorie_mult{i};
    
    % Calcola V(x) passo-passo per tracciare la discesa 3D
    V_traiettoria = zeros(1, size(x_traj, 2));
    for k = 1:size(x_traj, 2)
        V_traiettoria(k) = x_traj(:,k)' * P * x_traj(:,k);
    end
    
    plot3(x_traj(4,:), x_traj(2,:) * rad2deg, V_traiettoria, 'k.-', 'LineWidth', 2, 'MarkerSize', 8);
    plot3(x_traj(4,1), x_traj(2,1) * rad2deg, V_traiettoria(1), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
end

title('Traiettorie MPC sulla Superficie del Costo $V(x) = x^T P x$', 'Interpreter', 'latex');
xlabel('$W$ [ft/s]', 'Interpreter', 'latex');
ylabel('$q$ [deg/s]', 'Interpreter', 'latex');
zlabel('$V(x)$', 'Interpreter', 'latex');
view(-35, 35);