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
% *******************************Step 3b***********************************
%   >> This is for manually pick out bad epochs and channels
%
%   >>.. Outline ..
%   1. clear clc close
%   2. Find the data folders and configuration files, define parameters
%   3. Make subject list
%   4. LOOP on subjects:
%       4.1 go through all epochs and pick out bad epochs (and reject) and
%           bad channel (and record in removeElectrodes.m)
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
addpath('/Users/zycyc/Documents/Matlab/eeglab2019_0/'); %eeglab directory
dataPath = '/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/test/'; % input data path
tsOutDir = '/Users/zycyc/Documents/Abroad/UCDavis/EEGLAB_pp/test/'; % output data path
dataFileEnding = '_3_ts_epoch.set';
saveEnding = '_3_ts_clean_epoch.set';

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
                fprintf('NO VALID WM SUBJECTS FOUND\n');
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
    saveSetName = [subId, '_ts']; % eeglab set name
    fileName = [subId, dataFileEnding];
    filePath = [dataPath, subId, '/']; % input data path
    inputFile = fullfile(filePath, fileName); % input data
    savefile1 = [tsOutDir, subId, '/', subId, saveEnding]; % output data
    
    if ~exist(inputFile, 'file') % check input file
        fprintf('MISSING %s INPUT FILE: %s\n', subId, inputFile)
        continue
    else
        EEG = pop_loadset('filename', fileName, 'filepath', filePath); % load data
        
        % ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
        % 4.1 visual inspection & rejection
        pop_eegplot(EEG, 1, 1, 1);
        ud = get(gcf, 'UserData');
        ud.winlength = 2; % window length (how many epochs per screen)
        ud.spacing = 70; % spacing of data (degree of magnification)
        set(findobj(gcf, 'Tag', 'ESpacing'), 'string', num2str(ud.spacing));
        set(gcf, 'UserData', ud);
        eegplot('draws', 0);
        uiwait; % wait for inspection and rejection
        
        % creat new set and save
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', saveSetName, 'savenew', savefile1, 'gui', 'off');
        fprintf('CREATED: %s\n', saveSetName)
    end
end
