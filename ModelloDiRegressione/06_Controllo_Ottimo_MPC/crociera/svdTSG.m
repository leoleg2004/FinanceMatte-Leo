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
% SCOMPOSIZIONE AI VALORI SINGOLARI (SVD) IN ANELLO APERTO (Impianto G)
% =========================================================================

disp('--- SVD della Matrice dei Guadagni Statici G = G(0) ---');
% Estraiamo la matrice dei guadagni in continua (frequenza omega = 0)
G_full = dcgain(sys_long_min);

% Estraiamo il sottosistema quadrato 2x2 per il controllo longitudinale
% Assumendo: Ingressi = [Thrust, Elevator], Uscite = [Vt, q]
G = G_full([1, 3], [1, 2]); 
disp('Matrice G (2x2):');
disp(G);

% Applicazione della Scomposizione ai Valori Singolari
[Y, Sigma, U] = svd(G);

disp('Matrice delle direzioni di uscita (Y):');
disp(Y);
disp('Matrice dei Valori Singolari (Sigma):');
disp(Sigma);
disp('Matrice delle direzioni di ingresso associate (U):');
disp(U);

% Calcolo del numero di condizionamento (gamma)
sigma_bar = Sigma(1,1);       % Valore singolare massimo
sigma_under = Sigma(2,2);     % Valore singolare minimo
cond_num = sigma_bar / sigma_under;

fprintf('Valore Singolare Massimo (sigma_bar) = %.4f\n', sigma_bar);
fprintf('Valore Singolare Minimo (sigma_under) = %.4f\n', sigma_under);
fprintf('Numero di Condizionamento (gamma) = %.4f\n\n', cond_num);

% Verifica matematica: G = Y * Sigma * U' (dove U' è la trasposta coniugata)
% disp(Y * Sigma * U'); % Decommentare per verificare l'uguaglianza con G