% Semi-automatic scripts for preprocessing EEG data
% usage: load, downsample, band filter, epoch, ICA, remove eye-sensitive ICA,
%        , reference, interpolate bad channel, reject bad trials
%   >> Inputs::  .set
%   >> Outputs:  .set
%
%   >> Step1 + 2(auto):
%           Merge multiple '.cnt' into 1 '.set' file
%           Down-sample, re-reference to mastoids, high pass filter
%   >> Step3a(auto):
%           epoch
%   >> Step3b(manual):
%           visually pick out the bad epoch and channel
%   >> Step4a(auto):
%           ICA (binica) and MARA
%   >> Step4b(manual):
%           visual IC inspection and remove IC
%   >> Step5(manual):
%           remove baseline, bad epoch auto-rejection, manaully reject bad epochs
%
% *******************************Step 5***********************************
%   >> This script loads ICA components removed (clear) data, removes
%   baseline, runs artifact rejecting and finally interpolates bad channels
%
%   >>.. Outline ..
%   1. clear clc close
%   2. Find the data folders and configuration files, define parameters
%   3. Make subject list
%   4a. Load data from one subject to be used in interpolation
%   4b. LOOP on subjects:
%        4.1 remove baseline
%        4.2 artifact rejection
%        4.3 double check calculation of trial is correct
%        4.3 interpolate bad channels
%       END LOOP on subjects
%
%   Note:
%   >> Organized by Alan Zheng (Augest 2019). Original script from Xiaonan Liu.
%   >> "ts" refers to "temporal sequence" study. You can replace all "ts"
%       to your study acronym.

%%
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
% 1. Clear ALL
clear;
clc;
close all;

% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
% 2. Define data folders and configuration
epochBaseline = [-1500, 0];
autoRejectMin = -100;
autoRejectMax = 100;
autoRejectStartTimes = -3;
autoRejectEndTimes = 14;

addpath('/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/code/'); % EEG code directory
addpath('/Users/zycyc/Documents/Matlab/eeglab2019_0/'); % eeglab path

dataPath = '/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/test/'; % input data path
tsOutDir = '/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/test/'; % output data path
finalTsOutDir = '/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/test/eeg_count/'; % output epoch count path
dataFileEnding = '_4_ts_ICA_removed.set';
savedataEnding = '_5_ts_epoch_rejection.set';

%%
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
% 3. Make subject list:
validSubId = true; % Continues while loop until false
while validSubId % Must input value between 100 and 400
    subPrompt = 'Input IDs in brackets [101 102 103] or [0] for ALL IDs:';
    subjects = input(subPrompt); % subject ID(s)
    validSubId = false; % exit loop
    for iSubInput = subjects
        if iSubInput == 0
            subjects = []; % reset subjects array
            allDirs = dir(dataPath);
            for jDir = 1:length(allDirs)
                if iSubInput > 100 || iSubInput < 400 % IDs between 100 and 400
                    subjects = [subjects, str2double(allDirs(jDir).name(1:3))];
                end
            end
            subjects = subjects(~isnan(subjects)); % exclude invalid folder names
            if isempty(subjects)
                fprintf('NO VALID TS SUBJECTS FOUND\n');
                return
            end
        elseif iSubInput < 101 || iSubInput > 399 % IDs between 100 and 400
            clc
            fprintf('INVALID INPUT: %d\n', iSubInput);
            validSubId = true; % stay in loop
            break
        end
    end
end

%%
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
% 4. LOOP on subjects:
eeglab

% for interpolation, select a subject's data that has full channels
EEG101 = pop_loadset('filename', ['/101/101', dataFileEnding], 'filepath', dataPath); 
EEG101Chan = EEG101.chanlocs;
clear EEG101;

