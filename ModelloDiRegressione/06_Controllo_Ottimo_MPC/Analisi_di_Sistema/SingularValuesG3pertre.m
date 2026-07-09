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
% ANALISI DEI VALORI SINGOLARI E CONDIZIONAMENTO (Norma 1 Indotta)
% =========================================================================
disp('--- Analisi Valori Singolari: G(s) ---');

% MATLAB estrae analiticamente l'amplificazione massima e minima
% per tutti i vettori di ingresso tali che ||u|| = 1.
% sv conterrà 3 righe (essendo un sistema 3x3)
[sv, w] = sigma(G_nuova); 

% Conversione in Decibel (dB)
sv_dB = 20*log10(sv);
% 1. Calcolo del guadagno statico valutando la tua matrice per s = 0
G_statico = dcgain(G_nuova);

% 2. Calcolo della RGA utilizzando il prodotto di Schur e l'inversa trasposta
RGA = G_statico .* inv(G_statico).';

% 3. Stampa il risultato
disp('--- Relative Gain Array (RGA) ---');
disp(RGA);
% 1. GRAFICO DEL VALORE MASSIMO E MINIMO
figure('Name', 'Valori Singolari (Max e Min)', 'Color', 'w', 'Position', [100, 100, 700, 500]);

% Tracciamo la direzione a massimo guadagno (Norma 1 in ingresso -> Max Uscita)
semilogx(w, sv_dB(1,:), 'b', 'LineWidth', 2.5); 
hold on;
% Tracciamo la direzione a minimo guadagno (Norma 1 in ingresso -> Min Uscita)
semilogx(w, sv_dB(3,:), 'k', 'LineWidth', 2.5); 
hold off;

grid on;
title('Valori Singolari dell''Impianto $G(s)$ (Ingressi ||u||=1)', 'Interpreter', 'latex', 'FontSize', 14);
ylabel('Amplificazione Indotta (dB)');
xlabel('Frequenza (rad/s)');
legend('\sigma_{Max} (Direzione più reattiva)', '\sigma_{Min} (Direzione più faticosa)', 'Location', 'best');

% 2. NUMERO DI CONDIZIONAMENTO
% Il numero di condizionamento è il rapporto tra Sigma Max e Sigma Min.
% In dB è una semplice sottrazione. Rappresenta la severità del cross-talk.
gamma_dB = sv_dB(1,:) - sv_dB(3,:); 

figure('Name', 'Numero di Condizionamento', 'Color', 'w', 'Position', [150, 150, 700, 500]);
semilogx(w, gamma_dB, 'LineWidth', 2.5, 'Color', 'r');
grid on;
title('Numero di Condizionamento $\gamma(j\omega)$', 'Interpreter', 'latex', 'FontSize', 14);
ylabel('Condizionamento (dB)');
xlabel('Frequenza (rad/s)');

disp('Grafici generati! Analizza il numero di condizionamento.');




