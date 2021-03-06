function LickingGNG_FalseFrequencies
global BpodSystem
global Amount
%% Create trial manager object
TrialManager = TrialManagerObject;
%% Octaves by 1/8 spacing for reference
% [4000, 4362, 4756, 5187, 5657, 6169, 6727, 7336, 8000, 8724, 9514]
%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    S.GUI.RewardAmount = 3.5; % ul % due to calibration for output
    S.GUI.SoundDuration = 0.1; % duration of sound
    S.GUI.SinWaveFreqGo = 4756; % Frequency of go cue
    S.GUI.SinWaveFreqNoGo = 8000; % Frequency of no-go cue
    S.GUI.SinWaveFreqGoFalse = 5187; % Frequency of no-go cue
    S.GUI.SinWaveFreqNoGoFalse = 7336; 
    S.GUI.SinWaveFreqMiddle = 6169; % 3/8 octave from 4756 (halfway between our go and no-go)
    S.GUIPanels.Sound = {'SinWaveFreqGo', 'SinWaveFreqNoGo', 'SoundDuration'}; % Labels for sound panel
end
Amount = S.GUI.RewardAmount;

%% Define trials
MaxTrials = 1000; % max trials
n = 5; % first n trials are GO (Type 1)
randomize = RandStream('mlfg6331_64'); % randomize stream of numbers for sampling later
TrialTypes = []; % initalize empty array for trial types
for i = 1:50 % 50 groups of 20 trials, each 20 trials is balanced
    TrialTypes(i,:) = datasample(randomize, [1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 3 4 5],20,'Replace',false); % numbers specify balanced trial types
