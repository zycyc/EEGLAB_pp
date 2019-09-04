function [includedElectrodes, excludedElectrodes] = removeElectrodes(task, sub, displayMsg, varargin)
% RR3 SUBJECTS WITH BAD ELECTRODES
% Created: 08/05/2015 By: Evan Layher
% Revised: 08/07/2015 By: Evan Layher
%
% Input:
% task = 'wm' (working memory) or 'ts' (temporal sequence)
% sub = 3 digit RR3 subject ID (as string)
% displayMsg = '0' (do not display message) '1' (display message
% varargin = Indices of all electrodes of interest
%
% Output:
% includedElectrodes = indices of all good electrodes
% excludedElectrodes = names of excluded electrode(s) or 'NaN'
%
% Instructions:
% In the 'subBadElecs[TS,WM]' cell arrays input a new cell array containing
% 3 digit RR3 subject ID (as a string) followed by the names of electrode(s)
% to remove e.g.: subBadElecsTS = { {'103' 'T7' 'P7'} {'204' 'CP4'} };

% TEMPORAL SEQUENCE TASK ('ts')
% subBadElecsTS = { {'102' 'T8'} {'103' 'T7' 'P7'} {'105' 'F8' 'FT8'} {'106' 'F5' 'FT8'} {'107' 'CP3'} {'113' 'CB2'} {'114' 'F7' 'FT7' 'FC5'} {'116' 'F5' 'FC1'} {'119' 'PO4'} {'122' 'CP4'} {'126' 'C5' 'C3' 'P4'} {'127' 'CP4'} {'129' 'PO4'} {'131' 'PO4'} {'132' 'CP4'} {'133' 'PO4'} {'133' 'CP4'} {'135' 'F3' 'C5' 'C1' 'P4' 'PO8' 'CB2'} {'136' 'PO4' 'AF4'} {'137' 'PO4'} {'139' 'CP4'} {'140' 'PO4'} {'141' 'FZ'} {'142' 'P5'} {'143' 'FZ'} {'147' 'FC2'} {'148' 'TP8'} {'152' 'TP8' 'FC6' 'FT8' 'AF4' 'F8' 'F2' 'F4' 'F6' 'FC6'} {'153' 'AF3' 'F5' 'FT7' 'T7'} {'155' 'FP2' 'AF4' 'FZ' 'F2'} {'157' 'FPZ' 'AF4' 'CPZ'} {'158' 'AF3'} {'204' 'CP4'} {'208' 'F7' 'F5' 'F6' 'FT7' 'FC5' 'FC3' 'CP5' 'CP3'} {'214' 'F3' 'PO4'} {'217' 'F5'} {'219' 'F7'} {'223' 'PO4'} {'228' 'F3' 'C1' 'CP5' 'CP1' 'P1' 'PO3' 'CP4' 'F7'} {'237' 'F1' 'FZ' 'F2' 'FC1' 'FCZ' 'FC2' 'C1' 'CZ' 'C2' 'CP1' 'CPZ' 'CP2' 'P1' 'PZ' 'P2' 'PO3' 'POZ' 'CB1' 'O1' 'OZ' 'O2' 'CB2'} {'307' 'F5' 'F7'} {'311' 'PO4'} {'312' 'CP4'} {'313' 'F8'} {'160' 'TP8'} {'161' 'AF4'} {'163' 'O1' 'FPZ' 'FZ'}  {'164' 'O1'} {'165' 'O1'} {'166' 'O1' 'P2' 'P4' 'FPZ'} {'168' 'O1' 'PZ'} {'169' 'O1'} {'170' 'O1' 'FZ'} {'171' 'TP7' 'P7' 'O1'} {'244' 'O1'} }% 208: random spikes throughout trials
% subBadElecsTS = { {'102' 'T8'} {'103' 'T7' 'P7'} {'105' 'F7' 'F8' 'FT8'} {'106' 'F7' 'FC6'} {'107' 'CP3'} {'108' 'T7' 'T8'} {'110' 'FC6'} {'112' 'FC4'} {'113' 'VEO' 'F6' 'F8'} {'114' 'F7' 'FT7' 'FC5'} {'116' 'F5' 'FC1'} {'117' 'T8'} {'118' 'P7'} {'119' 'PO4'} {'121' 'T8'} {'122' 'CP4'} {'124' 'CP4' 'T7'} {'126' 'C5' 'C3' 'P4'} {'128' 'CP4'} {'129' 'PO4'} {'131' 'PO4'} {'132' 'CP4' 'P8'} {'133' 'PO4'} {'134' 'CP4'} {'136' 'PO4' 'AF4' 'F6'} {'137' 'PO4'} {'139' 'CP4'} {'140' 'PO4'} {'141' 'FZ' 'P7'} {'143' 'FZ' 'F1' 'TP7'}  {'146' 'TP7' 'FT8' 'TP8'} {'147' 'FC2'} {'148' 'TP8'} {'149' 'TP8' 'C6' 'T7' 'C2'} {'157' 'FPZ' 'TP8' 'AF4' 'CPZ'} {'158' 'AF3'} {'159' 'O1'} {'160' 'TP8' 'T8'} {'161' 'AF4'} {'164' 'O1' 'F1' 'FPZ'} {'165' 'O1'} {'166' 'O1' 'TP8'} {'168' 'T8'} {'170' 'O1' 'FZ'} {'171' 'TP7' 'P7' 'TP8' 'O1' 'FZ'} {'204' 'CP4'} {'208' 'F7' 'F5' 'F6' 'FT7' 'FC5' 'FC3' 'CP5' 'CP3'} {'214' 'F3' 'PO4'} {'217' 'F5'} {'219' 'F7'} {'223' 'PO4'} {'228' 'F3' 'C1' 'CP5' 'CP1' 'P1' 'PO3' 'CP4' 'F7'} {'237' 'F1' 'FZ' 'F2' 'FC1' 'FCZ' 'FC2' 'C1' 'CZ' 'C2' 'CP1' 'CPZ' 'CP2' 'P1' 'PZ' 'P2' 'PO3' 'POZ' 'CB1' 'O1' 'OZ' 'O2' 'CB2'} {'244' 'O1'} {'307' 'F5' 'F7'} {'311' 'PO4'} {'312' 'CP4'} {'313' 'F8'} };% 208: random spikes throughout trials
subBadElecsTS = { {'102' 'T8'} {'103' 'T7' 'P7'} {'105' 'F7' 'F8' 'FT8'} {'106' 'F7' 'FC6'} {'107' 'CP3'} {'108' 'T7' 'T8'} {'110' 'FC6'} {'112' 'FC4'} {'113' 'VEO' 'F6' 'F8'} {'114' 'F7' 'FT7' 'FC5'} {'116' 'F5' 'FC1'} {'117' 'T8'} {'118' 'P7'} {'119' 'PO4'} {'121' 'T8'} {'122' 'CP4'} {'124' 'CP4' 'T7'} {'126' 'C5' 'C3' 'P4'} {'128' 'CP4'} {'129' 'PO4'} {'131' 'PO4' 'FZ' 'FCZ'} {'132' 'CP4' 'P8'} {'133' 'PO4'} {'134' 'CP4'} {'136' 'PO4' 'AF4' 'F6'} {'137' 'PO4'} {'139' 'CP4'} {'140' 'PO4'} {'141' 'FZ' 'P7'} {'143' 'FZ' 'F1' 'TP7'}  {'146' 'TP7' 'FT8' 'TP8'} {'147' 'FC2'} {'148' 'TP8'} {'149' 'TP8' 'C6' 'T7' 'C2' 'FPZ' 'FT8'} {'157' 'FPZ' 'TP8' 'AF4' 'CPZ'} {'158' 'AF3'} {'159' 'O1'} {'160' 'TP8' 'T8'} {'161' 'AF4'} {'164' 'O1' 'F1' 'FPZ'} {'165' 'O1'} {'166' 'O1' 'TP8'} {'168' 'T8'} {'170' 'O1' 'FZ'} {'171' 'TP7' 'P7' 'TP8' 'O1' 'FZ'} {'204' 'CP4'} {'207' 'TP8' 'F6'} {'211' 'T7' 'FT7' 'TP7'} {'214' 'F3' 'PO4'} {'217' 'F5' 'F7'} {'219' 'F7'} {'220' 'CP2' 'F6'} {'222' 'FC1'} {'223' 'PO4'} {'226' 'T7'} {'227' 'TP8' 'F8'} {'229' 'TP8'} {'230' 'C5'} {'233' 'AF4' 'TP8' 'P4' 'P6'} {'242' 'FC6'} {'244' 'O1' 'T8' 'TP7' 'P8'} {'246' 'O1'} {'305' 'F7' 'T8' 'F8'} {'306' 'F8' 'F5' 'F3' 'P1'} {'307' 'F5' 'F7'} {'309' 'C3'} {'311' 'PO4' 'FP1'} {'312' 'CP4' 'F5'} {'313' 'F8' 'C6' 'F6'} };

% WOKRING MEMORY TASK ('wm')
subBadElecsWM = { {'103' 'T8'} {'106' 'FC2'} {'203' 'AF4'} {'207' 'C2' 'CP2' 'TP8' 'P3' 'P8'} {'112' 'TP7'} {'113' 'CB2'} {'115' 'FC3'} {'213' 'C4'} {'117' 'CB2' 'P6'} {'306' 'PO4'} {'221' 'F5'} {'220' 'F7' 'F5'} {'122' 'VEO'} {'123' 'CP4'} {'126' 'O1'} {'206' 'CP2'} {'223' 'PO4'} {'140' 'PO4'} {'141' 'PO4'} {'131' 'PO4'} {'135' 'PO4'} {'136' 'PO4'} {'138' 'PO4'} {'228' 'AF4' 'F6' 'CP4' 'P4' 'TP7' 'P7' 'PO7'} {'230' 'F5' 'PO3' 'P4' 'F2' 'F8'} {'145' 'P4' 'F8'} {'228' 'AF4' 'F6' 'CP4' 'P4' 'TP7' 'P7' 'PO7'} {'148' 'AF3' 'FP2'} {'152' 'TP8'} {'153' 'FPZ'} {'154' 'TP8'} {'237' 'FPZ'} {'307' 'F7'} {'199' 'CP2'}};
% 207 'C2' 'CP2' 'TP8' 'P3' 'P8' create off/on noise throughout experiment

% electrodes from /nfs/to-eeg/code/neuroscan/neuroscan_60_cap_3_2_2011.ced
electrodeNames = {'FP1' 'FPZ' 'FP2' 'AF3' 'AF4' 'F7' 'F5' ...
    'F3' 'F1' 'FZ' 'F2' 'F4' 'F6' 'F8' 'FT7' 'FC5' 'FC3' ...
    'FC1' 'FCZ' 'FC2' 'FC4' 'FC6' 'FT8' 'T7' 'C5' 'C3' 'C1' ...
    'CZ' 'C2' 'C4' 'C6' 'T8' 'TP7' 'CP5' 'CP3' 'CP1' ...
    'CPZ' 'CP2' 'CP4' 'CP6' 'TP8' 'P7' 'P5' 'P3' 'P1' ...
    'PZ' 'P2' 'P4' 'P6' 'P8' 'PO7' 'PO5' 'PO3' 'POZ' 'PO4' ...
    'PO6' 'PO8' 'O1' 'OZ' 'O2'};

%-----CODE-----%
includedElectrodes = cell2mat(varargin); % matrix of electrode indices
excludedElectrodes = {'NaN'}; % Electrodes to exclude ('NaN' includes all electrodes)

if strcmp(task, 'ts') % Temporal Sequence
    subBadElecs = subBadElecsTS;
elseif strcmp(task, 'wm') % Working Memory
    subBadElecs = subBadElecsWM;
else
    error('First input must be "ts" or "wm"')
end

if ~isempty(subBadElecs)
    badSub = false;
    % Check if subject has electrodes to exclude
    for iSub = 1:length(subBadElecs)
        badArray = subBadElecs{iSub};
        if strcmp(badArray{1}, sub)
            badSub = true;
            break
        end
    end
    
    if badSub
        excludeCount = 0; % Keep track of valid 'excluded' electrodes
        for iBadElec = 2:length(badArray) % Loop through electrode names only
            badElecName = badArray{iBadElec}; % Name of electrode
            badElec = strcmp(electrodeNames, badElecName); % create matrix of 0's (no match) and 1's (EXACT match)
            badElecIndex = find(badElec); % Finds bad electrode index
            if isempty(badElecIndex) % Alert that electrode name doesn't exist (user typo)
                fprintf('ELECTRODE NOT FOUND: %s %s\n', sub, badElecName)
            else % exclude electrode from 'includeElectrodes'
                excludeCount = excludeCount + 1;
                excludedElectrodes{excludeCount} = badElecName;
                includedElectrodes = includedElectrodes(find(includedElectrodes ~= badElecIndex));
                if displayMsg
                    fprintf('Subject %s EXCLUDING ELECTRODE FROM ANALYSIS: %s\n', sub, badElecName)
                end
            end
        end % for iBadElec = 2:length(badArray)
    end % if badSub
end % if ~isempty(subBadElecs)
