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
% Tesi Triennale - Set Controllabili MPC 
% Dimostrazione: Inclusione vs Non-Inclusione con IDENTICA Convergenza
% Ing: Leggeri Leonardo
% =========================================================================
clear; clc; close all;
set(0,'DefaultLineLineWidth',1.5);
set(0,'DefaultAxesFontSize',14);
set(0,'DefaulttextInterpreter','latex');

%% 1. Definizione Sistema Lineare 2D 
A = [1, 1; 
     0, 1];
B = [0.5; 
     1];
U_max = 0.5;
X_max = 5;

N_steps = 12; % Numero di passi per raggiungere la convergenza visiva

%% 2. Preparazione dei due Target
% TARGET A: Invariante (Piccolo set vicino all'origine)
Target_A = polyshape([-0.5 0.5 0.5 -0.5], [-0.5 -0.5 0.5 0.5]);
% Lo rendiamo rigorosamente invariante filtrandolo all'indietro
for j=1:5, Target_A = intersect(Target_A, calcola_O1passo(Target_A, A, B, U_max, X_max)); end

% TARGET B: Non Invariante (Quadrato disallineato arbitrario)
Target_B = polyshape([1 3 3 1], [1 1 3 3]);

%% 3. Inizializzazione Interfaccia Grafica Affiancata
figure('Name', 'Algoritmo Slide 44: Convergenza a O_inf', 'Color', 'w', 'Position', [100 100 1100 550]);

% Subplot Sinistro: Caso Invariante
ax1 = subplot(1,2,1); hold on; grid on; axis equal; xlim([-6 6]); ylim([-6 6]);
title('Target Invariante: $\mathcal{S}_i \subseteq \mathcal{S}_{i+1}$');
xlabel('$x_1$'); ylabel('$x_2$');
plot([-X_max X_max X_max -X_max -X_max], [-X_max -X_max X_max X_max -X_max], 'k--', 'LineWidth', 1);
plot(Target_A, 'FaceColor', 'r', 'FaceAlpha', 0.8, 'EdgeColor', 'r');

% Subplot Destro: Caso Non Invariante
ax2 = subplot(1,2,2); hold on; grid on; axis equal; xlim([-6 6]); ylim([-6 6]);
title('Target Non Invariante: $\mathcal{C}_i \not\subseteq \mathcal{C}_{i+1}$');
xlabel('$x_1$'); ylabel('$x_2$');
plot([-X_max X_max X_max -X_max -X_max], [-X_max -X_max X_max X_max -X_max], 'k--', 'LineWidth', 1);
plot(Target_B, 'FaceColor', 'b', 'FaceAlpha', 0.8, 'EdgeColor', 'b');

drawnow;
disp('Premi un tasto nella Command Window per avviare l''animazione...');
pause;

%% 4. Esecuzione Animata dell'Algoritmo (Slide 44)
Ci_A = Target_A;
Ci_B = Target_B;
colori = parula(N_steps+2); % Mappa colori per mostrare l'evoluzione

for i = 1:N_steps
    % Calcolo del passo precedente usando la funzione O1passo
    Ci_A = calcola_O1passo(Ci_A, A, B, U_max, X_max);
    Ci_B = calcola_O1passo(Ci_B, A, B, U_max, X_max);
    
    % Aggiornamento Grafico Sinistra (Invariante)
    plot(ax1, Ci_A, 'FaceColor', 'none', 'EdgeColor', colori(i,:), 'LineWidth', 2);
    
    % Aggiornamento Grafico Destra (Non Invariante)
    if Ci_B.NumRegions > 0
        plot(ax2, Ci_B, 'FaceColor', 'none', 'EdgeColor', colori(i,:), 'LineWidth', 2);
    end
    
    % Animazione step-by-step
    sgtitle(['Calcolo in corso... Passo all''indietro $i = ' num2str(i) '$'], 'Interpreter', 'latex', 'FontSize', 18);
    drawnow;
    pause(0.6); % Pausa per far apprezzare la formazione geometrica
end

%% 5. Evidenziazione della Convergenza allo Stesso Set
% Disegniamo il set finale di entrambi in NERO SPESSO per mostrare che sono identici
plot(ax1, Ci_A, 'FaceColor', 'none', 'EdgeColor', 'k', 'LineWidth', 3);
plot(ax2, Ci_B, 'FaceColor', 'none', 'EdgeColor', 'k', 'LineWidth', 3);
sgtitle('Convergenza completata allo stesso set: $\mathcal{S}_\infty = \mathcal{C}_\infty = \mathcal{O}_\infty$', 'Interpreter', 'latex', 'FontSize', 18, 'Color', 'k', 'FontWeight', 'bold');
disp('Animazione terminata. Nota come i due bordi neri finali siano identici.');

% =======================================================================
%% FUNZIONE DI PROIEZIONE (Equivalente a O1passo di Slide 44)
% =======================================================================
function Q_out = calcola_O1passo(Omega_in, A, B, U_max, X_max)
    % Implementazione geometrica esatta di Q(Omega)
    if Omega_in.NumRegions == 0
        Q_out = polyshape(); return;
    end
    
    V_omega = Omega_in.Vertices;
    V_omega(isnan(V_omega(:,1)), :) = []; 
    
    A_inv = inv(A);
    v_shift = A_inv * B * U_max;
    
    % Proiezione all'indietro dei vertici
    V1 = (A_inv * V_omega')' + v_shift';
    V2 = (A_inv * V_omega')' - v_shift';
    
    V_all = [V1; V2];
    K_hull = convhull(V_all(:,1), V_all(:,2));
    Pre_Set = polyshape(V_all(K_hull,1), V_all(K_hull,2));
    
    % Intersezione con i vincoli di stato x \in X
    Set_X = polyshape([-X_max X_max X_max -X_max], [-X_max -X_max X_max X_max]);
    Q_out = intersect(Pre_Set, Set_X);
end