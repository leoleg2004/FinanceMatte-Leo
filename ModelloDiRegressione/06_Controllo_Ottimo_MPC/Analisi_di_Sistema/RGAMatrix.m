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
% CALCOLO E VISUALIZZAZIONE RGA (SISTEMA LONGITUDINALE ORIGINALE)
% =========================================================================
disp('--- 1. Calcolo della Matrice dei Guadagni Statici (G) ---');
G_long = -C_long * (A_long \ B_long) + D_long;

disp('--- 2. Calcolo della Matrice RGA ---');
RGA_long = G_long .* (pinv(G_long).');

% Nomi FISSI per le uscite (Asse Y) - Saranno identici nell'altro script!
nomi_uscite = {'Vt_out', 'alpha_out', 'q_out', 'xbdd', 'zbdd', 'nz'};
% Nomi degli ingressi FISICI (Asse X) - Sono 5
nomi_ingressi_fisici = {'Thrust', 'Elevator', 'LEF', 'Gust X', 'Gust Z'};

% Creiamo la figura a sinistra
figure('Name', 'Analisi RGA Originale', 'Position', [100, 200, 700, 500]);
h1 = heatmap(nomi_ingressi_fisici, nomi_uscite, RGA_long);

% Formattazione Heatmap
h1.Title = 'RGA Sistema Originale (Accoppiato)';
h1.XLabel = 'Ingressi Fisici (Attuatori/Disturbi)';
h1.YLabel = 'Uscite Fisiche (Sensori)';
colormap(h1, parula); 
h1.CellLabelFormat = '%.2f';

% IL TRUCCO: Inchiodiamo la scala dei colori da -1 a 1
h1.ColorLimits = [-1, 1];