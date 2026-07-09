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