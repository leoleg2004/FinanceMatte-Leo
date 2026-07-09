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

<<<<<<< HEAD
function [H_nsteps, h_nsteps] = controllable_set(Fx, fx, Fu, fu, G_inf, g_inf, A, B, N)
    % Controllable Set N-Step tramite Polyhedron
    nx = size(A, 1);
    nu = size(B, 2);
    H_ii_steps = G_inf;
    h_ii_steps = g_inf;
    Hu = Fu; hu = fu;
    Gx = Fx; gx = fx;

    for ii = 1:N
        A_k_1 = [H_ii_steps * A, H_ii_steps * B;
                 zeros(size(Hu, 1), nx), Hu]; 
        B_k_1 = [h_ii_steps; hu];
        temp = Polyhedron(A_k_1, B_k_1); 
        temp = projection(temp, 1:nx); 
        temp.minHRep(); 
        H_ii_steps = [temp.A; Gx]; 
        h_ii_steps = [temp.b; gx];
    end
    H_nsteps = H_ii_steps;
    h_nsteps = h_ii_steps;
end
=======
function [H_nsteps, h_nsteps] = controllable_set(Hx, hx, Hu, hu, H_target, h_target, A, B, N)

% 1. Inizializzare a partire dal set più piccolo che posso raggiungere
%(H_target(x) <= h_target)
n = size(A, 2); % n = numero di stati
m = size(B, 2); % m = numero di ingressi

H_ii_steps = H_target;
h_ii_steps = h_target;

% Aggiorno iterativamente il set
for ii = 1:N
    % Calcol oin R^(n+m)
    A_k_1 = [H_ii_steps*A H_ii_steps*B;
             zeros(size(Hu, 1), n) Hu]; 
    
    B_k_1 = [h_ii_steps;
             hu];
    
    temp = Polyhedron(A_k_1, B_k_1); % Questo poliedro contiene coppie (x,u)

    % Proiezione in R^(n)
    temp = projection(temp, 1:n); % Questo poliedro contiene solo (x)

    temp.minHRep(); % Semplifichiamo la rappresentazione del poliedro

    % Intersezione con i vincoli di stato (Hx(x) <= hx)
    H_ii_steps = [temp.A; Hx]; 
    h_ii_steps = [temp.b; hx];
end

H_nsteps = H_ii_steps;
h_nsteps = h_ii_steps;

end 
>>>>>>> origin/main
