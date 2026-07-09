 % =========================================================================
% MINIMIZZAZIONE DEL SISTEMA (Raggiungibilità e Osservabilità)
% =========================================================================
% Tesi Triennale - Proprietà struturali per controllo longitudinale dell'
% F-16
% Simulazione con Conversione Continuo-Discreto (c2d) e Radianti
% Ing. Leggeri Leonardo
% =========================================================================

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
disp('--- Calcolo Matrice Funzioni di Trasferimento MINIMA G(s) ---');
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
% =========================================================================
% 1. PREPARAZIONE DELL'IMPIANTO MIMO 3x3
% =========================================================================
disp('--- 1. Preparazione Impianto G 3x3 ---');
uscite_ctrl = [1, 2, 3]; 
ingressi_ctrl = [1, 2, 3]; 
G = G_long_min(uscite_ctrl, ingressi_ctrl);

% =========================================================================
% 2. SINTESI ANALITICA DEL DISACCOPPIATORE DINAMICO (W)
% =========================================================================
disp('--- 2. Calcolo dei Pre-Compensatori (Metodo delle Equazioni) ---');

% Imponiamo che i comandi diretti passino inalterati (Diagonale = 1)
W11 = tf(1,1);
W22 = tf(1,1);
W33 = tf(1,1);

% --- COLONNA 1: Calcolo W21 e W31 ---
% Risolviamo il sistema per annullare i cross-talk su alpha e q (uscite 2 e 3)
Mat_C1 = [G(2,2), G(2,3); 
          G(3,2), G(3,3)];
Term_C1 = [-G(2,1); 
           -G(3,1)];
Incognite_C1 = inv(Mat_C1) * Term_C1;
W21 = minreal(Incognite_C1(1));
W31 = minreal(Incognite_C1(2));

% --- COLONNA 2: Calcolo W12 e W32 ---
% Risolviamo il sistema per annullare i cross-talk su Vt e q (uscite 1 e 3)
Mat_C2 = [G(1,1), G(1,3); 
          G(3,1), G(3,3)];
Term_C2 = [-G(1,2); 
           -G(3,2)];
Incognite_C2 = inv(Mat_C2) * Term_C2;
W12 = minreal(Incognite_C2(1));
W32 = minreal(Incognite_C2(2));

% --- COLONNA 3: Calcolo W13 e W23 ---
% Risolviamo il sistema per annullare i cross-talk su Vt e alpha (uscite 1 e 2)
Mat_C3 = [G(1,1), G(1,2); 
          G(2,1), G(2,2)];
Term_C3 = [-G(1,3); 
           -G(2,3)];
Incognite_C3 = inv(Mat_C3) * Term_C3;
W13 = minreal(Incognite_C3(1));
W23 = minreal(Incognite_C3(2));

% Assemblaggio della matrice W(s) completa
W_dinamico = [W11, W12, W13;
              W21, W22, W23;
              W31, W32, W33];
disp('Matrice W_dinamico assemblata con successo.');

% =========================================================================
% 3. VERIFICA E ISOLAMENTO DEI CANALI (CONSEGUENZA)
% =========================================================================
disp('--- 3. Calcolo G_nuova (G * W) e Isolamento Canali ---');
G_nuova = G * W_dinamico;

% Dato che sappiamo di aver imposto matematicamente gli zeri fuori diagonale,
% estraiamo direttamente la diagonale pulendola da piccoli residui numerici
tolleranza = 1e-3;
G_Vt_pulita    = minreal(G_nuova(1,1), tolleranza);
G_alpha_pulita = minreal(G_nuova(2,2), tolleranza);
G_q_pulita     = minreal(G_nuova(3,3), tolleranza);


%% Calcolo della Raggiungibilità / Controllabilità
% Otteniamo il numero di variabili di stato
n = size(A_long, 1);       

% 1. Calcolo della matrice di Raggiungibilità (Controllabilità)
R = ctrb(A_long, B_long);

% 2. Calcolo del rango della matrice
rango_R = rank(R);    

disp('--- Analisi di Raggiungibilità/Controllabilità ---');
% disp('Matrice di Raggiungibilità R:'); 
% disp(R); % Decommenta se vuoi stampare a schermo l'intera matrice

% 3. Verifica della completa raggiungibilità
% Il sistema è completamente raggiungibile se il rango della matrice R 
% è uguale al numero di variabili di stato n.
if rango_R == n
    disp(['✅ Il sistema è COMPLETAMENTE raggiungibile (Rango R = ', num2str(rango_R), ').']);
else
    disp('❌ Il sistema NON è completamente raggiungibile (rango incompleto).');
    disp(['Il rango della matrice R è ', num2str(rango_R), ' invece di ', num2str(n), '.']);
end

%% Calcolo della Raggiungibilità / Controllabilità
% Otteniamo il numero di variabili di stato
n = size(A_long, 1);       

% 1. Calcolo della matrice di Raggiungibilità (Controllabilità)
R = ctrb(A_long, B_long);

% 2. Calcolo del rango della matrice
rango_R = rank(R);    

disp('--- Analisi di Raggiungibilità/Controllabilità ---');
disp('Matrice di Raggiungibilità R:'); 
disp(R); % Ora la matrice verrà stampata a schermo

% 3. Verifica della completa raggiungibilità
if rango_R == n
    disp(['✅ Il sistema è COMPLETAMENTE raggiungibile (Rango R = ', num2str(rango_R), ').']);
else
    disp('❌ Il sistema NON è completamente raggiungibile (rango incompleto).');
    disp(['Il rango della matrice R è ', num2str(rango_R), ' invece di ', num2str(n), '.']);
end

%% Calcolo dell'Osservabilità
% 1. Calcolo della matrice di Osservabilità
O = obsv(A_long, C_long);

% 2. Calcolo del rango della matrice
rango_O = rank(O);    

disp(' '); % Riga vuota per separare l'output
disp('--- Analisi di Osservabilità ---');
disp('Matrice di Osservabilità O:'); 
disp(O); % Ora la matrice verrà stampata a schermo

% 3. Verifica della completa osservabilità
if rango_O == n
    disp(['✅ Il sistema è COMPLETAMENTE osservabile (Rango O = ', num2str(rango_O), ').']);
else
    disp('❌ Il sistema NON è completamente osservabile (rango incompleto).');
    disp(['Il rango della matrice O è ', num2str(rango_O), ' invece di ', num2str(n), '.']);
end