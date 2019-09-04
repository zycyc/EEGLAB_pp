# Naming rule
[subID, step, ProjName, StepName]
- subID: 101, 102, 103....
- step: for preprocessing 1~5, you can make your further steps
- ProjName: the acronym of your project (e.g., 'ts' for 'Temporal Sequence')
- StepName: introduction of this step


# Expected Folder structure:
- Project Folder
	- EEG data
		- 101
			- raw data
			- step1 data
			- step2 data
			- ...
		- 102
			- raw data
			- step1 data
			- step2 data
			- ...
		- eeg_count (epoch counting)
			- 101_ts_eeg_count.txt
			- 102_ts_eeg_count.txt
			- ...
	- Behavior data
		- 101
			- raw behavior data (task-specific)
		- 102
			- raw behavior data (task-specific)
	- Code
		- EEG_PP_1_2.m
		- EEG_PP_3a.m
		- ...
	- Neuroscan (map for electrodes)
		- neuroscan_64_cap_3_2_2011.ced
		- ...
	- ...


# Note
These preprocessing scripts are made from a study named "Temporal Sequence", in this study we need to make several pictures into a sequence, which makes the epoch part special. For experiment paradigm, check out this [paper](https://www.sciencedirect.com/science/article/pii/S1074742718301126) by Jordan Crivelli-Decker, Liang-Tien Hsieha, Alex Clarkea and Charan Ranganath.

If you are learning to do EEG preprocessing, you can do following steps to try it out:
	1. pick the files (.fdt + .set) from the step you want to start with, copy them from 'example_eeg/101' to 'test/101'
	2. read and run the script that takes the file you choose, this will give you the data for next step
	3. you can now either type in "eeglab" in MATLAB and choose "File" - "Choose existing dataset" to look at the data structure, or you can run the script for next step.

If you are using this template for your own study, please follow the instruction in each script to modify and make it work for your own study (please check your scripts line-by-line to make sure the template doesn't have any undesirable effect on your result).

Please contact Yicong (Alan) Zheng (alanzycyc@gmail.com) or report an issue through Github if you find any bugs, thanks in advance.

Have fun :)

-Alan
09/03/2019