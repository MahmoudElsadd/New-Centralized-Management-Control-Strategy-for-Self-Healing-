function [registerSignal, decodedSignal, cfg] = optimalRegisterSignalProcessing(stage, nsub, nlateral, direction, ndata, ntype, cfg)
% optimalRegisterSignalProcessing
% -------------------------------------------------------------------------
% Generates the optimal binary register used by the proposed centralized
% control strategy for fault management in distribution systems.
%
% Register format:
%   [ nstage | nsub | nlateral | ndirection | ndata | ntype ]
%
% Stage coding:
%   0 or 'initialization'   -> 00
%   1 or 'identification'   -> 01
%   2 or 'isolation'        -> 10
%   3 or 'restoration'      -> 11
%
% Direction coding:
%   0 -> downstream
%   1 -> upstream
%
% Notes:
%   - Communication hops are not included in this register.
%   - ndata is a single-bit field whose meaning changes according to stage.

    if nargin < 7 || isempty(cfg)
        cfg = struct();
    end

    validateattributes(nsub, {'numeric'}, {'scalar','integer','nonnegative'}, mfilename, 'nsub');
    validateattributes(nlateral, {'numeric'}, {'scalar','integer','nonnegative'}, mfilename, 'nlateral');
    validateattributes(direction, {'numeric'}, {'scalar','integer','>=',0,'<=',1}, mfilename, 'direction');
    validateattributes(ndata, {'numeric'}, {'scalar','integer','>=',0,'<=',1}, mfilename, 'ndata');
    validateattributes(ntype, {'numeric'}, {'scalar','integer','>=',0,'<=',1}, mfilename, 'ntype');

    cfg = localDefaultConfig(cfg);
    nstageValue = localStageToValue(stage);

    % Minimum register widths based on the proposed methodology
    bitsStage     = 2;
    bitsSub       = max(1, ceil(log2(cfg.NumSecondarySubstations + 1)));
    bitsLateral   = max(1, ceil(log2(cfg.MaxLateralsPerSubstation)));
    bitsDirection = 1;
    bitsData      = 1;
    bitsType      = 1;

    if nsub > (2^bitsSub - 1)
        error('nsub=%d cannot be represented using %d bits.', nsub, bitsSub);
    end

    if nlateral > (2^bitsLateral - 1)
        error('nlateral=%d cannot be represented using %d bits.', nlateral, bitsLateral);
    end

    codeStage     = dec2bin(nstageValue, bitsStage);
    codeSub       = dec2bin(nsub, bitsSub);
    codeLateral   = dec2bin(nlateral, bitsLateral);
    codeDirection = dec2bin(direction, bitsDirection);
    codeData      = dec2bin(ndata, bitsData);
    codeType      = dec2bin(ntype, bitsType);

    registerSignal = [codeStage codeSub codeLateral codeDirection codeData codeType];

    decodedSignal = struct();
    decodedSignal.RegisterSignal = registerSignal;
    decodedSignal.StageValue = nstageValue;
    decodedSignal.StageName = localStageName(nstageValue);
    decodedSignal.Substation = nsub;
    decodedSignal.Lateral = nlateral;
    decodedSignal.Direction = direction;
    decodedSignal.DirectionName = localDirectionName(direction);
    decodedSignal.Data = ndata;
    decodedSignal.Type = ntype;
    decodedSignal.TypeName = localTypeName(ntype);

    decodedSignal.BitWidths = struct();
    decodedSignal.BitWidths.nstage = bitsStage;
    decodedSignal.BitWidths.nsub = bitsSub;
    decodedSignal.BitWidths.nlateral = bitsLateral;
    decodedSignal.BitWidths.ndirection = bitsDirection;
    decodedSignal.BitWidths.ndata = bitsData;
    decodedSignal.BitWidths.ntype = bitsType;
end

% -------------------------------------------------------------------------
function cfg = localDefaultConfig(cfg)
    if ~isfield(cfg, 'NumSecondarySubstations')
        cfg.NumSecondarySubstations = 40;
    end

    if ~isfield(cfg, 'MaxLateralsPerSubstation')
        cfg.MaxLateralsPerSubstation = 4;
    end
end

% -------------------------------------------------------------------------
function value = localStageToValue(stage)
    if ischar(stage)
        stage = lower(strtrim(stage));
        switch stage
            case {'initialization','init'}
                value = 0;
            case {'identification','faulted section identification','fault identification'}
                value = 1;
            case {'isolation','faulted section isolation','fault isolation'}
                value = 2;
            case {'restoration','system restoration'}
                value = 3;
            otherwise
                error('Unknown stage name: %s', stage);
        end
    else
        value = stage;
    end

    if ~ismember(value, 0:3)
        error('stage must be 0, 1, 2, 3 or a valid stage name.');
    end
end

% -------------------------------------------------------------------------
function name = localStageName(value)
    names = {'initialization','identification','isolation','restoration'};
    name = names{value + 1};
end

% -------------------------------------------------------------------------
function name = localDirectionName(value)
    if value == 0
        name = 'downstream';
    else
        name = 'upstream';
    end
end

% -------------------------------------------------------------------------
function name = localTypeName(value)
    if value == 0
        name = 'temporary fault';
    else
        name = 'permanent fault';
    end
end
