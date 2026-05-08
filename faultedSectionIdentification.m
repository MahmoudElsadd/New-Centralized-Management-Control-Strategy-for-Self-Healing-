function result = faultedSectionIdentification(pathSubstations, faultIndicatorStatus, lateralCode, faultType, cfg)
% faultedSectionIdentification
% -------------------------------------------------------------------------
% Centralized-control faulted section identification algorithm.
%
% FaultIndicatorStatus is treated as one scalar value per substation,
% The actual lateral/branch is identified using % nlateral.
%
% Inputs:
%   pathSubstations       : ordered substations along suspected feeder path
%   faultIndicatorStatus  : scalar status for each substation
%                           1 = detects fault, 0 = does not detect fault
%   lateralCode           : nlateral code for each substation
%   faultType             : 1 permanent, 0 temporary
%   cfg                   : register configuration structure

    if nargin < 5 || isempty(cfg)
        cfg = struct();
    end

    validateattributes(pathSubstations, {'numeric'}, {'row','integer','nonnegative'}, mfilename, 'pathSubstations');
    validateattributes(faultIndicatorStatus, {'numeric'}, {'row','integer','>=',0,'<=',1}, mfilename, 'faultIndicatorStatus');
    validateattributes(lateralCode, {'numeric'}, {'row','integer','nonnegative'}, mfilename, 'lateralCode');
    validateattributes(faultType, {'numeric'}, {'scalar','integer','>=',0,'<=',1}, mfilename, 'faultType');

    n = numel(pathSubstations);

    if numel(faultIndicatorStatus) ~= n || numel(lateralCode) ~= n
        error('pathSubstations, faultIndicatorStatus, and lateralCode must have the same length.');
    end

    rowStep = {};
    rowDirection = {};
    rowSubstation = {};
    rowLateral = {};
    rowMeaning = {};
    rowRegisterSignal = {};
    rowSignalDirection = {};

    faultedSection = [];
    upstream = struct();
    downstream = struct();

    r = 0;

    for k = 1:n
        ss = pathSubstations(k);
        lat = lateralCode(k);

        % Step 1: CC sends downstream request for fault-indicator status
        direction = 0;       % downstream
        data = 1;            % request FI status
        [sig, dec] = optimalRegisterSignalProcessing('identification', ss, lat, direction, data, faultType, cfg);

        r = r + 1;
        rowStep{r,1} = k;
        rowDirection{r,1} = 'CC_to_SS';
        rowSubstation{r,1} = ss;
        rowLateral{r,1} = lat;
        rowMeaning{r,1} = 'Request_FI_Status';
        rowRegisterSignal{r,1} = sig;
        rowSignalDirection{r,1} = dec.DirectionName;

        % Step 2: SS responds upstream using scalar FI status
        direction = 1;       % upstream
        data = faultIndicatorStatus(k);
        [sig, dec] = optimalRegisterSignalProcessing('identification', ss, lat, direction, data, faultType, cfg);

        r = r + 1;
        rowStep{r,1} = k;
        rowDirection{r,1} = 'SS_to_CC';
        rowSubstation{r,1} = ss;
        rowLateral{r,1} = lat;
        rowMeaning{r,1} = 'FI_Status_Response';
        rowRegisterSignal{r,1} = sig;
        rowSignalDirection{r,1} = dec.DirectionName;

        % Fault-location rule:
        % The faulted section is between the last detecting substation and
        % the first non-detecting downstream substation.
        if k > 1 && faultIndicatorStatus(k-1) == 1 && faultIndicatorStatus(k) == 0
            faultedSection = [pathSubstations(k-1), pathSubstations(k)];

            upstream.Substation = pathSubstations(k-1);
            upstream.Lateral = lateralCode(k-1);
            upstream.FaultIndicatorStatus = faultIndicatorStatus(k-1);

            downstream.Substation = pathSubstations(k);
            downstream.Lateral = lateralCode(k);
            downstream.FaultIndicatorStatus = faultIndicatorStatus(k);

            break;
        end
    end

    if isempty(faultedSection)
        if all(faultIndicatorStatus == 1)
            warning('All checked substations detect the fault. Extend the search path downstream.');
        elseif all(faultIndicatorStatus == 0)
            warning('No checked substation detects the fault. The fault may be upstream of the first checked substation.');
        else
            warning('Faulted section was not uniquely identified from the provided status sequence.');
        end
    end

    signals = table(rowStep, rowDirection, rowSubstation, rowLateral, rowMeaning, rowRegisterSignal, rowSignalDirection, ...
        'VariableNames', {'Step','Direction','Substation','Lateral','Meaning','RegisterSignal','SignalDirection'});

    result = struct();
    result.Stage = 'faulted section identification';
    result.Signals = signals;
    result.FaultedSection = faultedSection;
    result.Upstream = upstream;
    result.Downstream = downstream;
    result.FaultType = faultType;
    result.FaultTypeName = localTypeName(faultType);
end

% -------------------------------------------------------------------------
function name = localTypeName(value)
    if value == 0
        name = 'temporary fault';
    else
        name = 'permanent fault';
    end
end