end
TrialTypes = TrialTypes'; % transpose array holding trial tyeps
TrialTypes(1:n) = 1; % overwrites first n trials
BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
tic; % starts timer
%% Initialize plots
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [10 750 2000 400],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off'); % Initializes figure for Outcome plot
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .9 .6]); % Initializes axes for Outcome plot
TrialTypeOutcomePlot_Frequencies(BpodSystem.GUIHandles.OutcomePlot,'init',TrialTypes) % 'ntrials',MaxTrials); % Initializes Outcome plot
% GUI plugin displays the settings from the "GUI" subfield of a settings struct.
BpodParameterGUI('init', S); % Initialize parameter GUI plugin--Creates a user interface for viewing and manual override
% Initialize performance graph
figure('Name','OutcomesGraph','NumberTitle','off', 'Position', [1250 100 500 600]); % open appropriate figure
b = categorical({'Hits','Miss','CR', 'FA'}); c = reordercats(b, {'Hits', 'Miss', 'CR', 'FA'}); % set x-axis
subplot(2,1,1); % graph 1
hit = 0; miss = 0; cr = 0; fa =0; % initalizes numbers of hits, miss, cr, fa to 0
z = [0 0 0 0]; % initiates array of graph
OutcomesGraph = bar(gca,c , z); title('Reinforcement'); xlabel('Outcome'); ylabel('% Correct'); ylim([0 110]); yticks(0:10:110); % Performance figure
numHit = text(1:length(c(1)),z(1),num2str(hit),'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2,1,1); % initializes numbers above bar
numMiss = text(2,z(2), num2str(miss), 'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2,1,1); % initializes numbers above bar
numCR = text(3,z(3), num2str(cr), 'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2,1,1); % initializes numbers above bar
numFA = text(4,z(4), num2str(fa), 'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2,1,1); % initializes numbers above bar
subplot(2, 1, 2); % graph 2
goIn = 0; goOut = 0; noGoIn = 0; noGoOut =0; middleIn = 0; middleOut = 0; % initializes numbers of ins and outs for false go, nogo and middle tones
z2 = [0 0 0 0 0 0]; % initiates array of graph
b = categorical({'GO-In','Go-Out','NoGo-In', 'NoGo-Out', 'MiddleIn', 'MiddleOut'}); c = reordercats(b, {'GO-In','Go-Out','NoGo-In', 'NoGo-Out', 'MiddleIn', 'MiddleOut'}); % set x-axis
ProbeGraph = bar(gca, c, z2); title('Probe'); xlabel('Outcome'); ylabel('% Correct'); ylim([0 110]); yticks(0:10:110); % performance in probe
numGoIn= text(1:length(c(1)),z2(1),num2str(goIn),'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2, 1, 2); % initializes numbers above bar
numGoOut = text(2,z2(2), num2str(goOut), 'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2, 1, 2); % initializes numbers above bar
numNoGoIn = text(3, z2(3),num2str(noGoIn),'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2, 1, 2); % initializes numbers above bar
numNoGoOut = text(4,z2(4), num2str(noGoOut), 'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2, 1, 2); % initializes numbers above bar
numMiddleIn = text(5, z2(5), num2str(middleIn),'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2, 1, 2); % initializes numbers above bar
numMiddleOut = text(6, z2(6), num2str(middleOut),'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2, 1, 2); % initializes numbers above bar
%% Define stimuli and send to sound server
S.SF = 192000; % Sound card sampling rate
% Program sound server
PsychToolboxSoundServer('init')
% Set soft code handler to trigger sounds
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';
sma = PrepareStateMachine(S, TrialTypes, 1, []); % Prepare state machine for trial 1 with empty "current events" variable
TrialManager.startTrial(sma); % Sends & starts running first trial's state machine. A MATLAB timer object updates the 
                              % console UI, while code below proceeds in parallel.
% In this case, we don't need trial events to build the state machine - but
% they are available in currentTrialEvents.
%% Main trial loop
for currentTrial = 1:MaxTrials
    currentTrialEvents = TrialManager.getCurrentEvents({'WaitForLick', 'OpenValve'}); % Hangs here until Bpod enters one of the listed trigger states, then returns current trial's states visited + events captured to this point
    if BpodSystem.Status.BeingUsed == 0; return; end % If user hit console "stop" button, end session 
    [sma, S] = PrepareStateMachine(S, TrialTypes, currentTrial+1, currentTrialEvents); % Prepare next state machine.
    % Since PrepareStateMachine is a function with a separate workspace, pass any local variables needed to make 
    % the state machine as fields of settings struct S e.g. S.learningRate = 0.2.
    SendStateMachine(sma, 'RunASAP'); % With TrialManager, you can send the next trial's state machine while the current trial is ongoing
    RawEvents = TrialManager.getTrialData; % Hangs here until trial is over, then retrieves full trial's raw data
    if BpodSystem.Status.BeingUsed == 0; return; end % If user hit console "stop" button, end session 
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    TrialManager.startTrial(sma); % Start processing the next trial's events (** can call with no argument since SM was already sent)
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned from last trial, update plots and save data
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        UpdateOutcomePlot(TrialTypes, BpodSystem.Data); % Updates tracker plot
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end  
    % Updates performance graphs
    if TrialTypes(currentTrial) == 3 & ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.NeutralIn) % FalseGoTone and In
        goIn = goIn+1; % updates number of Ins in probe for False go tone
        z2=[((goIn/(goIn+ goOut))*100) ((goOut/(goIn+goOut))*100) z2(3) z2(4) z2(5) z2(6)]; % updates percentage difference between Ins and Outs
        set(ProbeGraph, 'YData', z2); % Updates probe performance plot
    elseif TrialTypes(currentTrial) == 3 & ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.NeutralOut) % FalseGoTone and Out
        goOut = goOut +1; % update num of outs in probe for false go tone
        z2=[((goIn/(goIn+ goOut))*100) ((goOut/(goIn+goOut))*100) z2(3) z2(4) z2(5) z2(6)]; % updates percentage difference between Ins and Outs
        set(ProbeGraph, 'YData', z2); % Update probe performance plot
    elseif TrialTypes(currentTrial) == 4 & ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.NeutralIn) % FalseNoGoTone and In
        noGoIn = noGoIn +1; % update num of Ins in probe for false nogo tone
        z2=[z2(1) z2(2) ((noGoIn/(noGoIn+noGoOut))*100) ((noGoOut/(noGoIn+noGoOut))*100) z2(5) z2(6)]; % updates percentage difference between Ins and Outs
        set(ProbeGraph, 'YData', z2); % Update probe performance plot
    elseif TrialTypes(currentTrial) == 4 & ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.NeutralOut) % FalseNoGoTone and Out
        noGoOut = noGoOut +1; % update num of outs in probe for false no go tone
        z2=[z2(1) z2(2) ((noGoIn/(noGoIn+noGoOut))*100) ((noGoOut/(noGoIn+noGoOut))*100) z2(5) z2(6)]; % updates percentage difference between Ins and Outs
        set(ProbeGraph, 'YData', z2); % Update probe performance plot
    elseif TrialTypes(currentTrial) == 5 & ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.NeutralIn) % MiddleTone and In
        middleIn = middleIn +1; % update num of  ins in probe for middle tone
        z2=[z2(1) z2(2) z2(3) z2(4) ((middleIn/(middleIn+middleOut))*100) ((middleOut/(middleIn+middleOut))*100)]; % updates percentage difference between Ins and Outs
        set(ProbeGraph, 'YData', z2); % Update probe performance plot
    elseif TrialTypes(currentTrial) == 5 & ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.NeutralOut) % MiddleTone and Out
        middleOut = middleOut +1; % update num of outs in probe for middle tone
        z2=[z2(1) z2(2) z2(3) z2(4) ((middleIn/(middleIn+middleOut))*100) ((middleOut/(middleIn+middleOut))*100)]; % updates percentage difference between Ins and Outs
        set(ProbeGraph, 'YData', z2); % Update probe performance plot
    elseif  ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.OpenValve)
        hit = hit +1; % update num of hits
        z=[((hit/(hit+miss))*100) ((miss/(hit+miss))*100) z(3) z(4)]; % change percentage difference between hit and miss
        set(OutcomesGraph, 'YData', z); % Update reinforcement performance plot
    elseif TrialTypes(currentTrial) == 1 % go
        miss = miss +1; % update num of misses
        z=[((hit/(hit+miss))*100) ((miss/(hit+miss))*100) z(3) z(4)]; % change percentage difference between hit and miss
        set(OutcomesGraph, 'YData', z); % Update reinforcement performance plot
    elseif TrialTypes(currentTrial) == 2 & ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.CorrectReject) % If no-go and correct reject
        cr = cr +1; % update num of correct rejects
        z = [z(1) z(2) ((cr/(cr+fa))*100) ((fa/(fa+cr))*100)]; % change percentage difference between false alarm and correct rejects
        set(OutcomesGraph, 'YData', z); % Update reinforcement performance plot
    elseif TrialTypes(currentTrial) == 2 % no go
        fa = fa+1; % update num of false alarms
        z = [z(1) z(2) ((cr/(cr+fa))*100) ((fa/(fa+cr))*100)]; % change percentage difference between false alarm and correct rejects
        set(OutcomesGraph, 'YData', z); % Update reinforcement performance plot
    end
% Update numbers of hit, misses, cr, and false alarms above each bin in performance graphs (deletes previous, updates number in specific plot)    
% Also updates numbers of Ins and outs per every frequency change above each bin in probe graph (deletes previous, updates number in specific plot)    
delete(numGoIn); subplot(212); numGoIn = text(1:length(c(1)),z2(1),num2str(goIn),'vert','bottom','horiz','center'); 
delete(numGoOut);subplot(212); numGoOut = text(2,z2(2), num2str(goOut), 'vert', 'bottom', 'horiz', 'center');
delete(numNoGoIn);subplot(212);numNoGoIn = text(3,z2(3), num2str(noGoIn), 'vert', 'bottom', 'horiz', 'center');
delete(numNoGoOut);subplot(212);numNoGoOut = text(4,z2(4), num2str(noGoOut), 'vert', 'bottom', 'horiz', 'center');
delete(numMiddleIn);subplot(212);numMiddleIn = text(5,z2(5), num2str(middleIn), 'vert', 'bottom', 'horiz', 'center');
delete(numMiddleOut);subplot(212);numMiddleOut = text(6,z2(6), num2str(middleOut), 'vert', 'bottom', 'horiz', 'center');
delete(numHit);subplot(211);numHit = text(1:length(c(1)),z(1),num2str(hit),'HorizontalAlignment','center','VerticalAlignment','bottom');
delete(numMiss);subplot(211);numMiss = text(2,z(2), num2str(miss), 'vert', 'bottom', 'horiz', 'center');
delete(numCR);subplot(211);numCR = text(3,z(3), num2str(cr), 'vert', 'bottom', 'horiz', 'center');
delete(numFA);subplot(211);numFA = text(4,z(4), num2str(fa), 'vert', 'bottom', 'horiz', 'center');
end
function [sma, S] = PrepareStateMachine(S, TrialTypes, currentTrial, ~)
sma = NewStateMatrix(); % Assemble state matrix
GoFreq = GenerateSineWave(S.SF, S.GUI.SinWaveFreqGo, S.GUI.SoundDuration); % Sampling freq (hz), Sine frequency (hz), duration (s)
NoGoFreq = GenerateSineWave(S.SF, S.GUI.SinWaveFreqNoGo, S.GUI.SoundDuration); % Sampling freq (hz), Sine frequency (hz), duration (s)

FalseGoFreq = GenerateSineWave(S.SF, S.GUI.SinWaveFreqGoFalse, S.GUI.SoundDuration); % Sampling freq (hz), Sine frequency (hz), duration (s)
FalseNoGoFreq = GenerateSineWave(S.SF, S.GUI.SinWaveFreqNoGoFalse, S.GUI.SoundDuration); % Sampling freq (hz), Sine frequency (hz), duration (s)
MiddleFreq = GenerateSineWave(S.SF, S.GUI.SinWaveFreqMiddle, S.GUI.SoundDuration); % Sampling freq (hz), Sine frequency (hz), duration (s)

PsychToolboxSoundServer('Load', 1, GoFreq); % Load specified sound within trial
PsychToolboxSoundServer('Load', 2, NoGoFreq); % Load specified sound within trial
PsychToolboxSoundServer('Load', 3, FalseGoFreq); % Load specified sound within trial
PsychToolboxSoundServer('Load', 4, FalseNoGoFreq); % Load specified sound within trial
PsychToolboxSoundServer('Load', 5, MiddleFreq); % Load specified sound within trial

S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
R = GetValveTimes(S.GUI.RewardAmount, 1); ValveTime = R;  % Update reward amounts
switch TrialTypes(currentTrial) % Determine trial-specific state matrix fields
    case 1 % GO trial
        Stimulus = 1; % GoTone
        INResponse = 'OpenValve';
        NOResponse = 'Miss';
    case 2 % No-Go trial
        Stimulus = 2; %NoGoTone
        INResponse = 'Punish';
        NOResponse = 'CorrectReject'; 
    case 3 % False GO trial
        Stimulus = 3; % False Go tone
        INResponse = 'NeutralIn'; % State that records the mouse licked
        NOResponse = 'NeutralOut'; % state that records the mouse withheld licking
    case 4 % False NOGO trial
        Stimulus = 4; % False NoGo tone
        INResponse = 'NeutralIn'; % State that records the mouse licked
        NOResponse = 'NeutralOut'; % state that records the mouse withheld licking
    case 5 % False Middle trial
        Stimulus = 5; % False middle tone
        INResponse = 'NeutralIn'; % State that records the mouse licked
        NOResponse = 'NeutralOut'; % state that records the mouse withheld licking
end
sma = AddState(sma, 'Name', 'PreTrial', ... % Pre trial period ensuring no activity for 2 seconds
    'Timer', 2, ...
    'StateChangeConditions', {'Tup', 'Stimulus', 'Port1In', 'Stop'}, ... % if no action, stimulus activated; if action, stop period
    'OutputActions', {}); 
sma = AddState(sma, 'Name', 'Stop', ... % Stop period to assure no activity during Pre-Trial
    'Timer', 0, ...
    'StateChangeConditions', {'Tup', 'PreTrial'}, ... % returns to PreTrial
    'OutputActions', {}); 
sma = AddState(sma, 'Name', 'Stimulus', ... % Tone
    'Timer', S.GUI.SoundDuration, ...
    'StateChangeConditions', {'Tup', 'Dead'}, ...
    'OutputActions', {'SoftCode', Stimulus});  
sma = AddState(sma, 'Name', 'Dead', ... % 100ms dead period
    'Timer', .1, ...
    'StateChangeConditions', {'Tup', 'WaitForLick'}, ...
    'OutputActions', {}); 
sma = AddState(sma, 'Name', 'WaitForLick', ... % Response period
    'Timer', 2, ... 
    'StateChangeConditions', {'Port1In', INResponse, 'Tup', NOResponse},... % If lick, then open valve to reward. If no lick, miss period
    'OutputActions', {}); 
sma = AddState(sma, 'Name', 'OpenValve', ... % Open valve for reward
    'Timer', ValveTime,...
    'StateChangeConditions', {'Tup', 'Drinking'},...
    'OutputActions', {'ValveState', 1}); 
sma = AddState(sma, 'Name', 'Drinking', ... % 4 seconds for drinking
    'Timer', 4,...
    'StateChangeConditions', {'Tup', 'ITI'},...
    'OutputActions', {}); 
sma = AddState(sma, 'Name', 'Miss', ... % 2 second time out for miss
    'Timer', 2,...
    'StateChangeConditions', {'Tup', 'exit'}, ...
    'OutputActions', {}); 
sma = AddState(sma, 'Name', 'CorrectReject', ... % 2 second correct reject state
    'Timer', 2,...
    'StateChangeConditions', {'Tup', 'ITI'}, ...
    'OutputActions', {}); 
sma = AddState(sma, 'Name', 'Punish', ... % 7 second punish state
    'Timer', 7,...
    'StateChangeConditions', {'Tup', 'ITI'}, ...
    'OutputActions', {}); 
sma = AddState(sma, 'Name', 'NeutralIn', ... % 2 second time out for miss
    'Timer', 2,...
    'StateChangeConditions', {'Tup', 'exit'}, ...
    'OutputActions', {}); 
sma = AddState(sma, 'Name', 'NeutralOut', ... % 2 second time out for miss
    'Timer', 2,...
    'StateChangeConditions', {'Tup', 'exit'}, ...
    'OutputActions', {}); 
sma = AddState(sma, 'Name', 'ITI', ... % Tup Action
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'exit'},... % exits trial
    'OutputActions', {}); 

function UpdateOutcomePlot(TrialTypes, Data)
global BpodSystem
Outcomes = zeros(1,Data.nTrials);% Creates a vector for each completed trial, listing outcomes
for x = 1:Data.nTrials
    if ~isnan(Data.RawEvents.Trial{x}.States.OpenValve)
        Outcomes(x) = -1; % green circle for hits
    elseif TrialTypes(x) == 1 % go
        Outcomes(x) = 1; % green x for Miss
    elseif TrialTypes(x) == 2 & ~isnan(Data.RawEvents.Trial{x}.States.CorrectReject) % If no-go and correct reject
        Outcomes(x) = 2; % unfilled green circle for Correct Rejects
    elseif ~isnan(Data.RawEvents.Trial{x}.States.NeutralIn)
        Outcomes(x) = -1;
    elseif TrialTypes(x) == 2 % no go
        Outcomes(x) = 0; % red X for false alarm
    end
end
TrialTypeOutcomePlot_Frequencies(BpodSystem.GUIHandles.OutcomePlot,'update',Data.nTrials+1,TrialTypes,Outcomes);
