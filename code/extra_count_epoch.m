% Semi-automatic scripts for preprocessing EEG data
% *******************************Extra Script***********************************
%   >> Could be used at step 3 of preprocessing to get a feeling of the
%   data quality.
%
%   >>.. Outline ..
%   1. Clear All
%   2. Find the data folders and configuration files, define parameters
%   3. LOOP on subjects:
%       3.1 merge .cnt files
%       3.2 ensure subject ID matches EEG data input (checkSubId.m)
%       3.2 downsample, re-reference and high pass filter
%      END LOOP on subjects
%
%   Note:
%   >> Organized by Yicong Zheng (Aug 8, 2019)

%%
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
% 1. Clear ALL
clear;clc;close all;

% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
% 2. Define data folders and configuration files
addpath('/Users/cns-memory/Documents/Matlab/eeglab2019_0/')
addpath('/Users/cns-memory/Desktop/TS_EEG/code/');                          % code directory

dataPath       = '/Users/cns-memory/Desktop/TS_EEG/';
dataFileEnding = '_5_epoch_rejection_xl.set';

conditions    = {'fixed1' 'fixed2' 'novel' 'random1' 'random2'};            % finds first label in EEG.epoch(:).eventlabel

%%
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
% 3. Make subject list:
validSubId = true;                                                          % Continues while loop until false
while validSubId                                                            % Must input value between 100 and 400
    subPrompt = 'Input IDs in brackets [101 102 103] or [0] for ALL IDs:';
    subjects = input(subPrompt);                                            % RR3 subject ID(s)
    validSubId = false;                                                     % exit loop
    for iSubInput = subjects
        if iSubInput == 0
            subjects = [];                                                  % reset subjects array
            allDirs = dir('/Users/cns-memory/Desktop/TS_EEG/');
            for jDir = 1:length(allDirs)
                if iSubInput > 100 || iSubInput < 400                       % RR3 IDs between 100 and 400
                    subjects = [subjects str2double(allDirs(jDir).name)];
                end
            end
            subjects = subjects(~isnan(subjects));
            if isempty(subjects)
                fprintf('NO VALID RR3 WM SUBJECTS FOUND\n')
                return
            end
        elseif iSubInput < 101 || iSubInput > 399                           % RR3 IDs between 100 and 400
            clc
            fprintf('INVALID INPUT: %d\n', iSubInput)
            validSubId = true;                                              % stay in loop
            break
        end
    end
end

eeglab

%%
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
% 4. LOOP on subjects:
% preprocess steps subject by subjct
bad_sub_count = 0;
nSub = 0;
for iSub = 1:length(subjects) % loop through subjects
    tStart2     = tic; % Subject specific process time
    subId       = num2str(subjects(iSub)); % 3 digit sub id
    
    fileName    = [subId, dataFileEnding];
%     filePath    = dataPath;
    filePath    = [dataPath, subId, '/'];
    inputFile   = fullfile(filePath, fileName);
    
    if ~exist(inputFile, 'file') % Load pre-processed file
        fprintf('MISSING %s INPUT FILE: %s\n', subId, inputFile)
        continue
    else
        EEG = pop_loadset('filename', fileName, 'filepath', filePath);
        nSub = nSub + 1;
    end
    
%     % Separate trials by condition
    trialTypes = {};
    block_of_event = {};
    for jCond = 1:length(conditions) % loop through conditions
        trialIndex = []; % Reset index for each condition
        block_idx_tmp = [];
        for kEpoch = 1:length(EEG.epoch) % loop through epochs
            % Loop through labels starting with middle (epochs overlap)
            for mLabel = 7:8
                if strfind(EEG.epoch(kEpoch).eventlabel{mLabel}, conditions{jCond})
                    trialIndex = [trialIndex kEpoch];
                    event_info = EEG.epoch(kEpoch).eventlabel{mLabel};
                    blockIndex = str2num(event_info((strfind(event_info,'trial')+5):(strfind(event_info,'_pic')-1)));
                    if blockIndex >= 1 && blockIndex <= 5
                        blockIndex = 1;
                    elseif blockIndex >= 6 && blockIndex <= 10
                        blockIndex = 2;
                    elseif blockIndex >= 11 && blockIndex <= 15
                        blockIndex = 3;
                    elseif blockIndex >= 16 && blockIndex <= 20
                        blockIndex = 4;
                    end
                    block_idx_tmp = [block_idx_tmp blockIndex];
                    break
                end
            end % mTrial
        end % kEpoch
        trialTypes{jCond} = trialIndex;
        block_of_event{jCond} = block_idx_tmp;
    end % jCond


    
