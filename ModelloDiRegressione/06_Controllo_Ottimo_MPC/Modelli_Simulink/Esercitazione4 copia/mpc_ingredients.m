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

function mpc_ingr = mpc_ingredients(A, B, Hx, hx, Hu, hu, ...
                                    CIS_H, CIS_h, x_ref, u_ref, Q, R, Np)

% Dimensione stato e ingresso
n = size(A,2);
m = size(B,2);

% Dimensione vincolo terminale
n_ter = length(CIS_h);

% Matrice del costo terminale
[~, P, ~] = dlqr(A, B, Q, R);

% Traslazione dei vincoli rispetto al riferimento
Hx_shifted = Hx;
hx_shifted = hx - Hx*x_ref;

Hu_shifted = Hu;
hu_shifted = hu - Hu*u_ref;

% Peso sugli stati
Q_tilde = kron(eye(Np),Q);
Q_tilde = blkdiag(Q_tilde,P);

% Peso sugli ingressi
R_tilde = kron(eye(Np),R);

% Matrice dipendenza predizione da stato iniziale (A_cal)
A_cal = zeros(n*(Np+1),n);
for ii = 1:(Np+1)
    if ii == 1
        A_cal((ii-1)*n+1:ii*n, :) = eye(n); % alla prima iterazione voglio la matrice identità
    else
        A_cal((ii-1)*n+1:ii*n, :) = A^(ii-1); % Alle iterazioni successive assegna A^elevato alla ii-1
    end
end

% Matrice dipendenza predizione da ingresso iniziale (B_cal)
B_cal = zeros(n*(Np+1),m*Np);

A_cal_times_B = A_cal * B;
for ii = 1:Np
    B_cal(ii*n+1:end, (ii-1)*m+1:ii*m) = A_cal_times_B(1:(Np-ii+1)*n,:);

end

% Calcolo della matrice hessiana per il costo quadratico
F = B_cal' * Q_tilde * B_cal + R_tilde;


% Calcolo della componente lineare per il costo quadratico
f_base = B_cal' * Q_tilde * A_cal;

% Vincoli
Hx_tilde = kron(eye(Np+1), Hx_shifted);
hx_tilde = repmat(hx_shifted, [Np+1, 1]);

Hx_tilde = [Hx_tilde; zeros(n_ter, Np*n), CIS_H];
hx_tilde = [hx_tilde; CIS_h];

Hu_tilde = kron(eye(Np), Hu_shifted);
hu_tilde = repmat(hu_shifted, [Np,1]);

% Admissible input set (inequalities) 
A_ineq = [Hx_tilde * B_cal; 
          Hu_tilde];
b_ineq_base = [hx_tilde; 
               hu_tilde];
b_ineq_x0_factor = [Hx_tilde * A_cal; 
                    zeros(2*m*Np,n)];

% Creazione struttura mpc_ingr
mpc_ingr.F                  = F;
mpc_ingr.f_base             = f_base;
mpc_ingr.A_ineq             = A_ineq;
mpc_ingr.b_ineq_base        = b_ineq_base;
mpc_ingr.b_ineq_x0_factor   = b_ineq_x0_factor;
mpc_ingr.Np                 = Np;


end % Fine funzione