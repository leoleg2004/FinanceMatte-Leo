function [K, P, Q, R, A_cl] = progetta_LQR_portfolio_discreto(A_d, B_d)
    % =====================================================================
    % Calcolo pesi LQR per Asset Allocation (Regola di Bryson)
    % Stati: Pesi azionari (es. VWCE, SXRV, ZPRR)
    % Ingressi: Trades Delta Peso
    % =====================================================================
    
    nx = size(A_d, 1);
    nu = size(B_d, 2);
    
    % Massimi scostamenti tollerabili per gli stati (Bryson's rule)
    % Quanto tolleriamo che il portafoglio si discosti dal target?
    max_dev_x = 0.10; % 10% di scostamento tollerato dai pesi ideali
    
    % Matrice Q normalizzata
    Q = diag(repmat(1 / max_dev_x^2, 1, nx));
    
    % Massimi scostamenti tollerabili per gli attuatori (Trades)
    % Quanto vogliamo limitare ogni singolo trade per evitare altissime commissioni?
    max_trade_u = 0.05; % max 5% del capitale mosso per singola operazione
    
    % Matrice R normalizzata
    R = diag(repmat(1 / max_trade_u^2, 1, nu));
    
    % Fattori di tuning per dare più o meno aggressività globale
    rho_q = 1;   % Aggressività di inseguimento del benchmark
    rho_r = 10;  % Moltiplicatore di penalità sul trading
    
    Q = rho_q * Q;
    R = rho_r * R;
    
    % Sintesi LQR
    [K, P, ~] = dlqr(A_d, B_d, Q, R);
    A_cl = A_d - B_d*K;
end
