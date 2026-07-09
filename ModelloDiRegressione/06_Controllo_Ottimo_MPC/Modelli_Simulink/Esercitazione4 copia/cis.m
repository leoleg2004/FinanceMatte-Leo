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

function [G,g] = cis(A, B, x_ref, u_ref, Fx, fx, Fu, fu, Q, R)

% 1. Formulazione K del controllore LQR
K = -dlqr(A,B,Q,R);

% 2. Matrice A del sistema controllato con LQR
A_lqr = A + B*K;

% 3. Riformulazione dei vincoli su stato e ingresso combinati (F(x) <= f)
F = [Fx; Fu*K];
f = [fx; fu + Fu*(K*x_ref - u_ref)];

% 4. Calcolo del CIS (G(x) <= g)
CIS_poly_prev = Polyhedron();
CIS_poly_curr = Polyhedron(F,f);
while CIS_poly_prev.isEmptySet || CIS_poly_prev ~= CIS_poly_curr
    % Memorizzare il vecchio candidato
    CIS_poly_prev = CIS_poly_curr;

    % Calcolo del nuovo candidato
    G_hat = [CIS_poly_prev.A * A_lqr;
            F];
    g_hat = [CIS_poly_prev.b + CIS_poly_prev.A * B * (K*x_ref - u_ref);
            f];

    CIS_poly_curr = Polyhedron(G_hat, g_hat);

end
% 5. Disequazioni che descrivono il CSI (G(x) <= g)
G = CIS_poly_curr.A;
g = CIS_poly_curr.b;

end