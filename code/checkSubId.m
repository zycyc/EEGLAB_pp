function checkSubId(eegSetName,subSetName)
%%% Created: 03/11/2015 By: Evan Layher 
%%% Latest Revision: 03/20/2015 By: Evan Layher
% RR3 check the subject 'save_set_name' variable matches the loaded
% EEG.setname value. Otherwise the data will be saved to the wrong
% participant number.

compareIds = strcmp(eegSetName,subSetName);

if compareIds == 0
    fprintf('***ID MISMATCH*** EEG.setname = "%s" save_set_name = "%s"\n', eegSetName, subSetName)
    error('Must correct "sub_id" variable to match loaded EEG.setname')
    return
end
