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
% MINIMIZZAZIONE DEL SISTEMA (Raggiungibilità e Osservabilità)
% =========================================================================
disp('--- Generazione Modello State-Space (LTI) Originale ---');
sys_long = ss(A_long, B_long, C_long, D_long);
sys_long.StateName = {'theta', 'q', 'U', 'W'};
sys_long.InputName = {'Thrust', 'Elevator', 'LE_flap', 'Dist_x', 'Dist_z'};
sys_long.OutputName = {'Vt_out', 'alpha_out', 'q_out', 'xbdd', 'zbdd', 'nz'};
disp('--- Estrazione della Realizzazione Minima (minreal) ---');
% Il comando minreal cancella le dinamiche non osservabili/raggiungibili
% ed elimina le coppie polo-zero coincidenti.
sys_long_min = minreal(sys_long);
disp('--- Calcolo Matrice Funzioni di Trasferimento MINIMA H(s) ---');
G_long_min = tf(sys_long_min);

% =========================================================================
% CALCOLO DI POLI E ZERI
% =========================================================================
disp('--- Poli del Sistema Minimo (Autovalori effettivi) ---');
% I poli del sistema MIMO (coincidono con il denominatore comune)
poli_minimi = pole(sys_long_min);
disp(poli_minimi);
disp('--- Zeri di Trasmissione del Sistema MIMO ---');
% Gli zeri di un sistema MIMO non sono banali da calcolare come nei SISO.
% Il comando tzero calcola gli zeri di trasmissione dell'intera matrice.
zeri_mimo = tzero(sys_long_min);
disp(zeri_mimo);
%%
% disaccoppiamento in avanti 
% Scegliamo tutte e 5 le leve, ma scartiamo un'uscita (es. la sesta, 'nz')
G_quadrata = G_long_min(1:5, :); % Prende le prime 5 uscite e tutti e 5 gli ingressi

% Ora è una 5x5! Possiamo fare l'inversa classica
K = dcgain(G_quadrata);
W = inv(K); 

% Applichiamo il disaccoppiatore
G_disaccoppiataInAvanti = G_quadrata * W;



%%
% disaccopiamento con pseudoinversa
% 1. Calcola la matrice dei guadagni statici di tutto il sistema 6x5
K_totale = dcgain(G_long_min);

% 2. Crea il disaccoppiatore in avanti usando la pseudoinversa (pinv)
W = pinv(K_totale);

% 3. Applica il disaccoppiatore all'impianto originale
G_disaccoppiataPseudoInversa = G_long_min * W;

% Mostriamo il risultato per verifica
disp('--- Matrice di Disaccoppiamento W (Pseudoinversa) ---');
disp(W);
% =========================================================================
% VISUALIZZAZIONE GRAFICA
% =========================================================================
% Mappa Poli-Zeri per verificare la stabilità (tutte le X a sinistra dell'asse y)
figure('Name', 'Mappa Poli-Zeri (Minimal Realization)');
pzmap(sys_long_min);
grid on;
title('Mappa Poli-Zeri del Sistema Longitudinale Minimo');

% =========================================================================
% VERIFICA FINALE: RGA SUL SISTEMA DISACCOPPIATO CON ETICHETTE
% =========================================================================
disp('--- Verifica RGA su G_disaccoppiataPseudoInversa ---');

% 1. Calcoliamo il guadagno statico del sistema DOPO il disaccoppiamento
K_dec = dcgain(G_disaccoppiataPseudoInversa);

% 2. Calcoliamo la matrice RGA
% (Usiamo la trasposta della pseudoinversa per gestire la matrice creata prima)
RGA_dec = K_dec .* (pinv(K_dec).');

% 3. Creiamo le etichette per rendere la matrice leggibile
% Le uscite sono quelle fisiche del tuo modello
nomi_uscite = {'Vt_out', 'alpha_out', 'q_out', 'xbdd', 'zbdd', 'nz'};
% Gli ingressi ora sono i tuoi "Comandi Virtuali" (Reference)
nomi_comandi = {'Cmd_Vt', 'Cmd_alpha', 'Cmd_q', 'Cmd_xbdd', 'Cmd_zbdd', 'Cmd_nz'};

% 4. Convertiamo la matrice in una Tabella formattata
RGA_table = array2table(round(RGA_dec, 4), ...
    'RowNames', nomi_uscite, ...
    'VariableNames', nomi_comandi);

% 5. Stampiamo a schermo
disp('Matrice RGA (Arrotondata e Mappata sui Canali di Volo):');
disp(RGA_table);

% =========================================================================
% VISUALIZZAZIONE GRAFICA: HEATMAP DEL SISTEMA DISACCOPPIATO
% =========================================================================
% Creiamo una nuova figura
figure('Name', 'Analisi RGA Post-Disaccoppiamento', 'Position', [150, 150, 750, 550]);

% Generiamo la Heatmap passando le etichette corrette
h_dec = heatmap(nomi_comandi, nomi_uscite, RGA_dec);

% Formattazione per renderla "da tesi"
h_dec.Title = 'Efficacia del Disaccoppiamento in Avanti (Target: Diagonale = 1)';
h_dec.XLabel = 'Comandi Virtuali (Riferimenti di Controllo)';
h_dec.YLabel = 'Uscite Fisiche (Sensori)';

% Usiamo la colormap standard di MATLAB (parula) 
colormap(parula); 

% Arrotondiamo a 2 o 3 decimali per non sovrapporre i numeri nelle celle
h_dec.CellLabelFormat = '%.3f';



