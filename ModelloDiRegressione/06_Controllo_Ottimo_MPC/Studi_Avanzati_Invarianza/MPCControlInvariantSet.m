% =========================================================================
% Tesi Triennale - MPC Longitudinale F-16
% Simulazione con Conversione Continuo-Discreto (c2d) e Radianti
% Ing. Leggeri Leonardo
% =========================================================================

%% 1. Definizione del Sistema (TEMPO CONTINUO)
nx = 4; % Stati: [theta,q,U,W]'
nu = 3; % Ingressi: [T, dele, dlef]'
Ts = 0.05; % Tempo di campionamento in secondi


% ---  CONVERSIONE IN TEMPO DISCRETO ---
disp('Conversione del modello da Continuo a Discreto...');
sys_c = ss(A_long, B_ctrl, eye(nx), zeros(nx, nu));
sys_d = c2d(sys_c, Ts, 'zoh'); % Zero-Order Hold
A_long_ds = sys_d.A;
B_ctrl_ds = sys_d.B;

%% 2. Progetto LQR 
% Pesiamo l'errore massimo accettabile: u=20ft/s, w=15ft/s, q=10deg/s, th=10deg
Q = diag([1/20^2, 1/15^2, 1/deg2rad(10)^2, 1/deg2rad(10)^2]); 

% Pesiamo gli attuatori: Spinta=5000lb, Elevatore=25deg, Flap=25deg
% La spinta ha un numero grande, quindi il peso deve essere piccolissimo (1e-7)
R = diag([1/5000^2, 1/25^2, 1/25^2]);     

[K, P, ~] = dlqr(A_long_ds, B_ctrl_ds, Q, R);
A_cl = A_long_ds - B_ctrl_ds*K;
%% 3. Vincoli Fisici (Ampiezza e Rateo)
% Ingressi: [lb, deg, deg]
U_min = [-4000; -25; -12];  
U_max = [10000;  25;  12]; 
Rate_max = [10000; 60; 25]; 
dU_max = Rate_max * Ts; dU_min = -dU_max;

% Stati: theta(rad), q(rad/s), u(ft/s), w(ft/s)
X_max = [ deg2rad(45);  deg2rad(60);  100;  85]; 
X_min = [-deg2rad(45); -deg2rad(60); -100; -85];

Gx = [eye(nx); -eye(nx)]; gx = [X_max; -X_min];
Gu_x = [-K; K]; gu_x = [U_max; -U_min];
G = [Gx; Gu_x]; g = [gx; gu_x];

%% 4. Calcolo Control Invariant Set e Controllable Set con Polyhedron
disp('--- CALCOLO O_INF CON POLYHEDRON (Control Invariant Set) ---');
CIS_poly_prev = Polyhedron();
CIS_poly_curr = Polyhedron(G, g);

% Calcolo Invariant Set iterativo
while CIS_poly_prev.isEmptySet || CIS_poly_prev ~= CIS_poly_curr
    CIS_poly_prev = CIS_poly_curr;
    
    G_hat = [CIS_poly_prev.A * A_cl; G];
    g_hat = [CIS_poly_prev.b; g];
    
    CIS_poly_curr = Polyhedron(G_hat, g_hat);
end
G_inf = CIS_poly_curr.A;
g_inf = CIS_poly_curr.b;
disp('Calcolo O_inf completato.');

disp('--- CALCOLO N-STEP CONTROLLABLE SET CON POLYHEDRON ---');
N = 30; % Orizzonte predittivo MPC

H_ii_steps = G_inf;
h_ii_steps = g_inf;

Hu = [eye(nu); -eye(nu)]; 
hu = [U_max; -U_min];

for ii = 1:N
    % Calcolo in R^(n+m) per le coppie (x,u)
    A_k_1 = [H_ii_steps * A_long_ds, H_ii_steps * B_ctrl_ds;
             zeros(size(Hu, 1), nx), Hu]; 
    
    B_k_1 = [h_ii_steps; hu];
    
    temp = Polyhedron(A_k_1, B_k_1); 

    % Proiezione in R^(n) sullo stato x
    temp = projection(temp, 1:nx); 
    temp.minHRep(); 

    % Intersezione con i vincoli di stato Gx*x <= gx
    H_ii_steps = [temp.A; Gx]; 
    h_ii_steps = [temp.b; gx];
end
H_nsteps = H_ii_steps;
h_nsteps = h_ii_steps;
disp('Calcolo Controllable Set completato.');

%% 4b. Plot 3D dei Set Invarianti
figure('Name', 'Control Invariant Set 3D', 'Color', 'w', 'Position', [50, 50, 900, 700]);
hold on; grid on; view(3); 
title(sprintf('Poliedri $\\mathcal{X}_f$ e $\\mathcal{X}_{%d}$ in 3D (Fetta $\\theta = 0$)', N), 'Interpreter', 'latex', 'FontSize', 14);

