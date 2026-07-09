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

% ==========================
% Developed by
% Raktim Bhattacharya, 
% Professor
% Aerospace Engineering,
% Texas A&M University.
% ==========================


function plot_trajectories(simOut)
r2d = 180/pi;
set(0, 'DefaultLineLineWidth', 1);

% --- GESTIONE COMPATIBILITA' VERSIONI MATLAB ---
if isa(simOut.yout, 'Simulink.SimulationData.Dataset')
    % Formato Dataset (default nelle nuove versioni di MATLAB)
    yout_temp = [];
    for i = 1:simOut.yout.numElements
        yout_temp = horzcat(yout_temp, simOut.yout{i}.Values.Data);
    end
    yout = yout_temp;
elseif isstruct(simOut.yout) && isfield(simOut.yout, 'signals')
    % Formato Structure with time (vecchie versioni)
    yout = horzcat(simOut.yout.signals.values);
elseif isnumeric(simOut.yout)
    % Formato Array
    yout = simOut.yout;
else
    % Fallback
    yout = simOut.yout;
end
tout = simOut.tout;
% -----------------------------------------------

figure(1); clf;
% Plot position in inertial
subplot(4,3,1); plot(tout,yout(:,1)); title('$X$ Inertial Position (m)', 'interpreter', 'latex'); xlabel('Time (s)');
subplot(4,3,2); plot(tout,yout(:,2)); title('$Y$ Inertial Position (m)', 'interpreter', 'latex'); xlabel('Time (s)');
subplot(4,3,3); plot(tout,yout(:,3)); title('$Z$ Inertial Position (m)', 'interpreter', 'latex'); xlabel('Time (s)');
set(gca,'YDir','reverse');

% Plot velocity in inertial
subplot(4,3,4); plot(tout,yout(:,4)); title('Inertial Velocity $\dot{X}$ (m)', 'interpreter','latex'); xlabel('Time (s)');
subplot(4,3,5); plot(tout,yout(:,5)); title('Ineritial Velocity $\dot{Y}$ (m)', 'interpreter','latex'); xlabel('Time (s)');
subplot(4,3,6); plot(tout,yout(:,6)); title('Inertial Velocity $\dot{Z}$ (m)', 'interpreter','latex'); xlabel('Time (s)');

% Plot total velocity, angle of attack, and side slip angle
subplot(4,3,7); plot(tout,yout(:,7)); title('Total Velocity $V_t$ (m/s)', 'interpreter','latex'); xlabel('Time (s)');
subplot(4,3,8); plot(tout,yout(:,8)*r2d); title('Angle of Attack $\alpha$ (deg)', 'interpreter','latex'); xlabel('Time (s)');
subplot(4,3,9); plot(tout,yout(:,9)*r2d); title('Side-slip Angle $\beta$ (deg)', 'interpreter','latex'); xlabel('Time (s)');

% Plot body acceleration
subplot(4,3,10); plot(tout,yout(:,17)); title('Body Accleration $\ddot{x}_b$  (m/s$^2$)', 'interpreter','latex'); xlabel('Time (s)');
subplot(4,3,11); plot(tout,yout(:,18)); title('Body Accleration $\ddot{y}_b$  (m/s$^2$)', 'interpreter','latex'); xlabel('Time (s)');
subplot(4,3,12); plot(tout,yout(:,19)); title('Body Accleration $\ddot{z}_b$  (m/s$^2$)', 'interpreter','latex'); xlabel('Time (s)');


figure(2); clf;
% Plot Euler angels
subplot(4,3,1); plot(tout,yout(:,10)*r2d); title('Roll Angle $\phi$ (deg)', 'interpreter', 'latex'); xlabel('Time (s)');
subplot(4,3,2); plot(tout,yout(:,11)*r2d); title('Pitch Angle $\theta$ (deg)', 'interpreter', 'latex'); xlabel('Time (s)');
subplot(4,3,3); plot(tout,yout(:,12)*r2d); title('Yaw Angle $\psi$ (deg)', 'interpreter', 'latex'); xlabel('Time (s)');

% Plot angular velocity
subplot(4,3,4); plot(tout,yout(:,14)*r2d); title('Roll Rate $p$ (deg/s)', 'interpreter','latex'); xlabel('Time (s)');
subplot(4,3,5); plot(tout,yout(:,15)*r2d); title('Pitch Rate $q$ (deg/s)', 'interpreter','latex'); xlabel('Time (s)');
subplot(4,3,6); plot(tout,yout(:,16)*r2d); title('Yaw Rate $r$ (deg/s)', 'interpreter','latex'); xlabel('Time (s)');

% Plot angular acceleration
subplot(4,3,7); plot(tout,yout(:,20)*r2d); title('Roll Acceleration $\dot{p}$ (deg/s)', 'interpreter','latex'); xlabel('Time (s)');
subplot(4,3,8); plot(tout,yout(:,21)*r2d); title('Pitch Acceleration $\dot{q}$ (deg/s)', 'interpreter','latex'); xlabel('Time (s)');
subplot(4,3,9); plot(tout,yout(:,22)*r2d); title('Yaw Acceleration $\dot{r}$ (deg/s)', 'interpreter','latex'); xlabel('Time (s)');


% Plot Mach and flight path angle
subplot(4,3,10); plot(tout,yout(:,23)); title('Mach Number $M$', 'interpreter','latex'); xlabel('Time (s)');
subplot(4,3,11); plot(tout,yout(:,13)*r2d); title('Flight Path Angle $\gamma$ (deg)', 'interpreter','latex'); xlabel('Time (s)');
%subplot(4,3,9); plot(tout,yout{5}*r2d); title('Side-slip Angle $\beta$ (deg)', 'interpreter','latex'); xlabel('Time (s)');

end