%     % algorithm 1
%     nFixed1= 0;
%     nFixed2 = 0;
%     nNovel = 0;
%     nRandom1 = 0;
%     nRandom2 = 0;
%     countCheck = 0; % Double check count
%     EpochEventLabel = {EEG.epoch(:).eventlabel};
%     
%     for iEpoch = 1 : length(EpochEventLabel)
%         Label = EpochEventLabel{iEpoch};
%         Event_Count = zeros(1, 5);
%         for iEvent = 1 : length(Label) % Loop through Events (e.g., fixed1, fixed2....)
%             CurrentLabel = Label(iEvent);
%             EventType = CurrentLabel{1}(1:7);
%             switch EventType % Count events number to decide type of this Epoch
%                 case 'fixed1_'
%                     Event_Count(1) = Event_Count(1) + 1;
%                 case 'fixed2_'
%                     Event_Count(2) = Event_Count(2) + 1;
%                 case 'novel_t'
%                     Event_Count(3) = Event_Count(3) + 1;
%                 case 'random1'
%                     Event_Count(4) = Event_Count(4) + 1;
%                 case 'random2'
%                     Event_Count(5) = Event_Count(5) + 1;
%             end
%             TrialType = find(Event_Count == max(Event_Count(:)));
%         end
%         
%         switch TrialType % Add 1 on the type of this Epoch and countCheck
%             case 1
%                 nFixed1 = nFixed1 + 1;
%                 countCheck = countCheck + 1;
%             case 2
%                 nFixed2 = nFixed2 + 1;
%                 countCheck = countCheck + 1;
%             case 3
%                 nNovel = nNovel + 1;
%                 countCheck = countCheck + 1;
%             case 4
%                 nRandom1 = nRandom1 + 1;
%                 countCheck = countCheck + 1;
%             case 5
%                 nRandom2 = nRandom2 + 1;
%                 countCheck = countCheck + 1;
%         end
%     end
%     
%     
%     nTrial(iSub,1)=nFixed1;
%     nTrial(iSub,2)=nFixed2;
%     nTrial(iSub,3)=nNovel;
%     nTrial(iSub,4)=nRandom1;
%     nTrial(iSub,5)=nRandom2;
    
    
    
    
    
    
    % algorithm 2
    block_of_event = {};
    trialTypes = {};
    nTrialTypes = containers.Map({'fixed1' 'fixed2' 'novel' 'random1' 'random2'},[0 0 0 0 0]);
    conditions = keys(nTrialTypes);
    for jCond = 1:length(keys(nTrialTypes)) % loop through conditions
        block_idx_tmp = [];
        for kEpoch = 1:length(EEG.epoch) % loop through epochs
            % Loop through labels starting with middle (epochs overlap)
            if length(EEG.epoch(kEpoch).eventlabel) >= 8
                for mLabel = 7:8
                    if strfind(EEG.epoch(kEpoch).eventlabel{mLabel}, conditions{jCond})
                        nTrialTypes(conditions{jCond}) = nTrialTypes(conditions{jCond}) + 1;
                        event_info = EEG.epoch(kEpoch).eventlabel{mLabel};
                        blockIndex = str2num(event_info((strfind(event_info,'trial')+5):(strfind(event_info,'_pic')-1)));
                        if blockIndex >= 1 && blockIndex <= 5
                            blockIndex = 1;
                        elseif blockIndex >= 6 && blockIndex <= 10
                            blockIndex = 2;
                        elseif blockIndex >= 11 && blockIndex <= 15
                            blockIndex = 3;
                        elseif blockIndex >= 16 && blockIndex <= 20
                            blockIndex = 4;
                        end
                        block_idx_tmp = [block_idx_tmp blockIndex];
                        break
                    end
                end % mLabel
            end
        end % kEpoch
        block_of_event{jCond} = block_idx_tmp;
    end % jCond
    

    
    for jBlock = 1:4
        for iCond = 1:5
            nTrial(nSub,iCond,jBlock) = length(find(block_of_event{iCond}==jBlock));
        end
        nTrial(nSub, 6, jBlock) = str2num(subId);
    end
    nTrial_early = nTrial(:,:,1)+nTrial(:,:,2);
    nTrial_late = nTrial(:,:,3)+nTrial(:,:,4);


end