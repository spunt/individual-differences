function task_bif(subjectID,inputDevice)
%=========================================================================
% Personality Meaurement
% Bob Spunt
% Social Cognitive Neuroscience Lab (www.scn.ucla.edu)
% University of California, Los Angeles
%=========================================================================
if nargin==0
    %---------------------------------------------------------------
    %% PRINT TITLE TO SCREN
    %---------------------------------------------------------------
    script_name='- Behavior Identification Form -'; boxTop(1:length(script_name))='=';
    fprintf('%s\n%s\n%s\n',boxTop,script_name,boxTop)
    %---------------------------------------------------------------
    %% GET USER INPUT
    %---------------------------------------------------------------

    % get subject ID
    subjectID=input('\nEnter subject ID: ','s');
    while isempty(subjectID)
        disp('ERROR: no value entered. Please try again.');
        subjectID=input('Enter subject ID: ');
    end;

    %---------------------------------------------------------------
    %% SET UP INPUT DEVICES
    %---------------------------------------------------------------
    subdevice_string='- Choose device -'; boxTop(1:length(subdevice_string))='-';
    fprintf('\n%s\n%s\n%s\n',boxTop,subdevice_string,boxTop)
    inputDevice = hid_probe;
end

%---------------------------------------------------------------
%% INITIALIZE SCREENS
%---------------------------------------------------------------
AssertOpenGL;
screens=Screen('Screens');
screenNumber=max(screens);
w=Screen('OpenWindow', screenNumber,0,[],32,2);
[wWidth, wHeight]=Screen('WindowSize', w);
xcenter=wWidth/2;
ycenter=wHeight/2;
priorityLevel=MaxPriority(w);
Priority(priorityLevel);

% colors
grayLevel=0;    
black=BlackIndex(w); % Should equal 0.
white=WhiteIndex(w); % Should equal 255.
Screen('FillRect', w, grayLevel);
Screen('Flip', w);

% text
theFont='Arial';
theFontSize=40;
Screen('TextSize',w,40);
theight = Screen('TextSize', w);
Screen('TextFont',w,theFont);
Screen('TextColor',w,white);
wrapat = 46;

% cues
fixation='+';

% compute default Y position (vertically centered)
numlines = length(strfind(fixation, char(10))) + 1;
bbox = SetRect(0,0,1,numlines*theight);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
PosY = dv;
% compute X position for fixation
bbox=Screen('TextBounds', w, fixation);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
fixPosX = dh;

%---------------------------------------------------------------
%% ASSIGN RESPONSE KEYS
%---------------------------------------------------------------

b1=KbName('1!');
b2=KbName('2@');
b3=KbName('3#');
b4=KbName('4$');
b5=KbName('5%');
b6=KbName('6^');
b7=KbName('7&');
b8=KbName('8*');
b9=KbName('9(');
b1pad=KbName('1');
b2pad=KbName('2');
spacebar=KbName('space');
onetwo = [b1 b2 b1pad b2pad];
one2seven = [b1 b2 b3 b4 b5 b6 b7];
HideCursor;


%---------------------------------------------------------------
%% GET AND LOAD STIMULI
%---------------------------------------------------------------
DrawFormattedText(w, 'LOADING', 'center','center',white,wrapat);
Screen('Flip',w);

% load in stimkey
cd stimuli/bif
[use stims raw] = xlsread('bif_stimuli.xls');
stims(:,2)=[];
stims = stims(find(use),:);
% stim column key
% 1 - source (bif or new)
% 2 - target
% 3 - low-level option
% 4 - high-level option

% single stims
instructTex = Screen('MakeTexture',w,imread('instruct.png'));

cd ../../

