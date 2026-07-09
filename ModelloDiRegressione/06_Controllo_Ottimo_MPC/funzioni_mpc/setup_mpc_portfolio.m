function mpc_prob = setup_mpc_portfolio(N, nx, nu, A, B, Q, P, R, x_ref, u_ref)
    % SETUP_MPC_PORTFOLIO Prepara tutte le matrici per il quadprog (Formulazione Sparse)
    n_vars = N*nu + N*nx; 
    
    R_blk = kron(eye(N), R);
    Q_blk = blkdiag(kron(eye(N-1), Q), P);
    H = 2 * blkdiag(R_blk, Q_blk);         
    
    f = zeros(n_vars, 1);                  
    for k = 1:N
        f((k-1)*nu + 1 : k*nu) = -2 * R * u_ref;
    end
    for k = 1:N-1
        f(N*nu + (k-1)*nx + 1 : N*nu + k*nx) = -2 * Q * x_ref;
    end
    f(N*nu + (N-1)*nx + 1 : N*nu + N*nx) = -2 * P * x_ref;
    
    % Vincoli di Dinamica x(k+1) = A*x(k) + B*u(k)
    Aeq_dyn = zeros(N*nx, n_vars);
    for k = 1:N
        Aeq_dyn((k-1)*nx + 1 : k*nx, (k-1)*nu + 1 : k*nu) = -B;
        Aeq_dyn((k-1)*nx + 1 : k*nx, N*nu + (k-1)*nx + 1 : N*nu + k*nx) = eye(nx);
        if k > 1
            Aeq_dyn((k-1)*nx + 1 : k*nx, N*nu + (k-2)*nx + 1 : N*nu + (k-1)*nx) = -A;
        end
    end
    
    % Vincoli Finanziari
    % 1) Self financing: sum(u_k) = 0 per ogni k
    Aeq_self = zeros(N, n_vars);
    for k = 1:N
        Aeq_self(k, (k-1)*nu + 1 : k*nu) = ones(1, nu);
    end
    
    % 2) Fully invested: sum(x_k) = 1 per ogni k
    Aeq_inv = zeros(N, n_vars);
    for k = 1:N
        Aeq_inv(k, N*nu + (k-1)*nx + 1 : N*nu + k*nx) = ones(1, nx);
    end
    
    % Combina uguaglianze
    Aeq_base = [Aeq_dyn; Aeq_self; Aeq_inv];
    
    % Lower/Upper bounds
    lb = -inf(n_vars, 1); 
    ub = inf(n_vars, 1); 
    
    % No short selling (x >= 0)
    for k = 1:N
        lb(N*nu + (k-1)*nx + 1 : N*nu + k*nx) = 0;
        ub(N*nu + (k-1)*nx + 1 : N*nu + k*nx) = 1;
    end
    % Limiti massimi di trade per singolo mese (es. max 20% del ptf scambiato)
    for k = 1:N
        lb((k-1)*nu + 1 : k*nu) = -0.2;
        ub((k-1)*nu + 1 : k*nu) = 0.2;
    end
    
    mpc_prob.H = H;
    mpc_prob.f = f;
    mpc_prob.Aeq_base = Aeq_base;
    mpc_prob.lb = lb;
    mpc_prob.ub = ub;
    mpc_prob.A_ineq_stat = [];
    mpc_prob.b_ineq_stat = [];
    
    % Costante per traslare il funzionale di costo affinché V(x_ref) = 0
    cost_const = (N-1) * (x_ref' * Q * x_ref) + (x_ref' * P * x_ref) + N * (u_ref' * R * u_ref);
    mpc_prob.cost_const = cost_const;
    
    mpc_prob.n_vars = n_vars;
    mpc_prob.N = N;
    mpc_prob.nx = nx;
    mpc_prob.nu = nu;
end
