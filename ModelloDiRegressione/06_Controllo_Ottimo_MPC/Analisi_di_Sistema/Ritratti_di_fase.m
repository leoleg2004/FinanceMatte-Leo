% =========================================================================
% Ritratto di Fase F-16: MOTO DI CORTO PERIODO (Short Period)
% Variabili isolate: w (ft/s) vs q (deg/s)
% Ing. Leggeri Leonardo
% =========================================================================


set(0,'DefaultLineLineWidth',1.5);
set(0,'DefaultAxesFontSize',14);
set(0,'DefaulttextInterpreter','latex');

% Verifica matrici
if ~exist('A_long','var') || ~exist('B_ctrl','var')
    error('Le matrici A_long e B_ctrl non sono presenti.');
end

%% 1. Progetto LQR
% Ordine stati: [theta, q, u, w]
Q = diag([1/deg2rad(10)^2, 1/deg2rad(20)^2, 1/40^2, 1/30^2]); 
R = diag([1/5000^2, 1/25^2, 1/25^2]); 

[K, P] = lqr(A_long, B_ctrl, Q, R);
A_cl = A_long - B_ctrl * K; 

%% 2. Traiettorie (Solo dinamiche veloci)
dxdt = @(t,x) A_cl * x;

% Condizioni iniziali [theta=0, q_alta, u=0, w_alta]
x0 = [0,  0.5, 0,  30;   
      0, -0.6, 0, -40;   
      0,  0.8, 0, -20]';  

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
[W_grid, Q_deg] = meshgrid(-60:5:60, -60:5:60);
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

% Normalizziamo le frecce per vedere bene il flusso
L = sqrt(W_dot.^2 + Q_dot.^2) + 1e-6;
quiver(W_grid, Q_deg, W_dot./L, rad2deg(Q_dot)./L, 0.5, 'Color', [0.7 0.7 0.7]);
contour(W_grid, Q_deg, V_contour, 10, 'LineWidth', 1.5);

xlabel('Vertical Velocity $w$ [ft/s]') 
ylabel('Pitch Rate $q$ [deg/s]') 
title('Moto di Corto Periodo (Dinamica Veloce)')
xlim([-60, 60]); ylim([-60, 60]);