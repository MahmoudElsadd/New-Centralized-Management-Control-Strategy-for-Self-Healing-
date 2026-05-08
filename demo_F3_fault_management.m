% F3_fault_management
% -------------------------------------------------------------------------
% Example matching permanent F3:
% Fault is between SS 15 and SS 16.
% SS 15 detects the fault through lateral 01.
% SS 16 does not detect the fault; lateral 00 is closest to the upstream fault.
% Communication hops are not included in the program/register.

clc;
clear;

cfg.NumSecondarySubstations = 46;
cfg.MaxLateralsPerSubstation = 4; % at busbar 15

% 1) Faulted section identification
pathSubstations = [15 16];
faultIndicatorStatus = [1 0];   % scalar per substation, not FI array
lateralCode = [1 0];            % nlateral identifies the branch
faultType = 1;                  % 1 = permanent fault

idResult = faultedSectionIdentification(pathSubstations, faultIndicatorStatus, lateralCode, faultType, cfg);
disp('Identification signals:');
disp(idResult.Signals);
disp(idResult);

% 2) Faulted section isolation
sectionalizerResponse = [1 1];  % both sectionalizers opened successfully
isoResult = faultedSectionIsolation(idResult, sectionalizerResponse, cfg);
disp('Isolation signals:');
disp(isoResult.Signals);
disp(isoResult);

% 3) System restoration
receiverSubstation = 14;        % recloser substation
receiverLateral = 0;
restorationResponse = 1;        % recloser closed successfully

rstResult = systemRestoration(receiverSubstation, receiverLateral, restorationResponse, faultType, cfg);
disp('Restoration signals:');
disp(rstResult.Signals);
disp(rstResult);
