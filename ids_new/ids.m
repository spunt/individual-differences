function ids(test_tag)

if nargin<1, test_tag = 0; end

%% Check for Psychtoolbox %%
try
    ptbVersion = PsychtoolboxVersion;
catch
    url = 'https://psychtoolbox.org/PsychtoolboxDownload';
    fprintf('\n\t!!! WARNING !!!\n\tPsychophysics Toolbox does not appear to on your search path!\n\tSee: %s\n\n', url);
    return
end

%% Print Title %%
script_name='----------- Questionnaires -----------'; boxTop(1:length(script_name))='=';
fprintf('\n%s\n%s\n%s\n',boxTop,script_name,boxTop)

defaults = ids_defaults;
KbName('UnifyKeyNames');
startkey = KbName(defaults.startkey);
startkeymsg = sprintf('Press the %s key to begin.', upper(defaults.startkey)); 
addpath(defaults.path.utilities); 

%% Get Subject ID %%
if ~test_tag
    subjectID = ptb_get_input_string('\nEnter Subject ID: ');
else
    subjectID = 'TEST';
end

%% Setup Input Device(s) %%
switch upper(computer)
  case 'MACI64'
    inputDevice = ptb_get_resp_device;
  case {'PCWIN','PCWIN64'}
    % JMT:
    % Do nothing for now - return empty chosen_device
    % Windows XP merges keyboard input and will process external keyboards
    % such as the Silver Box correctly
    inputDevice = [];
  otherwise
    % Do nothing - return empty chosen_device
    inputDevice = [];
end

%% Initialize Screen %%
try
    w = ptb_setup_screen(0,250,defaults.font.name,defaults.font.item, defaults.screenres); % setup screen
catch
    disp('Could not change to recommend screen resolution. Using current.');
    w = ptb_setup_screen(0,250,defaults.font.name,defaults.font.item);
end

%% Compute Position of Scale Points %%
screenres  = w.res(3:4); % screen resolution
halfres    = round(screenres/2);
stepres    = round(halfres(1)/6);
xpos.odd   = 0:stepres:screenres(1);
xpos.even  = 0+stepres/2:stepres:screenres(1);
midpoint   = xpos.odd(ceil(length(xpos.odd)/2));
odd.left   = xpos.odd(xpos.odd<midpoint);
odd.right  = xpos.odd(xpos.odd>midpoint);
even.left  = xpos.even(xpos.even<midpoint);
even.right = xpos.even(xpos.even>midpoint);
ystepres   = stepres/4;
ypos       = halfres(2):ystepres:screenres(2);
ypos(1:2)  = [];
ypos       = ypos;

%% Initialize Logfile (Scalewise Data Recording) %%
d       = clock;
logfile = fullfile(defaults.path.data, sprintf('LOG_ids_sub%s.txt', subjectID));
fprintf('\nA running log of this session will be saved to %s\n',logfile);
fid     = fopen(logfile,'a');
if fid<1,error('could not open logfile!'); end;
fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));

%% Load Stimuli and Build Scales%%
searchpat   = fullfile(defaults.path.scales, sprintf('*%s', defaults.path.scaleext)); 
scalefiles  = files(searchpat);
for s = 1:length(scalefiles)

    % | Scale Name
    [path name ext] = fileparts(scalefiles{s});
    scales{s}.name  = name; 

    % | Instructions
    t = readfile(scalefiles{s}, 'instructions');
    scales{s}.instructions = t{1};

    % | Items
    t = readfile(scalefiles{s}, 'items');
    scales{s}.items   = strtrim(t(:,3));
    scales{s}.key     = cell2mat(t(:,1:2)); 
    nitem             = length(scales{s}.items);
    scales{s}.rt      = zeros(nitem,1);
    scales{s}.rawresp = zeros(nitem,1);
    scales{s}.revresp = zeros(nitem,1);

    % | Scale
    t               = readfile(scalefiles{s}, 'scale');
    scales{s}.scale = t;
    scalepoints     = cell2mat(t(:,1));
    np              = length(scalepoints);
    midpoint        = ceil(length(xpos.odd)/2);
    if mod(np,2)
        taillength = floor(np/2);
        sx         = xpos.odd(midpoint-taillength:midpoint+taillength);
    else
        sxleft     = even.left(end-(np/2-1):end);
        sxright    = even.right(1:np/2);
        sx         = [sxleft sxright];
    end
    for i = 1:np

        Screen('TextSize',w.win,defaults.font.scalepoint);
        Screen('DrawText',w.win,num2str(scalepoints(i)),sx(i),ypos(1));
        anchor = scales{s}.scale{i,2};
        anchor = allwords(anchor);
        for a = 1:length(anchor)
            Screen('TextSize',w.win,defaults.font.anchor);
            [textbounds, textoffset] = Screen('TextBounds', w.win, anchor{a});
            tsize                    = textbounds(3);
            tx                       = sx(i)-tsize/2;
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
Screen('TextSize',w.win,defaults.font.item);
DrawFormattedText(w.win, ['Questionnaires\n\n\n' startkeymsg],'center','center',w.white,defaults.font.wrap); Screen('Flip',w.win);
[resp, rt] = ptb_get_resp(inputDevice, defaults.startkey);
Screen('FillRect', w.win, w.black); Screen('Flip', w.win);
WaitSecs(defaults.interscale);

