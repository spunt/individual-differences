function ids(subjectID,inputDevice,w)

% ====================
% DEFAULTS
% ====================

%% Paths %%
basedir = pwd;
datadir = fullfile(basedir, 'data');
stimdir = fullfile(basedir, 'stimuli/alt_scales');
designdir = fullfile(basedir, 'design');
utilitydir = fullfile(basedir, 'utilities');
addpath(utilitydir)

%% Text %%
theFont='Arial';    % default font
fontsize.item = 36;
fontsize.scalepoint = 22;
fontsize.anchor = 14;
fontwrap=48;        % default font wrapping (arg to DrawFormattedText)

%% Response Keys %%
space = KbName('space');
enter = KbName('enter');
valid_keys = {'1!' '2@' '3#' '4$' '5%' '6^' '7&' '8*' '9('};

% ====================
% END DEFAULTS
% ====================

%% Print Title %%
script_name='-- Questionnaires --'; boxTop(1:length(script_name))='=';
fprintf('%s\n%s\n%s\n',boxTop,script_name,boxTop)

if nargin==0
    
    %% Get Subject ID %%
    subjectID = ptb_get_input_string('\nEnter subject ID: ');
    
    %% Setup Input Device(s) %%
    inputDevice = ptb_get_resp_device('Choose Response Device'); % input device
    
    %% Initialize Screen %%
    w = ptb_setup_screen(0,250,theFont,fontsize.item); % setup screen
    
end
resp_set = ptb_response_set(valid_keys); % response set
screenres = w.res(3:4); % screen resolution

%% Compute Position of Scale Points %%
halfres = round(screenres/2);
stepres = round(halfres(1)/6);
xpos.odd = 0:stepres:screenres(1);
xpos.even = 0+stepres/2:stepres:screenres(1);
midpoint = xpos.odd(ceil(length(xpos.odd)/2));
odd.left = xpos.odd(xpos.odd<midpoint);
odd.right = xpos.odd(xpos.odd>midpoint);
even.left = xpos.even(xpos.even<midpoint);
even.right = xpos.even(xpos.even>midpoint);
ystepres = stepres/4;
ypos = halfres(2):ystepres:screenres(2);
ypos(1:2) = [];
ypos = ypos;

%% Initialize Logfile (Scalewise Data Recording) %%
d=clock;
logfile=sprintf('sub%s_ids.log',subjectID);
fprintf('\nA running log of this session will be saved to %s\n',logfile);
fid=fopen(logfile,'a');
if fid<1,error('could not open logfile!');end;
fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));

