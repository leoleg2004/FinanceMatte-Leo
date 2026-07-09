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
% CALCOLO MATEMATICO DELLA MATRICE RGA (SISTEMA LONGITUDINALE)
% =========================================================================

disp('--- 1. Calcolo della Matrice dei Guadagni Statici (G) ---');
% Metodo analitico: G = -C * inv(A) * B + D
% Nota: MATLAB preferisce (A\B) rispetto a inv(A)*B per stabilità numerica
G_long = -C_long * (A_long \ B_long) + D_long;

% In alternativa, se hai già creato l'oggetto sys_long = ss(A,B,C,D), 
% puoi usare semplicemente la funzione integrata:
% G_long = dcgain(sys_long);

disp('G_long (6 uscite x 5 ingressi):');
disp(G_long);

disp('--- 2. Calcolo della Matrice RGA ---');
% Formula: RGA = G .* trasposta(pseudo-inversa(G))
% pinv(G_long) calcola la pseudo-inversa di Moore-Penrose
% Il .' esegue la trasposta (senza coniugare i numeri complessi, anche se qui sono reali)
% Il .* esegue il prodotto di Schur (Hadamard), ovvero elemento per elemento

RGA_long = G_long .* (pinv(G_long).');

disp('Matrice dei Guadagni Relativi (RGA_long):');
disp(RGA_long);

% =========================================================================
% VISUALIZZAZIONE DELL'ACCOPPIAMENTO (HEATMAP DELLA RGA)
% =========================================================================

% Definiamo le etichette per gli assi in modo chiaro
in_names = {'Thrust', 'Elevator', 'LEF', 'Gust X', 'Gust Z'};
out_names = {'Vt', 'alpha', 'gamma', 'q', 'ax', 'az'};

% Creiamo la figura
figure('Name', 'Analisi Accoppiamento RGA', 'Position', [100, 100, 700, 500]);

% Creiamo la Heatmap
h = heatmap(in_names, out_names, RGA_long);

% Formattazione del grafico
h.Title = 'Accoppiamento Ingressi-Uscite (RGA Longitudinale)';
h.XLabel = 'Ingressi (Attuatori e Disturbi)';
h.YLabel = 'Uscite (Variabili Controllate)';

% Usiamo una mappa di colori divergente:
% - I valori vicini a 1 saranno scuri/intensi (Accoppiamento forte)
% - I valori vicini a 0 saranno chiari (Nessun accoppiamento)
% - I valori negativi avranno un colore di allarme
colormap(parula); 

% Opzionale: Mostra i numeri con 2 decimali per non sporcare la grafica
h.CellLabelFormat = '%.2f';