%% Loop Over Scales %%
try
    
    for s = 1:nscales

        cs = scales{s};
        
        %% Present Instructions %%
        Screen('TextSize',w.win,defaults.font.item);
        cinstruct = [cs.instructions '\n\n\n' startkeymsg];
        DrawFormattedText(w.win,cinstruct,'center','center',w.white,defaults.font.wrap); Screen('Flip',w.win);
        [resp rt] = ptb_get_resp(inputDevice, defaults.startkey);
        Screen('FillRect', w.win, w.black); Screen('Flip', w.win);
        WaitSecs(.50);
        
        %% Loop over items %%
        items = cs.items;

        %% IF test, do first and last items only %%
        if test_tag, items = items([1 end]); end;
        for i = 1:length(items)
            
            [x y] = ptb_center_position(items{i}, w.win, -(round(halfres(2)/4)));
            Screen('DrawTexture',w.win,scaleTex(s));
            DrawFormattedText(w.win,items{i},'center',y,w.white,defaults.font.wrap);
            Screen('Flip',w.win);
            WaitSecs(defaults.ignoreDur);
            
            [resp rt] = ptb_get_resp(inputDevice, defaults.valid_keys(scalepoints));
            scales{s}.rawresp(i) = str2num(resp(1));
            scales{s}.rt(i) = rt;
            Screen('DrawTexture',w.win,scaleTex(s)); Screen('Flip',w.win);
            fprintf(fid,'%d\t%d\t%d\t%2.3f\n',s,i,str2num(resp(1)),rt);
            WaitSecs(defaults.interitem);
            
        end
        
        % reverse score
        scales{s}.revresp      = scales{s}.rawresp;
        idx                    = find(scales{s}.key(:,2));
        raw                    = scales{s}.rawresp(idx);
        rev                    = (1+size(scales{1}.scale,1))-raw;
        scales{s}.revresp(idx) = rev;
        
        Screen('FillRect', w.win, w.black); Screen('Flip', w.win);
        WaitSecs(defaults.interscale);

    end

        
catch
    
    ptb_exit;
    rmpath(defaults.path.utilities);
    psychrethrow(psychlasterror);
    
end

%% Save Data to Matlab Variable %%
d=clock;
outfile=sprintf('ids_%s_%s_%02.0f-%02.0f.mat',subjectID,date,d(4),d(5));
try
    save([defaults.path.data filesep outfile], 'subjectID', 'scales');
catch
	fprintf('couldn''t save %s\n saving to ids.mat\n',outfile);
	save ids.mat
end;

%% End of Test Screen %%
DrawFormattedText(w.win,'TASK COMPLETE\n\nPress any key to exit.','center','center',w.white,defaults.font.wrap);
Screen('Flip', w.win);
ptb_any_key;

%% Exit %%
ptb_exit;
rmpath(defaults.path.utilities);

