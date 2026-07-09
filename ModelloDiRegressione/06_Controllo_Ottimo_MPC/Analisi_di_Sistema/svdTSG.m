% =========================================================================
% SCOMPOSIZIONE AI VALORI SINGOLARI (SVD) TOTALE IN ANELLO APERTO 
% =========================================================================
% Tesi Triennale - Moto Longitudinale F-16
% Ing. Leggeri Leonardo
% =========================================================================

% =========================================================================
disp('--- SVD TOTALE della Matrice dei Guadagni Statici (Impianto Fisico) ---');

% 1. Calcolo della matrice G totale (6 uscite x 5 ingressi)
G_full = -C_long * (A_long \ B_long) + D_long; 
disp('Matrice G_full (6x5):');
disp(G_full);

% 2. Applicazione della Scomposizione ai Valori Singolari sull'intero sistema
% MATLAB usa la convenzione G = U * S * V'
% U_out = Direzioni di uscita (Sensori)
% Sigma = Guadagni principali (Valori Singolari)
% V_in  = Direzioni di ingresso associate (Attuatori)
[U_out, Sigma, V_in] = svd(G_full);

% 3. Estrazione dei Valori Singolari (elementi sulla diagonale di Sigma)
% Dato che la matrice è 6x5, avremo 5 valori singolari non nulli
valori_singolari = diag(Sigma);

disp('Valori Singolari del sistema (dal più forte al più debole):');
disp(valori_singolari);

% 4. Analisi di Condizionamento
sigma_max = valori_singolari(1);       % Il più grande (direzione più "facile")
sigma_min = valori_singolari(end);     % Il più piccolo (direzione più "difficile")
cond_num = sigma_max / sigma_min;      % Numero di condizionamento

fprintf('Valore Singolare Massimo (sigma_max) = %.4f\n', sigma_max);
fprintf('Valore Singolare Minimo (sigma_min)  = %.4f\n', sigma_min);
fprintf('Numero di Condizionamento (gamma)    = %.4f\n\n', cond_num);

% =========================================================================
% ANALISI FISICA DELLE DIREZIONI PRINCIPALI
% =========================================================================
disp('--- Analisi della Direzione di Massimo Guadagno ---');
disp('Combinazione di ingressi (V_in) che genera la risposta più forte:');
disp(V_in(:, 1));
disp('Combinazione di uscite (U_out) che reagisce di più a questi ingressi:');
disp(U_out(:, 1));

disp('--- Analisi della Direzione di Minimo Guadagno ---');
disp('Combinazione di ingressi (V_in) che genera la risposta più debole (spreco di energia):');
disp(V_in(:, end));