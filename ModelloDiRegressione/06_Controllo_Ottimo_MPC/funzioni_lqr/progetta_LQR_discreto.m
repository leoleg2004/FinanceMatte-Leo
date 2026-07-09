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

function [K, P, Q, R, A_cl] = progetta_LQR_discreto(A, B)
    % =====================================================================
    % Calcolo pesi LQR (Regola di Bryson) coerenti con il modello F-16
    % Ordine stati: [theta (rad); q (rad/s); U (ft/s); W (ft/s)]
    % Ordine input: [Thrust (lbs); Elevator (rad); LEF (rad)]
    % =====================================================================
    
    % Massimi scostamenti tollerabili per gli stati (Bryson's rule)
    max_theta = deg2rad(15); % 15 gradi max tollerati per il pitch
    max_q     = deg2rad(30); % 30 deg/s max tollerati per il pitch rate
    max_U     = 30;          % 30 ft/s max per la velocità X
    max_W     = 20;          % 20 ft/s max per la velocità Z (incide su alpha)
    
    Q = diag([1/max_theta^2, 1/max_q^2, 1/max_U^2, 1/max_W^2]);
    
    % Massimi scostamenti tollerabili per gli attuatori
    max_thrust = 5000;       % 5000 lbs variazione manetta
    max_elev   = deg2rad(25);% 25 gradi max deflessione equilibratore
    max_lef    = deg2rad(25);% 25 gradi max deflessione LEF
    
    R = diag([1/max_thrust^2, 1/max_elev^2, 1/max_lef^2]);
    
    % Fattori di tuning per dare più aggressività globale (se necessario)
    rho_q = 20;  % Bilanciamento: molto reattivo ma senza rendere il problema Infeasible
    rho_r = 1;   % Mantiene uno sforzo di controllo ragionevole per non violare i vincoli con x_iniziale elevato 
    
    Q = rho_q * Q;
    R = rho_r * R;
    
    % Sintesi LQR
    [K, P, ~] = dlqr(A, B, Q, R);
    A_cl = A - B*K;
end
