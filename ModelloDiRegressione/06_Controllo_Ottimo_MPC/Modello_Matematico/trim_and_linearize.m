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
 
% Estrai e filtra le sottomatrici longitudinali delegando alla funzione apposita
disp('Filtraggio delle matrici full per estrarre il modello longitudinale...');
[A_long, B_long, C_long, D_long, info] = filtra_matrici_longitudinali(linsys);