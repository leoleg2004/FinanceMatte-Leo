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

function dcm = calcola_dcm(best_theta)
    % La variabile in ingresso (best_theta) viene usata per calcolare la DCM
    dcm = [ cos(best_theta),  0, -sin(best_theta);
            0,                1,  0;
            sin(best_theta),  0,  cos(best_theta)];
end