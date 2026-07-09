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

function [A_long_ds, B_ctrl_ds] = discretizza_modello(A_long, B_ctrl, nx, nu, Ts)
    % Converte il sistema da tempo continuo a discreto
    sys_c = ss(A_long, B_ctrl, eye(nx), zeros(nx, nu));
    sys_d = c2d(sys_c, Ts, 'zoh'); % Zero-Order Hold
    A_long_ds = sys_d.A;
    B_ctrl_ds = sys_d.B;
end
