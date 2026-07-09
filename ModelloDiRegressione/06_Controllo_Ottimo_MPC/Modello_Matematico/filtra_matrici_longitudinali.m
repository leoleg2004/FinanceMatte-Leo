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

function [A_long, B_long, C_long, D_long, info] = filtra_matrici_longitudinali(linsys)
    % FILTRA_MATRICI_LONGITUDINALI Estrae il sottomodello longitudinale 
    % dal modello linearizzato completo (linsys) dell'F-16.
    % 
    % Delega la pulizia e il filtraggio delle matrici full per mantenere 
    % lo script principale più pulito.
    
    % Se linsys è un array LTI, prendi il primo elemento
    if numel(linsys) > 1
        linsys = linsys(:,:,1);
    end
    
    % Estrai matrici complete dallo spazio di stato
    [A_full, B_full, C_full, D_full] = ssdata(linsys);
    
    % --- Definizione Indici Modello Longitudinale ---
    % Stati: [theta, U, w, q]
    ix = [2, 5, 7, 9]; 
    % Ingressi: [T, dele, dlef, dist_x, dist_z]
    iu = [1, 2, 5, 6, 8]; 
    % Uscite: [Vt, alpha, q, xbdd, zbdd]
    iy = [7, 8, 13, 15, 17, 19]; 
    
    % Verifica compatibilità dimensioni
    if max(ix) > size(A_full,1) || max(ix) > size(A_full,2)
        error('Indici ix non compatibili con size(A_full) = [%d %d]', size(A_full));
    end
    if max(iu) > size(B_full,2)
        error('Indici iu non compatibili con size(B_full) = [%d %d]', size(B_full));
    end
    if max(iy) > size(C_full,1)
        error('Indici iy non compatibili con size(C_full) = [%d %d]', size(C_full));
    end
    
    % Estrai sottomatrici longitudinali (Filtraggio)
    A_long = A_full(ix, ix);
    B_long = B_full(ix, iu);
    C_long = C_full(iy, ix);
    D_long = D_full(iy, iu);
    
    % Autovalori
    ev = eig(A_long);
    
    % Stampa a schermo
    fprintf('\n--- Matrici Sottomodello Longitudinale Filtrate ---\n');
    fprintf('size(A_long) = [%d %d]\n', size(A_long)); disp('A_long ='); disp(A_long);
    fprintf('size(B_long) = [%d %d]\n', size(B_long)); disp('B_long ='); disp(B_long);
    fprintf('size(C_long) = [%d %d]\n', size(C_long)); disp('C_long ='); disp(C_long);
    fprintf('size(D_long) = [%d %d]\n', size(D_long)); disp('D_long ='); disp(D_long);
    fprintf('--- Autovalori di A_long ---\n'); disp(ev);
    
    % Info di ritorno per debug o log
    info.linsys = linsys;
    info.A_full = A_full; info.B_full = B_full;
    info.C_full = C_full; info.D_full = D_full;
    info.ix = ix; info.iu = iu; info.iy = iy;
    info.eigA = ev;
    
    % Assegna nel workspace base per retrocompatibilità e uso interattivo
    assignin('base','A_long',A_long);
    assignin('base','B_long',B_long);
    assignin('base','C_long',C_long);
    assignin('base','D_long',D_long);
    assignin('base','ABCD_info',info);
end
