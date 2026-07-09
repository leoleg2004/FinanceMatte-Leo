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

% =========================================================================
% Model of the F-16 Aircraft model.
%
% References:
%    NASA Technical Report 1538, Simulator Study of Stall/Post-Stall Characteristics of a Fighter Airplane with Relaxed Longitudinal Static Stability, 
%    by Nguyen, Ogburn, Gilbert, Kibler, Brown, and Deal, Dec 1979. 
% 
%    The model is based on Aircraft Control and Simulations, by Brian Stevens and Frank Lewis, Wiley Inter-Science, New York, 1992.
%
% All units in this model are in SI SYSTEM.
% 
% Model developed by
% Raktim Bhattacharya, 
% Professor
% Aerospace Engineering,
% Texas A&M University.
%
% =========================================================================
% ============================= Model Details =============================
% The 12 states of the system are as follows:
% 
% N: North position in ft
% E: East position in ft
% h: Altitude in ft, min: 5000 ft, max: 40000 ft
% phi: Roll angle in rad
% theta: Pitch angle in rad
% psi: Yaw angle in rad
% Vt: Magnitude of total velocity in ft/s, min: 300 ft/s, max: 900 ft/s
% alpha: Angle of attack in rad, min: -20 deg, max: 45 deg
% beta: Side slip angle in rad, min: -30 deg, max: 30 deg
% p: Roll rate in rad/s
% q: Pitch rate in rad/s
% r: Yaw rate in rad/s
% The 5 control variables are:
% 
% T: Thrust in lbf, min: 1000, max: 19000
% dele: Elevator angle in deg, min:-25, max: 25
% dail: Aileron angle in deg, min:-21.5, max: 21.5
% drud: Rudder angle in deg, min: -30, max: 30
% dlef: Leading edge flap in deg, min: 0, max: 25
% Actuator models are defined as:
%
% T: max |rate|: 10,000 lbs/s
% dele: max |rate|: 60 deg/s
% dail: max |rate|: 80 deg/s
% drud: max |rate|: 120 deg/s
% dlef: max |rate|: 25 deg/s
% =========================================================================
clear;
conversion % loads conversion constants. see conversion.m for defintions.
Param = load_F16_params(); % System Parameters

% Simulate with Arbitrary Initial Conditions
% ==========================================
h0 = -10000*ft2m; % 10 ft altitude
Vt0 = 300*ft2m;

% Need to specify IC to initialize simulink.
IC.inertial_position = [0,0,h0]; % At 10 Km altitude.
IC.body_velocity = [Vt0,0,0];    % We may need to get this from Mach, alpha, beta
IC.euler_angles = [0,0,0]*d2r;  % Euler angles
IC.omega = [0,0,0] ;            % Angular velocity in body coordinate system
Tend = 2.0; % Simulation time in seconds.

% Trim F16.
TrimF16; % Creates op, opreport
linsys = linearize('F16',op); % Linearize about operating point op.
 
% Estrai e stampa le sottomatrici longitudinali passando linsys (Eseguito 1 sola volta)
[A_long,B_long,C_long,D_long,info] = extract_and_print_ABCD(linsys);

% Indices for states, inputs, and outputs for longitudinal model.
% States are:
ix = [2,5,7,9]; % th, U, w, q
iu = [1,2,5,6,8]; % T, dele, lef, dx, dz (last two are dist in longi plane)
iy = [7,8,13,15,17,19]; % Vt, alp, q, xbdd, zbdd
A = linsys.A(ix,ix);
eig(A) % Check eigen values and determine properties of Phugoid/SP modes

% =========================================================================
% FUNZIONE MODIFICATA (Riceve linsys ed estrae/stampa le matrici)
% =========================================================================
function [A,B,C,D,info] = extract_and_print_ABCD(linsys)
    % se linsys è array LTI prendi primo elemento
    if numel(linsys) > 1
        linsys = linsys(:,:,1);
    end
    
    % estrai matrici complete
    [A_full,B_full,C_full,D_full] = ssdata(linsys);
    
    % indici longitudinali
    ix = [2,5,7,9]; % teta,q,U=vt*cos(alfa),W=vt*sin(alfa)
    iu = [1,2,5,6,8]; % spinta,equilibratore,flap,raffiche(assex),raffiche(z)
    iy = [7,8,13,15,17,19]; % vt,alfa,q,xbdd,zbdd
    
    % verifica dimensioni
    if max(ix) > size(A_full,1) || max(ix) > size(A_full,2)
        error('Indici ix non compatibili con size(A_full) = [%d %d]', size(A_full));
    end
    if max(iu) > size(B_full,2)
        error('Indici iu non compatibili con size(B_full) = [%d %d]', size(B_full));
    end
    if max(iy) > size(C_full,1)
        error('Indici iy non compatibili con size(C_full) = [%d %d]', size(C_full));
    end
    
    % estrai sottomatrici
    A = A_full(ix, ix);
    B = B_full(ix, iu);
    C = C_full(iy, ix);
    D = D_full(iy, iu);
    
    % autovalori
    ev = eig(A);
    
    % stampa
    fprintf('--- Matrici sottomatrici longitudinali ---\n');
    fprintf('size(A) = [%d %d]\n', size(A)); disp('A ='); disp(A);
    fprintf('size(B) = [%d %d]\n', size(B)); disp('B ='); disp(B);
    fprintf('size(C) = [%d %d]\n', size(C)); disp('C ='); disp(C);
    fprintf('size(D) = [%d %d]\n', size(D)); disp('D ='); disp(D);
    fprintf('--- Autovalori di A ---\n'); disp(ev);
    
    % nomi di stati/ingressi/uscite (se presenti)
    try
        if isprop(linsys,'StateName'), disp('StateName(ix):'), disp(linsys.StateName(ix)); end
        if isprop(linsys,'InputName'), disp('InputName(iu):'), disp(linsys.InputName(iu)); end
        if isprop(linsys,'OutputName'), disp('OutputName(iy):'), disp(linsys.OutputName(iy)); end
    catch
    end
    
    % info di ritorno
    info.linsys = linsys;
    info.A_full = A_full; info.B_full = B_full;
    info.C_full = C_full; info.D_full = D_full;
    info.ix = ix; info.iu = iu; info.iy = iy;
    info.eigA = ev;
    
    % assegna nel workspace base per accesso interattivo
    assignin('base','A_long',A);
    assignin('base','B_long',B);
    assignin('base','C_long',C);
    assignin('base','D_long',D);
    assignin('base','ABCD_info',info);
end