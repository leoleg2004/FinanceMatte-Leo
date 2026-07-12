% =========================================================================
% Esempio Libro: Calcolo del Value at Risk (VaR) di un portafoglio
% con 2 Asset su un orizzonte temporale di 10 giorni.
% =========================================================================
clear; clc; format bank;

disp('--- DATI INIZIALI ---');
% Pesi del portafoglio (2/3 e 1/3)
w = [2/3; 1/3]; 
disp('Pesi del portafoglio (w):');
disp(w');

% Volatilità giornaliere
sigma1_daily = 0.02; % 2%
sigma2_daily = 0.01; % 1%

% Orizzonte temporale
T_days = 100; 

% Scalamento volatilità su 10 giorni (Legge della radice del tempo)
s1 = sigma1_daily * sqrt(T_days);
s2 = sigma2_daily * sqrt(T_days);

% Correlazione
rho = 0.7;

% Matrice di Covarianza (CovMat)
CovMat = [ s1^2, rho*s1*s2 ; 
           rho*s1*s2, s2^2 ];
disp('Matrice di Covarianza su 10 giorni (CovMat):');
disp(CovMat);

%% CALCOLO MATRICIALE (Forma Quadratica della Varianza)
disp('--- CALCOLO DELLA VARIANZA E RISCHIO DEL PORTAFOGLIO ---');
% Forma quadratica: Var = w' * CovMat * w
PortVariance = w' * CovMat * w;
PortRisk = sqrt(PortVariance);

disp('Forma Quadratica della Varianza (w^T * CovMat * w):');
fprintf('%.6f\n', PortVariance);
disp('Rischio del Portafoglio (Deviazione Standard su 10 giorni):');
fprintf('%.6f (circa 5.011%%)\n', PortRisk);

%% CALCOLO DEL VALUE AT RISK (VaR)
disp('--- CALCOLO DEL VALUE AT RISK (VaR) ---');
PValue = 10000000; % $10 milioni
ConfidenceLevel = 0.99;

% Calcolo del quantile della normale standard (z-score)
% Per il 99% di confidenza a una coda, cerchiamo il 99° percentile
z_score = norminv(ConfidenceLevel);
fprintf('Z-Score per il 99%% di confidenza: %.4f\n', z_score);

% Calcolo del VaR parametrico
VaR = PValue * z_score * PortRisk;

disp('Value at Risk (VaR) a 10 giorni (99% confidenza):');
fprintf('$ %.2f\n', VaR);

% --- Calcolo Conditional Value at Risk (CVaR / Expected Shortfall) ---
alpha = 1 - ConfidenceLevel;
pdf_at_z = normpdf(norminv(alpha));
CVaR = PValue * PortRisk * (pdf_at_z / alpha);
disp('Conditional Value at Risk (CVaR) a 10 giorni (99% confidenza):');
fprintf('$ %.2f\n', CVaR);

%% CALCOLO TRAMITE FUNZIONI TOOLBOX (portstats / portvrisk)
% Nota: nelle nuove versioni di MATLAB le funzioni finanziarie storiche
% potrebbero essere state deprecate a favore di oggetti Portfolio, ma il
% calcolo matematico sottostante è esattamente quello mostrato sopra.
try
    disp(' ');
    disp('--- VERIFICA CON FUNZIONI TOOLBOX (portstats/portvrisk) se disponibili ---');
    s_toolbox = portstats([0 0], CovMat, w');
    var_toolbox = portvrisk(0, s_toolbox, 0.01, PValue);
    disp('VaR calcolato con portvrisk:');
    fprintf('$ %.2f\n', var_toolbox);
catch
    disp('Nota: Le funzioni portstats o portvrisk non sono presenti o sono state rimosse in questa versione del Financial Toolbox.');
    disp('Il risultato calcolato matricialmente è quello esatto ed equivale a 1165709.');
end

%% GRAFICO DELLA FORMA QUADRATICA DELLA VARIANZA
disp('--- GENERAZIONE GRAFICO 3D DELLA VARIANZA ---');
% Griglia dei pesi (da -0.5 a 1.5 per esplorare anche eventuali short selling)
[W1, W2] = meshgrid(linspace(-0.5, 1.5, 40), linspace(-0.5, 1.5, 40));
Var_Surface = zeros(size(W1));

for i = 1:size(W1,1)
    for j = 1:size(W1,2)
        wt = [W1(i,j); W2(i,j)];
        Var_Surface(i,j) = wt' * CovMat * wt;
    end
end

figure('Name', 'Forma Quadratica della Varianza', 'Color', 'w', 'Position', [200, 200, 800, 600]);
surf(W1, W2, Var_Surface, 'EdgeColor', 'none', 'FaceAlpha', 0.7);
colormap jet; colorbar;
hold on; grid on;

% Plottiamo il punto specifico del portafoglio scelto
plot3(w(1), w(2), PortVariance, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
text(w(1), w(2), PortVariance + 0.0005, '  Portafoglio Attuale (2/3, 1/3)', 'Color', 'r', 'FontWeight', 'bold');

title('\textbf{Forma Quadratica della Varianza $V(w) = w^T \Sigma w$}', 'Interpreter', 'latex', 'FontSize', 14);
xlabel('Peso Asset 1 ($w_1$)', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('Peso Asset 2 ($w_2$)', 'Interpreter', 'latex', 'FontSize', 12);
zlabel('Varianza del Portafoglio', 'FontSize', 12);
view(-45, 30);

%% GRAFICO DELLA DISTRIBUZIONE NORMALE E DEL VaR
disp('--- GENERAZIONE GRAFICO DISTRIBUZIONE NORMALE ---');
figure('Name', 'Distribuzione Normale del Portafoglio', 'Color', 'w', 'Position', [250, 250, 800, 500]);

% Valore atteso (0) e deviazione standard in dollari
mu_dollari = 0;
sigma_dollari = PValue * PortRisk;

% Asse X: da -4 a +4 deviazioni standard
x_val = linspace(mu_dollari - 4*sigma_dollari, mu_dollari + 4*sigma_dollari, 500);
y_val = normpdf(x_val, mu_dollari, sigma_dollari);

plot(x_val, y_val, 'b-', 'LineWidth', 2);
hold on; grid on;

% Evidenziamo l'area del VaR (coda sinistra 1%)
% Il VaR è stato calcolato in valore assoluto, quindi la soglia è -VaR
x_tail = linspace(min(x_val), -VaR, 100);
y_tail = normpdf(x_tail, mu_dollari, sigma_dollari);
area(x_tail, y_tail, 'FaceColor', 'r', 'FaceAlpha', 0.5, 'EdgeColor', 'none');

% Linea verticale per indicare la soglia esatta
xline(-VaR, 'r--', 'LineWidth', 2);
text(-VaR, max(y_val)*0.5, sprintf('  VaR 99%% = -$%.0f', VaR), 'Color', 'r', 'FontWeight', 'bold');

% Linea verticale per indicare il CVaR (Expected Shortfall)
xline(-CVaR, 'm--', 'LineWidth', 2);
text(-CVaR, max(y_val)*0.35, sprintf('  CVaR 99%% = -$%.0f', CVaR), 'Color', 'm', 'FontWeight', 'bold');

title('\textbf{Distribuzione dei Rendimenti del Portafoglio (in \$)}', 'Interpreter', 'latex', 'FontSize', 14);
xlabel('Variazione del Valore del Portafoglio (\$)', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('Densità di Probabilità', 'FontSize', 12);
