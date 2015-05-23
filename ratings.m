function ratings(subjectID,inputDevice,w)

% ====================
% DEFAULTS
% ====================

%% Paths %%
basedir = pwd;
datadir = fullfile(basedir, 'data');
stimdir = fullfile(basedir, 'stimuli/rate');
scaledir = fullfile(basedir, 'stimuli');
utilitydir = fullfile(basedir, 'utilities');
addpath(utilitydir)

%% Text %%
theFont='Arial';    % default font
theFontSize=46;     % default font size
fontwrap=42;        % default font wrapping (arg to DrawFormattedText)

%% Response Keys %%
space = KbName('space');
enter = KbName('enter');
valid_keys = {'1!' '2@' '3#' '4$' '5%' '6^' '7&' '8*' '9('};



% ====================
% END DEFAULTS
% ====================

%% Print Title %%
script_name='-- Rating Task --'; boxTop(1:length(script_name))='=';
fprintf('%s\n%s\n%s\n',boxTop,script_name,boxTop)


if nargin==0
    
    %% Get Subject ID %%
    subjectID = ptb_get_input_string('\nEnter subject ID: ');
    
    %% Setup Input Device(s) %%
    inputDevice = ptb_get_resp_device('Choose Response Device'); % input device
    
    %% Initialize Screen %%
    w = ptb_setup_screen(0,250,theFont,theFontSize); % setup screen
    
end
resp_set = ptb_response_set(valid_keys); % response set
screenres = w.res(3:4); % screen resolution


%% Initialize Logfile (Trialwise Data Recording) %%
d=clock;
logfile=sprintf('sub%s_ratings.log',subjectID);
fprintf('\nA running log of this session will be saved to %s\n',logfile);
fid=fopen(logfile,'a');
if fid<1,error('could not open logfile!');end;
fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));

%% Load Stimuli %%
DrawFormattedText(w.win,'LOADING','center','center',w.white,fontwrap);
Screen('Flip',w.win);
stimFiles = files([stimdir filesep '*jpg']);
ntrials = length(stimFiles);
randidx = randperm(length(stimFiles));
randstimFiles = stimFiles(randidx); % stimFiles is now randomized
% load stimuli
for i = 1:length(randstimFiles)
    slideName{i} = randstimFiles{i};
    slideTex{i} = Screen('MakeTexture',w.win,imread(randstimFiles{i}));
    Seeker(i,1) = cellstrfind(stimFiles,randstimFiles{i});
    Seeker(i+90,1) = Seeker(i,1);
%     Seeker(i+180,1) = Seeker(i,1);
end
% load scales
scaleFiles = files([scaledir filesep 'scale*jpg']);
nscale = length(scaleFiles);
randidx = randperm(length(scaleFiles));
randscaleFiles = scaleFiles(randidx); 
instructFiles = files([scaledir filesep 'rate*jpg']);
randinstructFiles = instructFiles(randidx);
for i = 1:length(randscaleFiles)
    scaleTex{i} = Screen('MakeTexture',w.win,imread(randscaleFiles{i}));
    instructionTex{i} = Screen('MakeTexture',w.win,imread(randinstructFiles{i}));
end
Seeker(1:90,2) = str2num(randscaleFiles{1}(end-4));
Seeker(91:180,2) = str2num(randscaleFiles{2}(end-4));
% Seeker(181:270,2) = str2num(randscaleFiles{3}(end-4));
fixTex = Screen('MakeTexture', w.win, imread([scaledir filesep 'fixation.jpg']));
introTex = Screen('MakeTexture',w.win,imread([scaledir filesep 'introrate.jpg']));

%% SEEKER column key %%
% 1 - slide # (corresponds to order in stimulus dir)
% 2 - question # (correponds to order in scale dir)
% 3 - response (1-9 corresponding to rating)
% 4 - reaction time

% ====================
% START TASK
% ====================
%% Present Instruction Screen %%
Screen('DrawTexture',w.win,introTex);
Screen('Flip',w.win);
WaitSecs(.5);
[resp rt] = ptb_get_resp(inputDevice, space);
Screen('FillRect', w.win, w.black); Screen('Flip', w.win);
%% Loop Over Trials %%
try
    for s = 1:nscale
        
        %% Present Instruction Screen %%
        WaitSecs(3)
        Screen('DrawTexture',w.win,instructionTex{s}); 
        Screen('Flip',w.win);
        WaitSecs(1);
        [resp rt] = ptb_get_resp(inputDevice, space);
      
        
        
        extra = (s-1)*90;
    
        for t = 1:90
            
            %% Present Fixation %%
            Screen('DrawTexture',w.win, fixTex); Screen('Flip',w.win);
            WaitSecs(1);
            
            %% Load Some Stuff and Present Photo and Scale %%
%             imageRect = [0 0 1024 239];
%             dstRect = CenterRect(imageRect,Screen('Rect',w.win));

            
            Screen('DrawTexture',w.win,slideTex{t});
            Screen('DrawTexture',w.win,scaleTex{s},[],[0 768-239 1024 768])
            
            %% Present Photo Stimulus and Wait for Response %%
            Screen('Flip',w.win);
            resp = [];
            [resp rt] = ptb_get_resp(inputDevice, resp_set);

            %% Present Fixation and Record Response %%
            Screen('Flip',w.win);
            if ~isempty(resp)
                Seeker(t+extra,3) = str2num(resp(1));
                Seeker(t+extra,4) = rt;
            end

            %% Save Data to Logfile
            fprintf(fid,[repmat('%d\t',1,size(Seeker,2)) '\n'],Seeker(t,:));

        end
    end
    
catch
    
    Screen('CloseAll');
    Priority(0);
    ShowCursor;
    psychrethrow(psychlasterror);
    
end

%% Save Data to Matlab Variable %%
d=clock;
outfile=sprintf('rate_%s_%s_%02.0f-%02.0f.mat',subjectID,date,d(4),d(5));
try
    save([datadir filesep outfile], 'subjectID', 'Seeker', 'slideName'); 
catch
	fprintf('couldn''t save %s\n saving to rate.mat\n',outfile);
	save rate
end;

if nargin==0
    %% Exit %%
    Screen('CloseAll');
    Priority(0);
    ShowCursor;
end
fclose(fid);


