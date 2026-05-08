function result = faultedSectionIsolation(identificationResult, sectionalizerResponse, cfg)
% faultedSectionIsolation
% Opens the sectionalizer closest to the fault from the upstream side and
% the sectionalizer closest to the fault from the downstream side.

    if nargin < 2 || isempty(sectionalizerResponse)
        sectionalizerResponse = [1 1];
    end

    if nargin < 3 || isempty(cfg)
        cfg = struct();
    end

    validateattributes(sectionalizerResponse, {'numeric'}, {'row','numel',2,'integer','>=',0,'<=',1}, mfilename, 'sectionalizerResponse');

    if ~isfield(identificationResult, 'FaultType') || identificationResult.FaultType ~= 1
        result = struct();
        result.Stage = 'faulted section isolation';
        result.Signals = table();
        result.Isolated = false;
        result.NextStage = 'terminate';
        result.Message = 'Temporary fault: isolation is not required.';
        return;
    end

    if isempty(identificationResult.FaultedSection)
        error('Cannot isolate because the faulted section is not identified.');
    end

    upSS  = identificationResult.Upstream.Substation;
    upLat = identificationResult.Upstream.Lateral;
    dnSS  = identificationResult.Downstream.Substation;
    dnLat = identificationResult.Downstream.Lateral;
    faultType = identificationResult.FaultType;

    rowStep = {};
    rowDirection = {};
    rowSubstation = {};
    rowLateral = {};
    rowMeaning = {};
    rowRegisterSignal = {};
    rowSignalDirection = {};

    r = 0;

    % Step 1: downstream isolation command to upstream-side substation
    direction = 0;
    data = 1; % isolation command: open sectionalizer
    [sig, dec] = optimalRegisterSignalProcessing('isolation', upSS, upLat, direction, data, faultType, cfg);

    r = r + 1;
    rowStep{r,1} = 1;
    rowDirection{r,1} = 'CC_to_Upstream_SS';
    rowSubstation{r,1} = upSS;
    rowLateral{r,1} = upLat;
    rowMeaning{r,1} = 'Open_Upstream_Sectionalizer';
    rowRegisterSignal{r,1} = sig;
    rowSignalDirection{r,1} = dec.DirectionName;

    % Step 2: upstream response from upstream-side substation
    direction = 1;
    data = sectionalizerResponse(1);
    [sig, dec] = optimalRegisterSignalProcessing('isolation', upSS, upLat, direction, data, faultType, cfg);

    r = r + 1;
    rowStep{r,1} = 2;
    rowDirection{r,1} = 'Upstream_SS_to_CC';
    rowSubstation{r,1} = upSS;
    rowLateral{r,1} = upLat;
    rowMeaning{r,1} = 'Upstream_Sectionalizer_Response';
    rowRegisterSignal{r,1} = sig;
    rowSignalDirection{r,1} = dec.DirectionName;

    % Step 3: downstream isolation command to downstream-side substation
    direction = 0;
    data = 1;
    [sig, dec] = optimalRegisterSignalProcessing('isolation', dnSS, dnLat, direction, data, faultType, cfg);

    r = r + 1;
    rowStep{r,1} = 3;
    rowDirection{r,1} = 'CC_to_Downstream_SS';
    rowSubstation{r,1} = dnSS;
    rowLateral{r,1} = dnLat;
    rowMeaning{r,1} = 'Open_Downstream_Sectionalizer';
    rowRegisterSignal{r,1} = sig;
    rowSignalDirection{r,1} = dec.DirectionName;

    % Step 4: upstream response from downstream-side substation
    direction = 1;
    data = sectionalizerResponse(2);
    [sig, dec] = optimalRegisterSignalProcessing('isolation', dnSS, dnLat, direction, data, faultType, cfg);

    r = r + 1;
    rowStep{r,1} = 4;
    rowDirection{r,1} = 'Downstream_SS_to_CC';
    rowSubstation{r,1} = dnSS;
    rowLateral{r,1} = dnLat;
    rowMeaning{r,1} = 'Downstream_Sectionalizer_Response';
    rowRegisterSignal{r,1} = sig;
    rowSignalDirection{r,1} = dec.DirectionName;

    signals = table(rowStep, rowDirection, rowSubstation, rowLateral, rowMeaning, rowRegisterSignal, rowSignalDirection, ...
        'VariableNames', {'Step','Direction','Substation','Lateral','Meaning','RegisterSignal','SignalDirection'});

    isolated = all(sectionalizerResponse == 1);

    result = struct();
    result.Stage = 'faulted section isolation';
    result.Signals = signals;
    result.UpstreamIsolatedAt = struct('Substation', upSS, 'Lateral', upLat);
    result.DownstreamIsolatedAt = struct('Substation', dnSS, 'Lateral', dnLat);
    result.Isolated = isolated;

    if isolated
        result.NextStage = 'system restoration';
        result.Message = 'The permanent faulted section is isolated from both sides.';
    else
        result.NextStage = 'manual intervention';
        result.Message = 'Isolation was not fully confirmed. Manual check is required.';
    end
end