%% Load Stimuli and Build Scales%%
scalefiles = files([stimdir filesep '*xls']);
for s = 1:length(scalefiles)
    [path name ext] = fileparts(scalefiles{s});
    scales{s}.name = name; 
    [n t r] = xlsread(scalefiles{s}, 'instructions');
    t = strtrim(t);
    t = regexprep(t,'Ò','''''');
    t = regexprep(t,'Ó','''''');
    t = regexprep(t,'Õ','''');
    scales{s}.instructions = t{1};
    [n t r] = xlsread(scalefiles{s}, 'items');
    t = strtrim(t);
    t = regexprep(t,'Ò','''''');
    t = regexprep(t,'Ó','''''');
    t = regexprep(t,'Õ','''');
    scales{s}.items = t(:,3);
    scales{s}.key = n;
    n = length(t);
    scales{s}.rt = zeros(n,1);
    scales{s}.rawresp = zeros(n,1);
    scales{s}.revresp = zeros(n,1);
    [n t r] = xlsread(scalefiles{s}, 'scale');
    scales{s}.scale = r; 
    %% Build Scale
    scalepoints = cell2mat(r(:,1));
    np = length(scalepoints);
    midpoint = ceil(length(xpos.odd)/2);
    if mod(np,2)
        taillength = floor(np/2);
        sx = xpos.odd(midpoint-taillength:midpoint+taillength);
    else
        sxleft = even.left(end-(np/2-1):end);
        sxright = even.right(1:np/2);
        sx = [sxleft sxright];
    end
    for i = 1:np

        Screen('TextSize',w.win,fontsize.scalepoint);
        Screen('DrawText',w.win,num2str(scalepoints(i)),sx(i),ypos(1));
        anchor = scales{s}.scale{i,2};
        anchor = allwords(anchor);
        for a = 1:length(anchor)
            Screen('TextSize',w.win,fontsize.anchor);
            [textbounds, textoffset]= Screen('TextBounds', w.win, anchor{a});
            tsize = textbounds(3);
            tx = sx(i)-tsize/2;
            Screen('DrawText',w.win,anchor{a},tx,ypos(1+a));
        end
        
    end
    scaleTex(s) = Screen('MakeTexture', w.win, Screen('GetImage',w.win,[],'backBuffer'));
    Screen('Flip', w.win);
end
nscales = length(scales);

% ====================
% START TASK
% ====================

%% Wait for Button Press to Start %%
Screen('TextSize',w.win,fontsize.item);
DrawFormattedText(w.win,'Questionnaires\n\n\nPress [spacebar] to begin.','center','center',w.white,fontwrap); Screen('Flip',w.win);
[resp rt] = ptb_get_resp(inputDevice, space);	
Screen('FillRect', w.win, w.black); Screen('Flip', w.win);
WaitSecs(1);

%% Loop Over Scales %%
try
    
    for s = 1:nscales

        cs = scales{s};
        
        %% Present Instructions %%
        Screen('TextSize',w.win,fontsize.item);
        cinstruct = [cs.instructions '\n\n\nPress [spacebar] to begin.'];
        DrawFormattedText(w.win,cinstruct,'center','center',w.white,fontwrap); Screen('Flip',w.win);
        [resp rt] = ptb_get_resp(inputDevice, space);
        Screen('FillRect', w.win, w.black); Screen('Flip', w.win);
        WaitSecs(.5);
        
        %% Loop over items %%
        items = cs.items;
        for i = 1:length(items)
            
            [x y] = ptb_center_position(items{i}, w.win, -(round(halfres(2)/4)));
            Screen('DrawTexture',w.win,scaleTex(s));
            DrawFormattedText(w.win,items{i},'center',y,w.white,fontwrap);
            Screen('Flip',w.win);
            WaitSecs(.25);
            [resp rt] = ptb_get_resp(inputDevice, resp_set);
            scales{s}.rawresp(i) = str2num(resp(1));
            scales{s}.rt(i) = rt;
            Screen('DrawTexture',w.win,scaleTex(s)); Screen('Flip',w.win);
            fprintf(fid,'%d\t%d\t%d\t%2.3f\n',s,i,str2num(resp(1)),rt);
            WaitSecs(.25);
            
        end
        
        % reverse score
        scales{s}.revresp = scales{s}.rawresp;
        idx = find(scales{s}.key(:,2));
        raw = scales{s}.rawresp(idx);
        rev = (1+size(scales{1}.scale,1))-raw;
        scales{s}.revresp(idx) = rev;
        
        Screen('FillRect', w.win, w.black); Screen('Flip', w.win);
        WaitSecs(1.25);

    end

        
catch
    
    Screen('CloseAll');
    Priority(0);
    ShowCursor;
    psychrethrow(psychlasterror);
    
end

%% Save Data to Matlab Variable %%
d=clock;
outfile=sprintf('ids_%s_%s_%02.0f-%02.0f.mat',subjectID,date,d(4),d(5));
try
    save([datadir filesep outfile], 'subjectID', 'scales'); 
catch
	fprintf('couldn''t save %s\n saving to ids.mat\n',outfile);
	save ids
end;

if nargin==0
    %% Exit %%
    Screen('CloseAll');
    Priority(0);
    ShowCursor;
end
fclose(fid);

