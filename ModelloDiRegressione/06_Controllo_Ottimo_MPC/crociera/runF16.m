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

clc; clear;

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
t0 = 0;

x0 = [IC.inertial_position, IC.euler_angles, IC.body_velocity, IC.omega];
u0 = [9000*lbf2N,0,0,0,0,0,0];

% [sys,x01,str,ts] = F16([],[],[],'compile'); % Uses x0 as initial condition. x01 and x0 should be the same.
% y0 = F16(t0, x0, u0, 'outputs'); % Need this to update the dynamics with current state values
% xdot = F16(t0,x0,u0,'derivs');
% F16([],[],[],'term');
% disp(xdot)

Tend = 5;
simout = sim('F16_2023a.mdl');
plot_trajectories(simout);
