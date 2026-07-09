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

function mpc_prob = setup_mpc(N, nx, nu, A_long_ds, B_ctrl_ds, Q, P, R, U_min, U_max, Gx, gx, G_inf, g_inf, x_ref, u_ref)
    % SETUP_MPC Prepara tutte le matrici per il quadprog
    n_vars = N*nu + N*nx; 
    
    R_blk = kron(eye(N), R);
    Q_blk = blkdiag(kron(eye(N-1), Q), P);
    H = 2 * blkdiag(R_blk, Q_blk);         
    
    % Termine lineare della funzione di costo per l'inseguimento del riferimento
    f = zeros(n_vars, 1);                  
    for k = 1:N
        f((k-1)*nu + 1 : k*nu) = -2 * R * u_ref;
    end
    for k = 1:N-1
        f(N*nu + (k-1)*nx + 1 : N*nu + k*nx) = -2 * Q * x_ref;
    end
    f(N*nu + (N-1)*nx + 1 : N*nu + N*nx) = -2 * P * x_ref;
    
    Aeq_base = zeros(N*nx, n_vars);
    for k = 1:N
        Aeq_base((k-1)*nx + 1 : k*nx, (k-1)*nu + 1 : k*nu) = -B_ctrl_ds;
        Aeq_base((k-1)*nx + 1 : k*nx, N*nu + (k-1)*nx + 1 : N*nu + k*nx) = eye(nx);
        if k > 1
            Aeq_base((k-1)*nx + 1 : k*nx, N*nu + (k-2)*nx + 1 : N*nu + (k-1)*nx) = -A_long_ds;
        end
    end
    
    lb = -inf(n_vars, 1); ub = inf(n_vars, 1); 
    for k = 1:N
        lb((k-1)*nu + 1 : k*nu) = U_min;
        ub((k-1)*nu + 1 : k*nu) = U_max;
    end
    
    A_ineq_stat = []; b_ineq_stat = [];
    for j = 1:N-1
        A_t = zeros(size(Gx, 1), n_vars);
        A_t(:, N*nu + (j-1)*nx + 1 : N*nu + j*nx) = Gx;
        A_ineq_stat = [A_ineq_stat; A_t];
        b_ineq_stat = [b_ineq_stat; gx];
    end
    
    A_t = zeros(size(G_inf, 1), n_vars);
    A_t(:, N*nu + (N-1)*nx + 1 : N*nu + N*nx) = G_inf;
    A_ineq_stat = [A_ineq_stat; A_t];
    b_ineq_stat = [b_ineq_stat; g_inf];
    
    % Salvataggio in struttura
    mpc_prob.H = H;
    mpc_prob.f = f;
    mpc_prob.Aeq_base = Aeq_base;
    mpc_prob.lb = lb;
    mpc_prob.ub = ub;
    mpc_prob.A_ineq_stat = A_ineq_stat;
    mpc_prob.b_ineq_stat = b_ineq_stat;
    mpc_prob.n_vars = n_vars;
    mpc_prob.N = N;
    mpc_prob.nx = nx;
    mpc_prob.nu = nu;
end