%---------------------------------------------------------------
%% iNITIALIZE SEEKER VARIABLE
%---------------------------------------------------------------
% trialcode key
% 1 - trial #
% 2 - stim index
% 3 - first option (0 = low, 1 = high)
% 4 - second option (0 = low, 1 = high)
% 5 - choice  (0 = low, 1 = high)
% 6 - rt (s)
nTrials=length(stims);
Seeker=zeros(nTrials,6);
Seeker(:,1)=1:nTrials;
Seeker(:,2) = randperm(nTrials);
tmp = randperm(nTrials);
Seeker(tmp(1:20),3) = 1;
Seeker(Seeker(:,3)==0,4) = 1;

%---------------------------------------------------------------
% INSTRUCTIONS
%---------------------------------------------------------------
Screen('FillRect', w, grayLevel);
Screen('Flip', w);
WaitSecs(0.25);
Screen('DrawTexture',w, instructTex);
Screen('Flip',w);
noresp=1;
while noresp
    [keyIsDown,secs,keyCode]=KbCheck(inputDevice);
    if keyIsDown && keyCode(spacebar)
        noresp=0;
        Screen('FillRect', w, grayLevel);
        Screen('Flip', w);
    end
    WaitSecs(0.001);
end
WaitSecs(1);

%---------------------------------------------------------------
%% TRIAL PRESENTATION
%---------------------------------------------------------------
try

    for t=1:nTrials
    
        cstims = stims(Seeker(t,2),2:4);
        target = cstims{1};
        option1 = cstims{Seeker(t,3)+2};
        option2 = cstims{Seeker(t,4)+2};
%     presentThis = [target '\n\n1:  ' option1 '\n2:  ' option2];
%     DrawFormattedText_new(w,presentThis,xcenter-225,'center',white,1600, 0, 0);
        Screen('TextSize',w,48);
        DrawFormattedText(w,target,xcenter-225,'center',white,wrapat);
        Screen('TextSize',w,40);
        DrawFormattedText(w,['\n\n\n\n1:  ' option1 '\n2:  ' option2],xcenter-225,'center',white,wrapat);
%         presentThis = [target '\n\n1: ' option1 '         2: ' option2];
%         DrawFormattedText_new(w,presentThis,'center','center',white,1600, 0, 0);
        Screen('Flip',w);
        stimStart=GetSecs;
        WaitSecs(.25);
        noresp = 1;
        while noresp
            [keyIsDown,secs,keyCode]=KbCheck(inputDevice);
            keyPressed = find(keyCode);
            if keyIsDown && ismember(keyPressed,onetwo)
                noresp=0;
                Seeker(t,6)=secs-stimStart;
                Screen('FillRect', w, grayLevel);
                Screen('Flip', w);
                tmp = KbName(keyPressed);
                choice = str2double(tmp(1));
                if (choice==1 && Seeker(t,3)==1) || (choice==2 && Seeker(t,4)==1)
                    Seeker(t,5) = 1;
                end
            end
            WaitSecs(.001);
        end
        WaitSecs(.25)
        
end;    % end of trial loop

catch
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
end;

%---------------------------------------------------------------
%% SAVE DATA
%---------------------------------------------------------------
d=clock;
outfile=sprintf('bif_%s_%s_%02.0f-%02.0f.mat',subjectID,date,d(4),d(5));
cd data
try
    save(outfile, 'Seeker','subjectID');
catch
	fprintf('couldn''t save %s\n saving to dst_behav.mat\n',outfile);
	save dst_behav
end;
cd ..

bob_sendemail('bobspunt@gmail.com','lois behav backup - bif','attached',['data' filesep outfile])

instructCUE3='You are done with the the Behavior Identification Task. Press any key to move on to the next part.';
DrawFormattedText(w, instructCUE3, 'center','center',white ,wrapat);
Screen('Flip',w);

noresp=1;
while noresp
    [keyIsDown,secs,keyCode]=KbCheck(inputDevice);
    if keyIsDown
        noresp=0;
    end
WaitSecs(.001);
end


if nargin==0
%---------------------------------------------------------------
%% CLOSE SCREENS
%---------------------------------------------------------------
Screen('CloseAll');
Priority(0);
ShowCursor;
end