% preprocess steps subject by subjct
for iSub = 1:length(subjects) % loop through subjects
    subId = num2str(subjects(iSub)); % 3-digit sub id

    % Load input file
    finalTsOutText = fullfile(finalTsOutDir, [subId, '_ts_eeg_count.txt']); % Trial counts after EEG rejection
    fileName = [subId, dataFileEnding];
    filePath = [dataPath, subId, '/']; % input data path
    inputFile = fullfile(filePath, fileName);
    savefile = [tsOutDir, subId, '/', subId, savedataEnding];

    if ~exist(inputFile, 'file') % check input file
        fprintf('MISSING %s INPUT FILE: %s\n', subId, inputFile)
        continue
    else
        saveSetName = [subId, '_ts'];

        % load, remove baseline, auto-rejection
        EEG = pop_loadset('filename', fileName, 'filepath', filePath);
        EEG = pop_rmbase(EEG, epochBaseline); % baseline subtract last 2s of cross hair before trial
        [EEG, EEG.rejected_indexes] = pop_eegthresh(EEG, 1, [1:EEG.nbchan], autoRejectMin, autoRejectMax, autoRejectStartTimes, autoRejectEndTimes, 1, 1);

        % After auto-rejection, we manaully select bad epochs to reject.
        if length(EEG.rejected_indexes) > 5
            pop_eegplot(EEG, 1, 1, 1);
            ud = get(gcf, 'UserData');
            %     ud.winlength = 1;
            ud.spacing = 70;
            set(findobj(gcf, 'Tag', 'ESpacing'), 'string', num2str(ud.spacing));
            set(gcf, 'UserData', ud);
            eegplot('draws', 0);
            uiwait;
        end

        %% calculate trial type and save info
        % Get behave count after rejecting trials
        nFixed1 = 0;
        nFixed2 = 0;
        nNovel = 0;
        nRandom1 = 0;
        nRandom2 = 0;
        countCheck = 0; % Double check count
        EpochEventLabel = {EEG.epoch(:).eventlabel};
        totalEvents = EEG.trials;

        % algorithm 1 (safer)
        % Loop through Epochs (e.g., 88 epochs)
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

        % algorithm 2 (faster)
        nTrialTypes = containers.Map({'fixed1', 'fixed2', 'novel', 'random1', 'random2'}, [0, 0, 0, 0, 0]);
        conditions = keys(nTrialTypes);
        for jCond = 1:length(keys(nTrialTypes)) % loop through conditions
            for kEpoch = 1:length(EEG.epoch) % loop through epochs
                for mLabel = 7:8 % Loop through labels starting with middle (epochs overlap)
                    if strfind(EEG.epoch(kEpoch).eventlabel{mLabel}, conditions{jCond})
                        nTrialTypes(conditions{jCond}) = nTrialTypes(conditions{jCond}) + 1;
                        countCheck = countCheck + 1;
                        break
                    end
                end % mLabel
            end % kEpoch
        end % jCond

        % double check to decide if calculation of trial number is correct
        if countCheck == totalEvents
            fid = fopen(finalTsOutText, 'w');
            fprintf(fid, 'Fixed1:%d\nFixed2:%d\nNovel:%d\nRandom1:%d\nRandom2:%d\n', nTrialTypes('fixed1'), nTrialTypes('fixed2'), nTrialTypes('novel'), nTrialTypes('random1'), nTrialTypes('random2'));
            fclose(fid); % Creates text file of final count
            EEG.behaveItemFixed1 = nTrialTypes('fixed1');
            EEG.behaveItemFixed2 = nTrialTypes('fixed2');
            EEG.behaveItemNovel = nTrialTypes('novel');
            EEG.behaveItemRandom1 = nTrialTypes('random1');
            EEG.behaveItemRandom2 = nTrialTypes('random2');
        else
            fprintf('BEHAVE ERROR COUNT: EXPECTED %d FOUND %d\n', countCheck, totalEvents)
            fprintf('NOT SAVING DATA\n')
            return
        end

        % Interpolate bad channels (if any)
        if EEG.nbchan < 60
            EEG = eeg_interp(EEG, EEG101Chan);
        end

        % creat new set and save
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', saveSetName, 'savenew', savefile, 'gui', 'off');
        fprintf('CREATED: %s\n', saveSetName)
    end
end