% Assi aggiornati al tuo vettore di stato: [theta, q, U, W]
xlabel('u [ft/s]'); ylabel('w [ft/s]'); zlabel('q [rad/s]');

% Griglia coerente con i tuoi stati (U, W, q)
[X_U, X_W, X_q] = meshgrid(linspace(-50, 50, 40), ... % Range per u (Stato 3)
                           linspace(-50, 50, 40), ... % Range per w (Stato 4)
                           linspace(-deg2rad(40), deg2rad(40), 40)); % Range per q (Stato 2)

X_U_f = X_U(:); X_W_f = X_W(:); X_q_f = X_q(:); 

% Imposta la fetta in modo che combaci con la theta iniziale
theta_slice = 0; 
X_theta_f = theta_slice * ones(size(X_U_f)); % Fetta corrispondente alla partenza

% --- Plot Control Invariant Set (O_inf) ---
Validi_inf = true(size(X_U_f));
for j = 1:size(G_inf, 1)
    Valore = G_inf(j,1)*X_theta_f + G_inf(j,2)*X_q_f + G_inf(j,3)*X_U_f + G_inf(j,4)*X_W_f;
    Validi_inf = Validi_inf & (Valore <= g_inf(j));
end

PX_inf = X_U_f(Validi_inf); PY_inf = X_W_f(Validi_inf); PZ_inf = X_q_f(Validi_inf);

if length(PX_inf) > 4
    K_hull_inf = convhull(PX_inf, PY_inf, PZ_inf);
    trisurf(K_hull_inf, PX_inf, PY_inf, PZ_inf, 'FaceColor', 'c', 'FaceAlpha', 0.5, 'EdgeColor', 'b', 'EdgeAlpha', 0.3);
else
    disp('ATTENZIONE: Nessun punto valido trovato per il plot di O_inf.');
end

% --- Plot Controllable Set a N passi ---
Validi_n = true(size(X_U_f));
for j = 1:size(H_nsteps, 1)
    Valore = H_nsteps(j,1)*X_theta_f + H_nsteps(j,2)*X_q_f + H_nsteps(j,3)*X_U_f + H_nsteps(j,4)*X_W_f;
    Validi_n = Validi_n & (Valore <= h_nsteps(j));
end

PX_n = X_U_f(Validi_n); PY_n = X_W_f(Validi_n); PZ_n = X_q_f(Validi_n);

if length(PX_n) > 4
    K_hull_n = convhull(PX_n, PY_n, PZ_n);
    trisurf(K_hull_n, PX_n, PY_n, PZ_n, 'FaceColor', 'g', 'FaceAlpha', 0.15, 'EdgeColor', 'g', 'EdgeAlpha', 0.1);
else
    disp('ATTENZIONE: Nessun punto valido trovato per il plot del Controllable Set.');
end

legend('Control Invariant Set $\mathcal{O}_\infty$', sprintf('%d-step Controllable Set', N), 'Location', 'best', 'Interpreter', 'latex');

%% 5. Setup Problema MPC 
% N è già stato definito nella sezione precedente
n_vars = N*nu + N*nx; 

R_blk = kron(eye(N), R);
Q_blk = blkdiag(kron(eye(N-1), Q), P);
H = 2 * blkdiag(R_blk, Q_blk);         

f = zeros(n_vars, 1);                  
Aeq_base = zeros(N*nx, n_vars);
for k = 1:N
    Aeq_base((k-1)*nx + 1 : k*nx, (k-1)*nu + 1 : k*nu) = -B_ctrl_ds;
    Aeq_base((k-1)*nx + 1 : k*nx, N*nu + (k-1)*nx + 1 : N*nu + k*nx) = eye(nx);
    if k > 1
        Aeq_base((k-1)*nx + 1 : k*nx, N*nu + (k-2)*nx + 1 : N*nu + (k-1)*nx) = -A_long_ds;
    end
end
lb = -inf(n_vars, 1); ub = inf(n_vars, 1); 
for k = 1:N
    lb((k-1)*nu + 1 : k*nu) = U_min;
    ub((k-1)*nu + 1 : k*nu) = U_max;
end
A_ineq_stat = []; b_ineq_stat = [];
for j = 1:N-1
    A_t = zeros(size(Gx, 1), n_vars);
    A_t(:, N*nu + (j-1)*nx + 1 : N*nu + j*nx) = Gx;
    A_ineq_stat = [A_ineq_stat; A_t];
    b_ineq_stat = [b_ineq_stat; gx];
end
A_t = zeros(size(G_inf, 1), n_vars);
A_t(:, N*nu + (N-1)*nx + 1 : N*nu + N*nx) = G_inf;
A_ineq_stat = [A_ineq_stat; A_t];
b_ineq_stat = [b_ineq_stat; g_inf];

%% 6. Simulazione MPC Completa 
disp('--- Avvio Ottimizzazione e Simulazione MPC ---');

