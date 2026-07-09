function [storia_x, storia_u, storia_costo] = simula_mpc_portfolio(mpc_prob, x_iniziale, t_sim, A, B, Sigma)
    % SIMULA_MPC_PORTFOLIO Risolve il problema quadratico MIMO
    nx = mpc_prob.nx;
    nu = mpc_prob.nu;
    N = mpc_prob.N;
    
    storia_x = zeros(nx, t_sim+1); 
    storia_x(:,1) = x_iniziale;
    storia_u = zeros(nu, t_sim);
    storia_costo = zeros(1, t_sim);
    
    options = optimoptions('quadprog', 'Display', 'off');
    
    for t = 1:t_sim
        % Costruisci b_eq
        beq_dyn = zeros(N*nx, 1);
        beq_dyn(1:nx) = A * storia_x(:,t); 
        
        beq_self = zeros(N, 1); % sum(u) = 0
        beq_inv = ones(N, 1);   % sum(x) = 1
        
        beq = [beq_dyn; beq_self; beq_inv];
        
        [z_opt, fval, exitflag] = quadprog(mpc_prob.H, mpc_prob.f, [], [], mpc_prob.Aeq_base, beq, mpc_prob.lb, mpc_prob.ub, [], options);
        
        % Traslazione in modo che V(x_ref) = 0 (Definita Positiva)
        storia_costo(t) = fval + mpc_prob.cost_const;
        
        if exitflag < 0
            warning('Infeasible a t=%d! Mantengo i pesi precedenti.', t);
            u_applicata = zeros(nu, 1);
        else
            u_applicata = z_opt(1:nu);
        end
        
        storia_u(:, t) = u_applicata;
        
        % Simulazione ambiente (Plant) con rumore stocastico
        wk = mvnrnd(zeros(nx,1), Sigma)';
        x_next = A * storia_x(:,t) + B * u_applicata + diag(wk) * (storia_x(:,t) + u_applicata);
        x_next = max(x_next, 0); % No shorting reale
        x_next = x_next / sum(x_next); % Normalizza a 1
        
        storia_x(:, t+1) = x_next;
    end
end
