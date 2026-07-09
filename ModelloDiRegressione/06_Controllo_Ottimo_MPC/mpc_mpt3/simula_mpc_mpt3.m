function [storia_x, storia_u, flags] = simula_mpc_mpt3(mpc_ingr, x_iniziale, x_ref, u_ref, t_sim, A_long_ds, B_ctrl_ds, dU_max, dU_min)
    % SIMULA_MPC_MPT3 Esegue la simulazione passo-passo dell'MPC usando quadprog
    % e tenendo conto dei rate constraints.
    
    nx = size(A_long_ds, 1);
    nu = size(B_ctrl_ds, 2);
    Np = mpc_ingr.Np;
    
    storia_x = zeros(nx, t_sim+1);
    storia_x(:, 1) = x_iniziale;
    storia_u = zeros(nu, t_sim);
    flags = zeros(1, t_sim);

    u_previous = zeros(nu, 1);

    % Matrici per i rate constraints
    A_rate_block = kron(eye(Np), eye(nu)) + kron(diag(ones(Np-1,1), -1), -eye(nu));
    A_rate = [A_rate_block; -A_rate_block];
    options = optimoptions('quadprog', 'Display', 'off');

    for tt = 1:t_sim
        x_lin_shifted = storia_x(:, tt) - x_ref;

        f = mpc_ingr.f_base * x_lin_shifted;
        b_ineq = mpc_ingr.b_ineq_base - mpc_ingr.b_ineq_x0_factor * x_lin_shifted; 

        b_rate = zeros(2 * Np * nu, 1);
        b_rate(1:Np*nu) = repmat(dU_max, Np, 1);
        b_rate(Np*nu+1 : 2*Np*nu) = repmat(-dU_min, Np, 1);
        b_rate(1:nu) = b_rate(1:nu) + u_previous - u_ref;
        b_rate(Np*nu+1 : Np*nu+nu) = b_rate(Np*nu+1 : Np*nu+nu) - (u_previous - u_ref);

        A_ineq_tot = [mpc_ingr.A_ineq; A_rate];
        b_ineq_tot = [b_ineq; b_rate];

        [delta_u_seq, ~, exitflag] = quadprog(mpc_ingr.F, f, A_ineq_tot, b_ineq_tot, [], [], [], [], [], options);
        flags(tt) = exitflag;

        if exitflag ~= 1 && exitflag ~= 0
            if tt > 1
                u_applicata = u_previous;
            else
                u_applicata = zeros(nu, 1);
            end
        else
            u_applicata = delta_u_seq(1:nu) + u_ref;
        end
        
        storia_u(:, tt) = u_applicata;
        storia_x(:, tt+1) = A_long_ds * storia_x(:, tt) + B_ctrl_ds * u_applicata;
        u_previous = u_applicata;
    end
end
