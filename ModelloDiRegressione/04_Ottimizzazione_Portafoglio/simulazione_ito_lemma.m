% =========================================================================
% Simulazione Moto Browniano ed espansione con Lemma di Ito
% =========================================================================
clear; clc; close all;

% --- Parametri Iniziali ---
S0 = 100;       % Prezzo iniziale
mu = 0.08;      % Drift (Rendimento atteso) dell'8%
sigma = 0.20;   % Volatilità del 20%
T = 1;          % Orizzonte temporale (1 anno)
N_steps = 252;  % Numero di passi (giorni lavorativi)
dt = T / N_steps;
N_sims = 1000;  % Numero di traiettorie simulate (Monte Carlo)

disp('====================================================');
disp('   SIMULAZIONE MOTO BROWNIANO & LEMMA DI ITO');
disp('====================================================');
fprintf('S0 = %.2f | mu = %.2f | sigma = %.2f\n\n', S0, mu, sigma);

%% 1. SIMULAZIONE DEL MOTO BROWNIANO GEOMETRICO (GBM) S(t)
% Generiamo gli incrementi standard dW ~ N(0, dt)
dW = sqrt(dt) * randn(N_steps, N_sims); 
S = zeros(N_steps + 1, N_sims);
S(1, :) = S0;

% Simulazione step-by-step con Eulero-Maruyama: dS = mu*S*dt + sigma*S*dW
for i = 1:N_steps
    S(i+1, :) = S(i,:) + mu * S(i,:) * dt + sigma * S(i,:) .* dW(i,:);
end
t = linspace(0, T, N_steps + 1)';

%% CASO 1: V1(S) = log(S^3)
% Usiamo il Lemma di Ito sapendo che log(S^3) = 3 * log(S):
% d(log S^3) = (3/S)*dS + 0.5*(-3/S^2)*(dS)^2
% dV1 = 3*(mu - 0.5*sigma^2)dt + 3*sigma*dW
disp('--- CASO 1: V_1(S) = log(S^3) ---');
disp('Equazione differenziale stocastica (Ito):');
disp('dV_1 = 3 * (mu - 0.5*sigma^2) dt + 3 * sigma dW');

drift_V1_teo = 3 * (mu - 0.5 * sigma^2);
vol_V1_teo = 3 * sigma;

% Calcolo empirico dalla simulazione
V1 = log(S.^3);
dV1_empirico = diff(V1); % differenze passo-passo
drift_V1_emp = mean(mean(dV1_empirico)) / dt;
vol_V1_emp = mean(std(dV1_empirico)) / sqrt(dt);

fprintf('Media Attesa Teorica (Drift annuo):   %.4f\n', drift_V1_teo);
fprintf('Media Attesa Empirica (Simulazione):  %.4f\n', drift_V1_emp);
fprintf('Volatilita Teorica annua:             %.4f\n', vol_V1_teo);
fprintf('Volatilita Empirica (Simulazione):    %.4f\n\n', vol_V1_emp);

%% CASO 2: V2(S) = 1 + S
% Usiamo il Lemma di Ito:
% d(1+S) = 1*dS + 0*(dS)^2
% dV2 = mu*S*dt + sigma*S*dW = dS
disp('--- CASO 2: V_2(S) = 1 + S ---');
disp('Equazione differenziale stocastica (Ito):');
disp('dV_2 = mu * S dt + sigma * S dW  (ovvero dV_2 = dS)');

% Valore atteso e deviazione standard teorica al tempo T
mean_V2_teo = 1 + S0 * exp(mu * T);
var_S_T = S0^2 * exp(2*mu*T) * (exp(sigma^2*T) - 1);
vol_V2_teo = sqrt(var_S_T);

% Calcolo empirico al tempo T
V2 = 1 + S;
mean_V2_emp = mean(V2(end, :));
vol_V2_emp = std(V2(end, :));

fprintf('Media Attesa Teorica a T=1:       %.4f\n', mean_V2_teo);
fprintf('Media Attesa Empirica a T=1:      %.4f\n', mean_V2_emp);
fprintf('Dev Standard Teorica a T=1:       %.4f\n', vol_V2_teo);
fprintf('Dev Standard Empirica a T=1:      %.4f\n\n', vol_V2_emp);

%% PLOT COMPARATIVI
disp('Generazione dei grafici in corso...');
figure('Name', 'Confronto Processi Stocastici', 'Color', 'w', 'Position', [100, 100, 1400, 450]);

% 1. Processo Base S(t)
subplot(1,3,1);
plot(t, S(:, 1:50), 'Color', [0.7 0.7 1], 'LineWidth', 0.5); hold on;
plot(t, mean(S, 2), 'k', 'LineWidth', 2);
title('\textbf{1. Moto Browniano } $S(t)$', 'Interpreter', 'latex', 'FontSize', 12);
xlabel('Tempo (Anni)'); ylabel('Prezzo S(t)');
grid on;

% 2. Processo V1 = log(S^3)
subplot(1,3,2);
plot(t, V1(:, 1:50), 'Color', [1 0.7 0.7], 'LineWidth', 0.5); hold on;
plot(t, mean(V1, 2), 'k', 'LineWidth', 2);
title('\textbf{2. Lemma di Ito: } $V_1 = \log(S^3)$', 'Interpreter', 'latex', 'FontSize', 12);
xlabel('Tempo (Anni)'); ylabel('\log(S^3)');
grid on;

% 3. Processo V2 = 1 + S
subplot(1,3,3);
plot(t, V2(:, 1:50), 'Color', [0.7 1 0.7], 'LineWidth', 0.5); hold on;
plot(t, mean(V2, 2), 'k', 'LineWidth', 2);
title('\textbf{3. Lemma di Ito: } $V_2 = 1 + S$', 'Interpreter', 'latex', 'FontSize', 12);
xlabel('Tempo (Anni)'); ylabel('1 + S(t)');
grid on;

disp('Simulazione completata. Grafici visualizzati a schermo.');
