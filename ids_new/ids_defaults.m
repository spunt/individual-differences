function defaults = ids_defaults
% DEFAULTS  Defines defaults for Why/How Localizer Task
%
% You can modify the values below to suit your particular needs. Note that
% some combinations of modifications may not work, so if you do modify
% anything, make sure to do a test run before running a subject.
%
%__________________________________________________________________________
% Copyright (C) 2014  Bob Spunt, Ph.D.

% Paths
%==========================================================================
defaults.path.base          = fileparts(mfilename('fullpath'));
defaults.path.data          = fullfile(defaults.path.base, 'data');
defaults.path.utilities     = fullfile(defaults.path.base, 'ptb-utilities');
defaults.path.scales        = fullfile(defaults.path.base, 'stimuli');
defaults.path.scaleext      = '.xlsx';

% Screen Resolution
%==========================================================================
defaults.screenres      = [1024 768];  % recommended screen resolution (if
                                        % not supported by monitor, will
                                        % default to current resolution)

% Response Keys
%==========================================================================
defaults.escape      = 'ESCAPE'; % escape key (to exit early)
defaults.startkey    = 'space'; % key to advance task
defaults.valid_keys  = {'1!' '2@' '3#' '4$' '5%' '6^' '7&' '8*'  '9('}; %    valid response keys

% Text
%==========================================================================
defaults.font.name          = 'Arial'; % default font
defaults.font.item          = 36; % default font size (bigger)
defaults.font.scalepoint    = 22; % default font size (bigger)
defaults.font.anchor        = 16; % default font size (bigger)
defaults.font.wrap          = 48; % default font wrapping (arg to DrawFormattedText)
defaults.font.linesep       = 3;  % spacing between first and second lines of question cue

% Timing (specify all in seconds)
%==========================================================================
defaults.interitem      = 0.25;     % dur of interval between stimuli within blocks
defaults.interscale     = 1;        % dur of interval between question and first trial of each block
defaults.ignoreDur      = 0.25;     % dur after trial presentation in which
                                    % button presses are ignored (this is
                                    % useful when participant provides a late
                                    % response to the previous trial)
end


