% =========================================================================
% STARTUP.m
% Aggiunge le cartelle delle funzioni e del toolbox MPT3 al path di MATLAB
% per garantire il corretto funzionamento del MPC di Portafoglio.
% =========================================================================

disp('--- Esecuzione Automatica di Startup ---');

% Aggiunge cartelle locali al path
addpath(fullfile(pwd, 'funzioni_mpc'));
addpath(fullfile(pwd, 'funzioni_lqr'));

% Seleziona la directory del toolbox MPT3
mpt3_path = fullfile(pwd, 'toolboxes', 'mpt');

if exist(mpt3_path, 'dir')
    addpath(mpt3_path);
    disp('Toolbox MPT3 aggiunto al path.');
    
    % MPT3 di solito richiede un'inizializzazione tramite mpt_init.
    % Decommentare la riga successiva se necessario:
    % mpt_init; 
else
    disp('Attenzione: Cartella MPT3 non trovata in toolboxes/');
end

disp('Path di progetto aggiornato con successo. Le funzioni MPC sono pronte.');
