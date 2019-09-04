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
% *******************************Step 4a***********************************
%   >> This script loads epoch-removed data and remove bad channel + run
%      binica
%
%   >>.. Outline ..
%   1. clear clc close
%   2. Find the data folders and configuration files, define parameters
%   3. Make subject list
%   4. LOOP on subjects:
%       4.1 remove bad channels using removeElectrodes.m
%       4.2 run binica
%       4.3 MARA
%      END LOOP on subjects
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
includedElectrodes = 1:64;

addpath('/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/code/'); % EEG code directory
addpath('/Users/zycyc/Documents/Matlab/eeglab2019_0/'); % eeglab path

locFile = '/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/neuroscan/neuroscan_60_cap_3_2_2011.ced'; % EEG cap channel location file
dataPath = '/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/test/'; % input data path
tsOutDir = '/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/test/'; % output data path
dataFileEnding = '_3_ts_clean_epoch.set'; % input file ending
savefile1ending = '_3_ts_epoch_channelremoved.set';
savefile2ending = '_4_ts_ICA.set';

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
                fprintf('NO VALID ts SUBJECTS FOUND\n');
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
    
    % Load input file
    fileName = [subId, dataFileEnding];
    filePath = [dataPath, subId, '/']; % input data path
    inputFile = fullfile(filePath, fileName);
    savefile1 = [tsOutDir, subId, '/', subId, savefile1ending]; % output data path 1
    savefile2 = [tsOutDir, subId, '/', subId, savefile2ending]; % output data path 2
    
    if ~exist(inputFile, 'file') % check input file
        fprintf('MISSING %s INPUT FILE: %s\n', subId, inputFile)
        continue
    else
        saveSetName = [subId, '_ts'];
        EEG = pop_loadset('filename', fileName, 'filepath', filePath); % load dataset
        
        % ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
        % 4.1 remove bad channels
        [~, EEG.excludeChans] = removeElectrodes('ts', subId, 1, includedElectrodes); % open this function to edit bad channels for each subject
        EEG = pop_select(EEG, 'nochannel', {'M1', 'M2', 'CB1', 'CB2', 'VEO', 'HEO'}); % exclude these channels (64 --> 60)
        EEG.chanlocs = readlocs(locFile); % EEG labels (60 channels)
        if EEG.excludeChans{1, 1}(1) ~= 'N' % exclude bad channels (perfect ones will be 'NaN')
            EEG = pop_select(EEG, 'nochannel', EEG.excludeChans);
        end
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', saveSetName, 'savenew', savefile1, 'gui', 'off');
        
        % ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
        % 4.2 run binica
        EEG = pop_runica(EEG, 'icatype', 'binica', 'dataset', 1, 'options', {'extended', 1});
        
        % ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
        % 4.3 MARA toolbox
        [ALLEEG, EEG, CURRENTSET] = processMARA(ALLEEG, EEG, CURRENTSET);
        
        % save new set
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', saveSetName, 'savenew', savefile2, 'gui', 'off');
        fprintf('CREATED: %s\n', saveSetName)
    end
end
