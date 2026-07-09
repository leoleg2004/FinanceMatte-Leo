% =========================================================================
% VALUTAZIONE ZERI E PROPRIETÀ BLOCCANTE (Sistema Completo 3x3)
% Ing. Leggeri Leonardo
% =========================================================================
disp('--- Analisi Proprietà Bloccante su Sistema Completo 3x3 ---');

% Estraiamo le dimensioni e le sottomatrici
n_stati = size(A_long, 1);
ingressi_3x3 = [1, 2, 3]; % Thrust, Elevator, LE_Flap
uscite_3x3 = [1, 2, 3];   % V_t, alpha, q

B_3x3 = B_long(:, ingressi_3x3);
C_3x3 = C_long(uscite_3x3, :);
D_3x3 = D_long(uscite_3x3, ingressi_3x3);

% Modello in Spazio di Stato 3x3
sys_3x3 = ss(A_long, B_3x3, C_3x3, D_3x3);

% Calcolo degli zeri invarianti
Zeri_3x3 = tzero(sys_3x3);

disp('Zeri Invarianti calcolati per il sistema 3x3:');
disp(Zeri_3x3); % Sarà un array vuoto []

% Verifica e Spiegazione a schermo
if isempty(Zeri_3x3)
    disp('---------------------------------------------------------');
    disp('RISULTATO STRUTTURALE: Il sistema 3x3 NON ha zeri invarianti.');
    disp('Non esiste alcuna frequenza lambda (reale o complessa) capace');
    disp('di bloccare la trasmissione degli ingressi verso le uscite.');
    disp('La matrice di sistema ha sempre rango pieno.');
    disp('---------------------------------------------------------');
end

% =========================================================================
% CONTROPROVA: Proprietà Bloccante su Sottosistema Sottoattuato (2x2)
% =========================================================================
disp('--- Analisi Proprietà Bloccante Sottosistema 2x2 ---');

n_stati = size(A_long, 1);

% Selezioniamo 2 ingressi (Thrust, Elevator) e 2 uscite (V_t, q)
ingressi_2x2 = [1, 2]; 
uscite_2x2 = [1, 3];   

B_2x2 = B_long(:, ingressi_2x2);
C_2x2 = C_long(uscite_2x2, :);
D_2x2 = D_long(uscite_2x2, ingressi_2x2);

% Creazione Sottosistema
sys_2x2 = ss(A_long, B_2x2, C_2x2, D_2x2);

% Calcolo Zeri Invarianti
Zeri_2x2 = tzero(sys_2x2);
disp('Zeri Invarianti calcolati per il 2x2:');
disp(Zeri_2x2);

if ~isempty(Zeri_2x2)
    % Prende il primo zero (che sarà lo zero di macchina ~ 1e-15)
    lambda = Zeri_2x2(1); 
    
    % Matrice di Rosenbrock
    P_lambda = [lambda * eye(n_stati) - A_long, -B_2x2; 
                C_2x2,                           D_2x2];
    
    % Nullspace per trovare direzioni bloccanti
    N = null(P_lambda); 
    
    if ~isempty(N)
        % Estrazione direzioni (parte reale per sicurezza contro rumore numerico)
        x0 = real(N(1:n_stati, 1));
        u0 = real(N(n_stati+1:end, 1));
        
        % Simulazione
        t = 0:0.01:10; 
        u_t = (u0 * exp(real(lambda) * t))'; 
        
        [y_sim, t_sim, x_sim] = lsim(sys_2x2, u_t, t, x0);
        
        % ==========================================
        % GRAFICO FORMATTATO PER IL REPORT
        % ==========================================
        fig = figure('Name', 'Proprieta_Bloccante_2x2', 'Color', 'w', 'Position', [100, 100, 700, 500]);
        
        % Subplot Ingressi
        subplot(2,1,1);
        plot(t, u_t, 'LineWidth', 2);
        title('Ingressi Bloccanti (Condizione di Trim)', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('Ampiezza Comando');
        legend('Spinta (Thrust)', 'Equilibratore (Elevator)', 'Location', 'best');
        grid on;
        
        % Subplot Uscite
        subplot(2,1,2);
        plot(t, y_sim, 'LineWidth', 2);
        title('Risposta del Sottosistema (Uscite Mascherate)', 'FontSize', 12, 'FontWeight', 'bold');
        xlabel('Tempo [s]');
        ylabel('Variazione Uscita');
        ylim([-0.05 0.05]); % Limiti stretti per evidenziare che è esattamente zero
        legend('$V_t$', '$q$', 'Location', 'best', 'Interpreter', 'latex');
        grid on;
        
        disp('Grafico generato. Salvalo per il report!');
    else
        disp('Errore: Nullspace vuoto.');
    end
end