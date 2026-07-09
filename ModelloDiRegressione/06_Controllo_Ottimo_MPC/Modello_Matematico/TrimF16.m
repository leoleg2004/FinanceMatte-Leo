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

%script usato utilizzando lo particle swarm optimization e impostando i
%vincoli di volo di crociera dell'aereo in volo di crociera
%% Specifiche del modello F16
model = 'F16';
opspec = operspec(model);

Vt0 = 91.4400;
ft2m = 0.3048;
d2r = pi/180;
r2d = 180/pi;
lbf2N = 4.44822;

control.lb = [1000*lbf2N -25*d2r -21.5*d2r -30*d2r 0];
control.ub = [19000*lbf2N 25*d2r  21.5*d2r  30*d2r 25*d2r];

%% STATI (Beccheggio, u, w SBLOCCATI)
opspec.States(1).Known = [true; false; true]; % Theta libero di cabrare
opspec.States(2).Known = true;
opspec.States(3).Known = true;
opspec.States(4).Known = true;
opspec.States(5).Known = false; % u libera
opspec.States(6).Known = true;
opspec.States(7).Known = false; % w libera
opspec.States(8).Known = true; opspec.States(8).SteadyState = false;
opspec.States(9).Known = true; opspec.States(9).SteadyState = false;
opspec.States(10).Known = true;

%% INPUT
opspec.Inputs(1).Known = false; opspec.Inputs(1).Min = control.lb(1); opspec.Inputs(1).Max = control.ub(1);
opspec.Inputs(2).Known = false; opspec.Inputs(2).Min = control.lb(2); opspec.Inputs(2).Max = control.ub(2);
opspec.Inputs(3).Known = true;  opspec.Inputs(3).u = 0;
opspec.Inputs(4).Known = true;  opspec.Inputs(4).u = 0;
opspec.Inputs(5).Known = false; opspec.Inputs(5).Min = control.lb(5); opspec.Inputs(5).Max = control.ub(5);
opspec.Inputs(6).Known = [true;true;true]; opspec.Inputs(6).u = [0;0;0];

%% OUTPUT
opspec.Outputs(3).y = Vt0; opspec.Outputs(3).Known = true;
opspec.Outputs(4).Known = false; opspec.Outputs(4).y = 0; opspec.Outputs(4).Min = -20*d2r; opspec.Outputs(4).Max = 45*d2r;
opspec.Outputs(5).Known = true; opspec.Outputs(5).y = 0;
opspec.Outputs(6).Known = [true;false;true]; opspec.Outputs(6).y = [0;0;0];
opspec.Outputs(7).Known = true; opspec.Outputs(7).y = 0;
opspec.Outputs(8).Known = [true;true;true]; opspec.Outputs(8).y = [0;0;0];
opspec.Outputs(9).Known = [true;true;true]; opspec.Outputs(9).y = [0;0;0];
opspec.Outputs(10).Known = [true;true;true]; opspec.Outputs(10).y = [0;0;0];

%% =======================================================================
%% ESECUZIONE CON PARTICLE SWARM (4 Gradi di Libertà)
%% =======================================================================
% Prepariamo un'opzione di valutazione silenziosa nel Workspace principale
opt_eval = findopOptions('DisplayReport','off');
opt_eval.OptimizationOptions.MaxIter = 0;

% Limiti per Thrust, Elevator, LEF e THETA (da -5 a +25 gradi)
lb_pso = [control.lb(1), control.lb(2), control.lb(5), -5*d2r];
ub_pso = [control.ub(1), control.ub(2), control.ub(5),  25*d2r];

disp('--- Avvio Ottimizzazione Stocastica a 4 GRADI DI LIBERTÀ ---');
disp('Le particelle stanno cercando l''assetto perfetto...');

pso_opt = optimoptions('particleswarm', 'SwarmSize', 30, 'MaxIterations', 20, 'Display', 'iter');

% Lanciamo lo sciame (nota il 4 invece del 3)
[best_u, best_cost] = particleswarm(@(u_try) costo_stocastico(u_try, model), 4, lb_pso, ub_pso, pso_opt);

disp('--- Ricerca Terminata! Generazione del Report Finale... ---');

% Applichiamo i risultati vincenti all'aereo
opspec.Inputs(1).u = best_u(1);
opspec.Inputs(2).u = best_u(2);
opspec.Inputs(5).u = best_u(3);

% Applichiamo l'assetto vincente per theta, u e w
best_theta = best_u(4);
opspec.States(1).x = [0; best_theta; 0];
opspec.States(5).x = Vt0 * cos(best_theta);
opspec.States(7).x = Vt0 * sin(best_theta);

% Stampiamo il report finale
opt_final = findopOptions('DisplayReport', 'iter');
opt_final.OptimizationOptions.MaxIter = 0; % Stampiamo e basta, i dx saranno azzerati dal PSO
[op, opreport] = findop(model, opspec, opt_final);

%% =======================================================================
%% FUNZIONE DI COSTO (Cinematica integrata)
%% =======================================================================
function J = costo_stocastico(u_try, model)
    % 1. Inviamo i tentativi della particella al Workspace principale
    assignin('base', 'u_try_pso', double(u_try));
    
    % 2. Scriviamo i comandi (Includiamo Theta, u, w)
    cmd = [ ...
        'opspec.Inputs(1).u = u_try_pso(1); ', ...
        'opspec.Inputs(2).u = u_try_pso(2); ', ...
        'opspec.Inputs(5).u = u_try_pso(3); ', ...
        'theta_try = u_try_pso(4); ', ...
        'opspec.States(1).x = [0; theta_try; 0]; ', ...
        'opspec.States(5).x = Vt0 * cos(theta_try); ', ...
        'opspec.States(7).x = Vt0 * sin(theta_try); ', ...
        '[~, pso_report] = findop(''', model, ''', opspec, opt_eval);' ...
    ];
    
    % 3. Eseguiamo il test in modo blindato
    try
        evalin('base', cmd);
        % Recuperiamo il report
        report = evalin('base', 'pso_report');
        
        % Calcoliamo l'errore
        J = 0;
        for i = 1:length(report.States)
            if report.States(i).SteadyState
                J = J + sum(report.States(i).dx.^2);
            end
        end
    catch
        % Se i parametri sono fisicamente impossibili, diamo una penalità
        J = 1e6; 
    end
end