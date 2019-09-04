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
% *******************************Step 3a***********************************
%   >> This is only for making epoch, after step 1 and 2.
%
%   >>.. Outline ..
%   1. clear clc close
%   2. Find the data folders and configuration files, define parameters
%   3. Make subject list:
%   4. LOOP on subjects:
%       4.1 go through all events and make into epochs
%      END LOOP on subjects
%
%   Note:
%   >> Organized by Alan Zheng (Augest 2019). Original script from Xiaonan Liu.
%   >> "ts" refers to "temporal sequence" study. You can replace all "ts"
%       to your study acronym.

%%
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
% 1. Clear
clear;
clc;
close all;

% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
% 2. Define data folders and configuration
epochTimeRange = [-3, 14]; % Actual epoch is [-1.5 12.5] (pad each end with 1.5 seconds for wavelet analysis)
epochBaseline = [-1500, 0]; % 1.5 seconds before first stimulus
includedElectrodes = 1:64;

tsOutDir = '/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/test/'; % output data path
addpath('/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/code/'); % EEG code directory
addpath('/Users/zycyc/Documents/Matlab/eeglab2019_0/'); % eeglab path

dataPath = '/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/test/'; % for reading subject info and data
seqDir = '/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/example_behavior/'; % for reading behavioral data
dataFileEnding = '_2_ts_raw_filt_data.set';
SaveEnding = '_3_ts_epoch.set';

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
                    subjects = [subjects, str2double(allDirs(jDir).name)];
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
% preprocess steps subject by subjct
eeglab
for iSub = 1:length(subjects) % loop through subjects
    subId = num2str(subjects(iSub)); % 3-digit sub id
%     finalTsOutDir = [tsOutDir, subId, '/']; % final data output path
%     eegBehaveFile = ['/Users/zycyc/Documents/Abroad/UCDaivs/Dynamic_Memory_Lab/TS_EEG/behave/ts/eeg_final/', subId, '_ts_eeg_count.txt']; % TS trials left after rejection
    seqPath = [seqDir, subId, '/hires_land4_ss', subId, '.txt']; % sequence file
    
    fileName = [subId, dataFileEnding]; % Load input file
    filePath = [dataPath, subId, '/']; % input data path
    inputFile = fullfile(filePath, fileName); % input data
    saveFile = [tsOutDir, subId, '/', subId, SaveEnding]; % output data
    if ~exist(inputFile, 'file')
        fprintf('MISSING %s INPUT FILE: %s\n', subId, inputFile)
        continue
    else
        saveSetName = [subId, '_ts']; % set name 
        EEG = pop_loadset('filename', fileName, 'filepath', filePath); % load data
        
        % ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
        % Note:
        % Below is what you probably don't need to understand, it's very
        % task-specific. The gist is to go through every event in your data
        % and give them propriate labels and type. After that, we use
        % [pop_epoch] to squeeze these events into epochs.
        
        fid = fopen(seqPath); % Matches picture number to trial types
        % fixed1
        tmp = fgetl(fid);
        [~, trigger] = strtok(tmp);
        fixed1 = str2num(trigger);
        % fixed2
        tmp = fgetl(fid);
        [~, trigger] = strtok(tmp);
        fixed2 = str2num(trigger);
        % random1
        tmp = fgetl(fid);
        [~, trigger] = strtok(tmp);
        random1 = str2num(trigger);
        % random2
        tmp = fgetl(fid);
        [~, trigger] = strtok(tmp);
        random2 = str2num(trigger);
        
        picCount = 1; % 1 to 5
        absCount = 1; % absolute picture count 1 to 500
        firstPics = [fixed1(1), fixed2(1), 501, 502]; % Get first novel picture below. 501 = random1 502 = random2
        
        % Below are trial counts (1 to 20 each)
        fixed1Count = 1;
        fixed2Count = 1;
        random1Count = 1;
        random2Count = 1;
        novelCount = 1;
        
        for iEvent = 1:length(EEG.event)
            if str2double(EEG.event(iEvent).type) == 501
                EEG.event(iEvent).type = num2str(random1(1));
            end
            if str2double(EEG.event(iEvent).type) == 502
                EEG.event(iEvent).type = num2str(random2(1));
            end
        end
        
        % ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
        % 4.1 go through events and make into epochs
        for iEvent = 1:length(EEG.event)
            eventNumber = str2double(EEG.event(iEvent).type);
            checkNumber = length(eventNumber); % Removes 'boundary'
            picLabel = num2str(picCount);
            absLabel = num2str(absCount);
            fixed1Label = num2str(fixed1Count);
            fixed2Label = num2str(fixed2Count);
            random1Label = num2str(random1Count);
            random2Label = num2str(random2Count);
            novelLabel = num2str(novelCount);
            if checkNumber > 0 % strings will create empty array
                if eventNumber > 0 && eventNumber <= 250 % (30 trial + 220 novel)
                    absCount = absCount + 1; % Count each picture
                    if any(eventNumber == fixed1)
                        EEG.event(iEvent).label = ['fixed1_trial', fixed1Label, '_pic', picLabel, '_', absLabel];
                        if picCount == 5
                            fixed1Count = fixed1Count + 1;
                        end
                    elseif any(eventNumber == fixed2)
                        EEG.event(iEvent).label = ['fixed2_trial', fixed2Label, '_pic', picLabel, '_', absLabel];
                        if picCount == 5
                            fixed2Count = fixed2Count + 1;
                        end
                    elseif any(eventNumber == random1)
                        EEG.event(iEvent).label = ['random1_trial', random1Label, '_pic', picLabel, '_', absLabel];
                        if picCount == 1
                            EEG.event(iEvent).type = '501'; % first random1 pic
                        end
                        if picCount == 5
                            random1Count = random1Count + 1;
                        end
                    elseif any(eventNumber == random2)
                        EEG.event(iEvent).label = ['random2_trial', random2Label, '_pic', picLabel, '_', absLabel];
                        if picCount == 1
                            EEG.event(iEvent).type = '502'; % first random2 pic
                        end
                        if picCount == 5
                            random2Count = random2Count + 1;
                        end
                    else
                        EEG.event(iEvent).label = ['novel_trial', novelLabel, '_pic', picLabel, '_', absLabel];
                        if picCount == 5
                            novelCount = novelCount + 1;
                        end
                        if picCount == 1
                            firstPics = [firstPics, eventNumber];
                        end
                    end
                    if picCount >= 5 % 5 pictures in each sequence
                        picCount = 1;
                    else
                        picCount = picCount + 1;
                    end
                elseif eventNumber == 254
                    EEG.event(iEvent).label = 'crosshair';
                elseif eventNumber == 255
                    EEG.event(iEvent).label = 'instructions';
                else
                    EEG.event(iEvent).label = 'unknown_event';
                end
            else
                EEG.event(iEvent).label = 'unknown_event';
            end
        end
        
        EEG.picOnsets = firstPics; % Store first picture values in EEG stucture
        allOnsets = firstPics; % Use for epoch
        
        onsetValues = num2cell(allOnsets); % epoch window
        EEG = pop_epoch(EEG, onsetValues, epochTimeRange, 'epochinfo', 'yes'); % epoch event (see comments above)
        
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', saveSetName, 'savenew', saveFile, 'gui', 'off');
        fprintf('CREATED: %s\n', saveSetName)
    end
end
