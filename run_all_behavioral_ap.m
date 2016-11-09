%%===============================================================
% wrapper for why/how fmri 
%===============================================================
clear all; home;
%===============================================================
% change to study directory
%===============================================================
studyDIR = pwd; cd(studyDIR)
dataDIR = [studyDIR filesep 'data'];
utilityDIR = [studyDIR filesep 'utilities'];
addpath(utilityDIR)

%===============================================================
% start by getting necessary inputs
%===============================================================

% get subject ID
subjectID=input('\nEnter subject ID: ','s');
while isempty(subjectID)
    disp('ERROR: no value entered. Please try again.');
    subjectID=input('Enter subject ID: ','s');
end;

% Participant input device (inputDevice)
subdevice_string='- Choose Device -'; boxTop(1:length(subdevice_string))='-';
fprintf('\n%s\n%s\n%s\n',boxTop,subdevice_string,boxTop)
[inputDevice usageName product] = hid_probe;

% Setup window
w = ptb_setup_screen(0,250,'Arial',55); % setup screen

% check screen resolution
screenres = w.res(3:4); % screen resolution
correctres = [1024 768];
if mean(ismember(screenres,correctres))<1
    fprintf('\n\n\n\n\tScreen resolution must be set to 1024 x 768\n\n\n\n');
    Screen('CloseAll');
    Priority(0);
    ShowCursor;
    return
end
display_message('Press any key to begin Part 1 of 3.',w.win,inputDevice) % message
% ----------------------
% RATINGS
% ----------------------
inputDevice = hid_get(usageName,product);
ratings(subjectID,inputDevice,w)          % task
display_message('Press any key to begin Part 2 of 3.',w.win,inputDevice) % message
% ----------------------
% IDS
% ----------------------
ids_alt(subjectID,inputDevice,w);
display_message('Please let the experimenter know that you are finished.',w.win,inputDevice) % message

% Close Screen
%===============================================================
Screen('CloseAll');
Priority(0);
ShowCursor;

% move logfiles into data directory
movefile('*.log',dataDIR)