end
% =========================================================================
%
% ------------------------------ SUBFUNCTIONS -----------------------------
%
% =========================================================================
function out            = readfile(in, worksheet, donum2str)
% READFILE (Try to) read contents of file
%
% USAGE: readfile(in, [worksheet])
%
%       in:         input filename
%       worksheet:  (optional) name of worksheet
%
if nargin<1, error('USAGE: readfile(in, [worksheet])'); end
if nargin<2, worksheet = []; end
if nargin<3, donum2str = 0; end
if iscell(in), in = char(in); end
[~,~,ext] = fileparts(in);
switch ext
    case '.csv'
        
        out = csv2cell(in);
        
    case {'.xlsx' '.xls'}
        
        if isempty(worksheet) 
            [~, ~, out] = xlsread(in);
        else
            [~, ~, out] = xlsread(in, worksheet); 
        end
        
    otherwise
        
        try
            out = textfile2cell(in); 
        catch err
            fprintf('COULD NOT READ FILE => %s', err.message);
            printstruct(err.stack);
        end
        
end
if donum2str, out = cellnum2str(out); end
out = cleanupout(out);
% out = strtrim(out);
end
function csvmat         = csv2cell(csv_fname,delimiter)
if nargin<2,
    delimiter=',';
else
    if ~ischar(delimiter)
        error('Specified delimiter needs to be a character.');
    elseif length(delimiter)>1
        error('Delimiter needs to be a single character.');
    end
end
[fid, msg]=fopen(csv_fname,'r');
if fid==-1,
   error('Cannot open %s because: %s.\n',csv_fname,msg);
end
csvmat=cell(1,1);
row_ct=1;
col_ct=1;
while 1
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    while ~isempty(tline),
        [t, tline]=parse_by_char(tline,delimiter);
        csvmat{row_ct,col_ct}=t;
        col_ct=col_ct+1;
    end
    col_ct=1;
    row_ct=row_ct+1;
end
fclose(fid);
end
function [pre,post]     = parse_by_char(str,delimiter)
char_ids=find(str==delimiter);
if isempty(char_ids),
    pre=str;
    post=[];
else
    pre=str(1:char_ids(1)-1);
    post=str(char_ids(1)+1:end);
end
end
function out            = cleanupout(out)
%     out(cellfun(@isnumeric,out)) = cellfun(@num2str,out(cellfun(@isnumeric,out)),'UniformOutput',false);
    out(cellfun('isempty',out)) = {''};
    out(nanmean(strcmp(out','NaN'))==1,:) = [];
    out(strcmp(out, 'NaN')) = {''};
end
function allcell        = textfile2cell(textfile)
    if nargin < 1, disp('USAGE: allcell = textfile2cell(textfile)'); end
    if ischar(textfile), textfile = cellstr(textfile); end
    space = repmat({' '}, 4, 1);
    allcell = [];
    for i = 1:length(textfile)
        fid         = fopen(textfile{i},'r+');
        lncount     = 1;
        cline       = fgetl(fid);
        if cline < 0, continue; end
        while ischar(cline) && ~strcmp(cline, '.END_BOARD_OUTLINE');
            mcell{lncount}  = cline;
            pline           = cline;
            cline           = fgetl(fid);
            lncount         = lncount + 1;
        end
        if size(mcell,2) > 1, mcell = mcell'; end
        allcell = [allcell; mcell; space];
        fclose(fid);
    end

end
function out            = cellnum2str(in, ndec, leftzeropad)
    % CELLNUM2STR 
    %
    %  USAGE: out = cellnum2str(in, ndec, leftzeropad)
    % __________________________________________________________________________
    %  INPUTS
    %   in:     numeric cell array
    %   ndec:   number of decimal points to display
    %

    % ---------------------- Copyright (C) 2015 Bob Spunt ----------------------
    %   Created:  2015-01-13
    %   Email:    spunt@caltech.edu
    % __________________________________________________________________________
    if nargin < 1, mfile_showhelp; return; end
    if nargin < 2, ndec = 3; end
    if nargin < 3, leftzeropad = 1; end
    if ~iscell(in), error('Input array must be cell!'); end
    numidx                  = cell2mat(cellfun(@isnumeric, in, 'Unif', false))==1;
    out                     = in;
    innum                   = in(numidx);
    decidx                  = mod(cell2mat(innum), 1) > 0;
    outnum                  = innum;
    outnum(~decidx)         = cellfun(@num2str, innum(~decidx), 'Unif', false);
    outnum(decidx)          = cellfun(@num2str, innum(decidx), repmat({['%2.' num2str(ndec) 'f']}, size(innum(decidx))), 'Unif', false);
    if ~leftzeropad, outnum = regexprep(outnum, '0\.', '\.'); end
    out(numidx)             = outnum;
end
