function Light2AFC
global BpodSystem
%% Create trial manager object
TrialManager = TrialManagerObject;
%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    S.GUI.RewardAmount = 5; %ul
end
%% Define trial types
MaxTrials = 20; % max trials
S.context = ones(MaxTrials, 1); %1 = reinforced context, licktube in
S.context(11:20) = 0; % 0 = probe context, licktube out
TrialTypes = ceil(rand(1,MaxTrials)*2); % randomize Go and No-go trials
BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
tic; % starts a timer

%% Initialize
BpodParameterGUI('init', S); % Initialize parameter GUI plugin   
sma = PrepareStateMachine(S, TrialTypes, 1, []); % Prepare state machine for trial 1 with empty "current events" variable
TrialManager.startTrial(sma); % Sends & starts running first trial's state machine. A MATLAB timer object updates the 
                              % console UI, while code below proceeds in parallel.
%% Main Trial Loop
for currentTrial = 1:MaxTrials
    currentTrialEvents = TrialManager.getCurrentEvents({'WaitForPoke', 'Reward'}); % Hangs here until Bpod enters one of the listed trigger states, 
                                                                    % then returns current trial's states visited + events captured to this point
    if BpodSystem.Status.BeingUsed == 0; return; end % If user hit console "stop" button, end session 
    [sma, S] = PrepareStateMachine(S, TrialTypes, currentTrial+1, currentTrialEvents); % Prepare next state machine.
    % Since PrepareStateMachine is a function with a separate workspace, pass any local variables needed to make 
    % the state machine as fields of settings struct S e.g. S.learningRate = 0.2.
    SendStateMachine(sma, 'RunASAP'); % With TrialManager, you can send the next trial's state machine while the current trial is ongoing
    RawEvents = TrialManager.getTrialData; % Hangs here until trial is over, then retrieves full trial's raw data
    if BpodSystem.Status.BeingUsed == 0; return; end % If user hit console "stop" button, end session 
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    TrialManager.startTrial(sma); % Start processing the next trial's events (**can call with no argument since SM was already sent)
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned from last trial, update plots and save data
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
end
function [sma, S] = PrepareStateMachine(S, TrialTypes, currentTrial, currentTrialEvents)
% In this case, we don't need trial events to build the state machine - but
% they are available in currentTrialEvents.

S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
R = GetValveTimes(S.GUI.RewardAmount, [1]); LeftValveTime = R(1); % Update reward amounts
if S.context(currentTrial) == 1
    sma = NewStateMatrix(); % Assemble state matrix
    sma = SetCondition(sma, 1, 'Port1', 0); % Condition 1: Port 1 low (is out)
    sma = AddState(sma, 'Name', 'WaitForPoke', ... % Wait for poke to initalize trial
        'Timer', 0,...
        'StateChangeConditions', {'Port1In', 'Reward'},...
        'OutputActions', {'ValveState', 2}); 
    sma = AddState(sma, 'Name', 'Reward', ... % Opens valve
        'Timer', LeftValveTime,...
        'StateChangeConditions', {'Tup', 'Drinking'},...
        'OutputActions', {'ValveState', 1, 'ValveState', 2}); 
    sma = AddState(sma, 'Name', 'Drinking', ... % waits until port 1 is out to exit trial
        'Timer', 0,...
        'StateChangeConditions', {'Condition1', 'ITI'},...
        'OutputActions', {'ValveState', 2});
    sma = AddState(sma, 'Name', 'ITI', ... % Tup state, exits trial
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {'ValveState', 2});
else
    sma = NewStateMatrix(); % Assemble state matrix
    sma = SetCondition(sma, 1, 'Port1', 0); % Condition 1: Port 1 low (is out)
    sma = AddState(sma, 'Name', 'WaitForPoke', ... % Wait for poke to initalize trial
        'Timer', 0,...
        'StateChangeConditions', {'Port1In', 'Reward'},...
        'OutputActions', {}); 
    sma = AddState(sma, 'Name', 'Reward', ... % Opens valve
        'Timer', LeftValveTime,...
        'StateChangeConditions', {'Tup', 'Drinking'},...
        'OutputActions', {'ValveState', 1}); 
    sma = AddState(sma, 'Name', 'Drinking', ... % waits until port 1 is out to exit trial
        'Timer', 0,...
        'StateChangeConditions', {'Condition1', 'ITI'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'ITI', ... % Tup state, exits trial
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {});
end
