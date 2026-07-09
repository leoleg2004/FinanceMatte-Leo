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

function startup_project()
    % Aggiunge tutte le cartelle necessarie al path di MATLAB per 
    % garantire il funzionamento di tutti gli script e modelli.
    cartelle = {'funzioni_mpc', 'funzioni_lqr', 'Modello_Matematico', ...
                'Modelli_Simulink', 'Dati_Mat', 'Analisi_di_Sistema', ...
                'Studi_Avanzati_Invarianza', 'Simulazioni_Simulink', 'Utility_Extra', 'Startup'};
    
    for i = 1:length(cartelle)
        path_cartella = fullfile(pwd, cartelle{i});
        if exist(path_cartella, 'dir')
            addpath(path_cartella);
        end
    end
    disp('Path di progetto aggiornato con successo. Tutte le funzioni sono pronte.');
end
