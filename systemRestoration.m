function result = systemRestoration(receiverSubstation, receiverLateral, restorationResponse, faultType, cfg)
% systemRestoration
% Sends a restoration command and receives a confirmation/control-update
% request from the receiver substation.

    if nargin < 2 || isempty(receiverLateral)
        receiverLateral = 0;
    end

    if nargin < 3 || isempty(restorationResponse)
        restorationResponse = 1;
    end

    if nargin < 4 || isempty(faultType)
        faultType = 1;
    end

    if nargin < 5 || isempty(cfg)
        cfg = struct();
    end

    validateattributes(receiverSubstation, {'numeric'}, {'scalar','integer','nonnegative'}, mfilename, 'receiverSubstation');
    validateattributes(receiverLateral, {'numeric'}, {'scalar','integer','nonnegative'}, mfilename, 'receiverLateral');
    validateattributes(restorationResponse, {'numeric'}, {'scalar','integer','>=',0,'<=',1}, mfilename, 'restorationResponse');
    validateattributes(faultType, {'numeric'}, {'scalar','integer','>=',0,'<=',1}, mfilename, 'faultType');

    rowStep = {};
    rowDirection = {};
    rowSubstation = {};
    rowLateral = {};
    rowMeaning = {};
    rowRegisterSignal = {};
    rowSignalDirection = {};

    r = 0;

    % Step 1: restoration command from CC to receiver substation
    direction = 0;     % downstream
    data = 1;          % restoration command: close/reconnect
    [sig, dec] = optimalRegisterSignalProcessing('restoration', receiverSubstation, receiverLateral, direction, data, faultType, cfg);

    r = r + 1;
    rowStep{r,1} = 1;
    rowDirection{r,1} = 'CC_to_Receiver_SS';
    rowSubstation{r,1} = receiverSubstation;
    rowLateral{r,1} = receiverLateral;
    rowMeaning{r,1} = 'Restoration_Command_Close';
    rowRegisterSignal{r,1} = sig;
    rowSignalDirection{r,1} = dec.DirectionName;

    % Step 2: confirmation message and request for control update to CC
    direction = 1;     % upstream
    data = restorationResponse;
    [sig, dec] = optimalRegisterSignalProcessing('restoration', receiverSubstation, receiverLateral, direction, data, faultType, cfg);

    r = r + 1;
    rowStep{r,1} = 2;
    rowDirection{r,1} = 'Receiver_SS_to_CC';
    rowSubstation{r,1} = receiverSubstation;
    rowLateral{r,1} = receiverLateral;
    rowMeaning{r,1} = 'Confirmation_and_Control_Update_Request';
    rowRegisterSignal{r,1} = sig;
    rowSignalDirection{r,1} = dec.DirectionName;

    signals = table(rowStep, rowDirection, rowSubstation, rowLateral, rowMeaning, rowRegisterSignal, rowSignalDirection, ...
        'VariableNames', {'Step','Direction','Substation','Lateral','Meaning','RegisterSignal','SignalDirection'});

    result = struct();
    result.Stage = 'system restoration';
    result.Signals = signals;
    result.Restored = logical(restorationResponse);

    if result.Restored
        result.Message = 'Service restoration is confirmed and the control center should update the control configuration.';
    else
        result.Message = 'Restoration is not confirmed. Manual or secondary restoration logic is required.';
    end
end