% Ordine: [theta; q; u; w]
x_iniziale = [deg2rad(25);  % theta: 5 gradi convertiti in rad
              deg2rad(20);           % q: velocità angolare nulla
              20;          % u: +10 ft/s di velocità forward
              20];          % w: velocità verticale nulla
t_sim = 100; 
storia_x = zeros(nx, t_sim+1); storia_x(:,1) = x_iniziale;
storia_u = zeros(nu, t_sim);
u_previous = [0;0;0]; 

options = optimoptions('quadprog', 'Display', 'off')
for t = 1:t_sim
    beq = zeros(N*nx, 1);
    beq(1:nx) = A_long_ds * storia_x(:,t); 
    
    A_rate = zeros(nu*2*N, n_vars); b_rate = zeros(nu*2*N, 1);
    for k = 1:N
        idx_u = (k-1)*nu+1:k*nu;
        A_rate((k-1)*2*nu+1:k*2*nu, idx_u) = [eye(nu); -eye(nu)];
        if k == 1
            b_rate((k-1)*2*nu+1:k*2*nu) = [dU_max + u_previous; dU_max - u_previous];
        else
            idx_u_prev = (k-2)*nu+1:(k-1)*nu;
            A_rate((k-1)*2*nu+1:k*2*nu, idx_u_prev) = [-eye(nu); eye(nu)];
            b_rate((k-1)*2*nu+1:k*2*nu) = [dU_max; dU_max];
        end
    end
    [z_opt, ~, exitflag] = quadprog(H, f, [A_ineq_stat; A_rate], [b_ineq_stat; b_rate], Aeq_base, beq, lb, ub, [], options);
    
    if exitflag < 0
        error('Infeasible! Il punto allo step %d è fuori da X_N. Riduci leggermente la severità di x_iniziale.', t);
    end
    
    if t == 1
        X_pred = zeros(nx, N+1);
        X_pred(:, 1) = x_iniziale;
        for k = 1:N
            X_pred(:, k+1) = z_opt(N*nu + (k-1)*nx + 1 : N*nu + k*nx);
        end
        % Plot corretto per gli assi: X=u(3), Y=w(4), Z=q(2)
        plot3(X_pred(3,:), X_pred(4,:), X_pred(2,:), '-rs', 'LineWidth', 2, 'MarkerFaceColor', 'r');
        plot3(x_iniziale(3), x_iniziale(4), x_iniziale(2), 'k*', 'MarkerSize', 10, 'LineWidth', 2);
        text(x_iniziale(3), x_iniziale(4), x_iniziale(2)+0.05, ' Partenza', 'FontWeight', 'bold');
    end
    
    u_applicata = z_opt(1:nu);
    storia_u(:, t) = u_applicata;
    
    storia_x(:, t+1) = A_long_ds * storia_x(:,t) + B_ctrl_ds * u_applicata;
    u_previous = u_applicata;
end
disp('Ottimizzazione Riuscita! Il modello è matematicamente solido.');


%% 7. Grafici 
figure('Name', 'Risultati MPC: Stati del Velivolo', 'Color', 'w', 'Position', [100 100 900 600]);
% storia_x(1) -> theta
subplot(2,2,1); plot(0:t_sim, storia_x(1,:), '-b', 'LineWidth', 1.5); title('\Delta Pitch Angle (\theta) [rad]'); grid on; 
% storia_x(2) -> q
subplot(2,2,2); plot(0:t_sim, storia_x(2,:), '-r', 'LineWidth', 1.5); title('Pitch Rate (q) [rad/s]'); grid on; 
% storia_x(3) -> u
subplot(2,2,3); plot(0:t_sim, storia_x(3,:), '-m', 'LineWidth', 1.5); title('\Delta Velocità Forward (u) [ft/s]'); grid on; 
% storia_x(4) -> w
subplot(2,2,4); plot(0:t_sim, storia_x(4,:), '-c', 'LineWidth', 1.5); title('\Delta Velocità Verticale (w) [ft/s]'); grid on;
figure('Name', 'Risultati MPC: Sforzo degli Attuatori', 'Color', 'w', 'Position', [150 150 700 800]);
subplot(3,1,1); stairs(0:t_sim-1, storia_u(1,:), '-g', 'LineWidth', 1.5); hold on;
yline(U_max(1), 'k--'); yline(U_min(1), 'k--'); title('\Delta Spinta [lbf]'); grid on; ylim([U_min(1)-2000, U_max(1)+2000]);
subplot(3,1,2); stairs(0:t_sim-1, storia_u(2,:), '-g', 'LineWidth', 1.5); hold on;
yline(U_max(2), 'k--'); yline(U_min(2), 'k--'); title('\Delta Elevatore [rad]'); grid on; ylim([U_min(2)-5, U_max(2)+5]);
subplot(3,1,3); stairs(0:t_sim-1, storia_u(3,:), '-g', 'LineWidth', 1.5); hold on;
yline(U_max(3), 'k--'); yline(U_min(3), 'k--'); title('\Delta Flap [rad]'); grid on; ylim([U_min(3)-5, U_max(3)+5]);