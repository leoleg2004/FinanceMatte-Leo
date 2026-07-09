% Script per simulare il volo di crociera del modello F-16
% Questo script esegue il trim dell'aereo e poi utilizza
% le condizioni linearizzate per inizializzare la simulazione.
% =========================================================================
% Tesi Triennale - Grafici volo di crociera con simulink
% Ing. Leggeri Leonardo
% =========================================================================

% Assicuriamoci che tutte le cartelle del progetto siano nel path di MATLAB!
% Questo comando naviga nella cartella superiore rispetto a questo script
% e lancia lo startup del progetto, garantendo che MATLAB trovi tutti i file.
addpath(fullfile(fileparts(mfilename('fullpath')), '..'));
startup_project();

disp('Caricamento costanti di conversione...');
conversion % Carica le costanti di conversione

% 1. Caricamento dei parametri del sistema
Param = load_F16_params();

% 2. Esecuzione del trim per trovare le condizioni di crociera
% (Il file TrimF16 eseguirà un'ottimizzazione tramite particle swarm)
disp('Avvio della ricerca del punto di trim (crociera)...');
%%TrimF16; % Genera op, opreport, best_u e best_theta

% 3. Impostazione delle Condizioni Iniziali (IC) dai risultati del trim
h0 = -10000 * ft2m; % Altitudine specificata in TrimF16 e runF16
Vt0 = 91.4400;      % Velocità definita in TrimF16

% Popoliamo l'oggetto IC richiesto da Simulink per gli integratori
IC.inertial_position = [0, 0, h0]; 
IC.body_velocity = [Vt0 * cos(best_theta), 0, Vt0 * sin(best_theta)]; 
IC.euler_angles = [0, best_theta, 0];  
IC.omega = [0, 0, 0];            

% Prepariamo anche i vettori x0 e u0 nel workspace 
% (x0 può essere utile per altre funzioni, anche se IC viene letto da Simulink)
x0 = [IC.inertial_position, IC.euler_angles, IC.body_velocity, IC.omega];

% Vettore degli ingressi u0: [Thrust, Elevator, Aileron, Rudder, LEF, dx, dz]
% best_u(1) = Thrust, best_u(2) = Elevator, best_u(3) = LEF
u0 = [best_u(1), best_u(2), 0, 0, best_u(3), 0, 0];

% 4. Avvio della simulazione Simulink
Tend = 10; % Tempo di simulazione (modificabile)
disp(['Avvio della simulazione (Tend = ', num2str(Tend), 's)...']);

% IMPORTANTE: Simulink carica i modelli tramite il Path di MATLAB. 
% NON usare percorsi relativi, inserisci solo il nome del modello senza estensione.
simout = sim('F16_2022a'); 

% 5. Plot delle traiettorie
disp('Generazione dei grafici delle traiettorie...');
plot_trajectories(simout);
