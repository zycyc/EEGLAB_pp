% Semi-automatic scripts for preprocessing EEG data
% usage: load, downsample, band filter, epoch, ICA, remove eye-sensitive ICA,
%        , reference, interpolate bad channel, reject bad trials
%   >> Inputs::  .cnt EEG file
%   >> Outputs:  .set EEGLAB data
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
% *******************************Step 1 + 2***********************************
%   >> This is the steps from the very beginning and running through epoch. We do manually epoch rejection before ICA with a liberal threshold just to move bad epoch for ICA.
%
%   >>.. Outline ..
%   1. clear clc close
%   2. Find the data folders and configuration files, define parameters
%   3. Make subject list
%   4. LOOP on subjects:
%       4.1 merge .cnt files
%       4.2 downsample, re-reference and high pass filter
%      END LOOP on subjects
%
%   Note:
%   >> Organized by Alan Zheng (Augest 2019). Original script from Xiaonan Liu.
%   >> "ts" refers to "temporal sequence" study. You can replace all "ts"
%       to your study acronym.
%   ?? Not sure if we need a notch filter

%%
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
% 1. Clear
clear;
clc;
close all;

% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
% 2. Define data folders and configuration
includedElectrodes = 1:64;
refChan = [33, 43]; % [33 43] IRC mastoids (reference channels)
sampleRate = 500; % Down-sample to 500Hz
highPassFilter = 0.5; % high pass filter at 0.5Hz

addpath('/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/code/'); % all your code
addpath('/Users/zycyc/Documents/Matlab/eeglab2019_0/'); % eeglab path
dataPath = '/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/test/'; % for reading subject info
tsRawData = '/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/test/'; % raw data path
tsOutDir = '/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/test/'; % output data path
locFile = '/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/neuroscan/neuroscan_64_cap_3_2_2011.ced'; % EEG cap channel location file

savefile1ending = '_1_ts_raw_merged_data.set';
savefile2ending = '_2_ts_raw_filt_data.set';
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
    saveSetName = [subId, '_ts'];
    finaltsOutDir = fullfile(tsOutDir, subId, '/'); % TS final data path
    saveFile1 = [finaltsOutDir, subId, savefile1ending];
    saveFile2 = [finaltsOutDir, subId, savefile2ending];
    subRawDir = [tsRawData, subId, '/']; % Directory of raw .cnt files

    subCntFiles = dir([subRawDir, '*cnt']); % Finds raw .cnt files
    totalCnt = length(subCntFiles); % Should find 4 '.cnt' files (ts)
    if totalCnt == 0 % Check if any files were found
        fprintf('NO CNT FILES FOUND FOR %s\n', subId);
        return
    else
        fprintf('%d CNT FILES FOUND FOR %s\n', totalCnt, subId);
    end

    % read all '.cnt' files and convert into EEGLAB format
    cntRange = 1:totalCnt;
    for iBlock = cntRange % Load each '.cnt' file
        indexEEG = iBlock - 1; % Index starts at 0
        cntNameSet = [subCntFiles(iBlock).name];
        cntFile = [subRawDir, cntNameSet]; % cnt file path
        namename = [subRawDir, num2str(iBlock)]; % EEG dataset name
        if exist(cntFile, 'file')
            EEG = pop_loadcnt(cntFile);
            [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, indexEEG, 'setname', namename, 'savenew', namename, 'gui', 'off'); % into EEGLAB format
        else
            fprintf('MISSING FILE: %s', cntFile);
        end
    end

    % ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
    % 4.1 merge .cnt files
    EEG = pop_mergeset(ALLEEG, cntRange, 0); % merge 4 .cnt files (ts)
    EEG.setname = subId;
    EEG.chanlocs = readlocs(locFile); % EEG channel/electrode labels

    % Save raw dataset (File 1)
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', saveSetName, 'savenew', saveFile1, 'gui', 'off');
    fprintf('CREATED: %s\n', saveFile1);
    if ~exist(saveFile1, 'file')
        fprintf('MISSING: %s\n', saveFile1);
        return
    end
    checkSubId(EEG.setname, saveSetName); % Check sub ID matches loaded data set

    % ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
    % 4.2 downsample, re-reference and high pass filter
    EEG = pop_select(EEG, 'nochannel', {'EKG', 'EMG'}); % Remove unused channels
    EEG = pop_resample(EEG, sampleRate); % downsample to 500Hz
    EEG = pop_reref(EEG, refChan, 'keepref', 'on'); % reference to the average of the mastoids
    EEG.data = eegfilt(EEG.data, EEG.srate, highPassFilter, []); % High pass filter at 0.5Hz

    % Save raw filtered dataset (File 2)
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', saveSetName, 'savenew', saveFile2, 'gui', 'off');
    fprintf('CREATED: %s\n', saveFile2);
    if ~exist(saveFile2, 'file')
        fprintf('MISSING: %s\n', saveFile2);
        return
    end
end
