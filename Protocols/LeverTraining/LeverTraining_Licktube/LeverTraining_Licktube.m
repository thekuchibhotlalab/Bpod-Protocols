function LeverTraining_Licktube
global BpodSystem
global Amount
%% Create trial manager object
TrialManager = TrialManagerObject;
%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    S.GUI.RewardAmount = 5.0; % ul
end
Amount = S.GUI.RewardAmount;

% Initialize performance graph
lick = figure('Name','Lick Tracker','NumberTitle','off', 'Position', [10 500 500 600]); % open appropriate figure
b = categorical({'Hits','Miss', 'FA'}); c = reordercats(b, {'Hits', 'Miss', 'FA'}); % set x-axis
hit = 0; miss = 0; fa =0; % initalizes numbers of hits, miss, cr, fa to 0
z = [0 0 0];
LickGraph = bar(gca,c , z); title('Lick Tracker'); xlabel('Outcome'); ylabel('Number of Licks'); ylim([0 800]); yticks(0:50:800) % Performance figure
numHit = text(1:length(c(1)),z(1),num2str(hit),'HorizontalAlignment','center','VerticalAlignment','bottom'); % initializes number of hits
numMiss = text(2,z(2), num2str(miss), 'HorizontalAlignment','center','VerticalAlignment','bottom'); % initalizes number or misses
numFA = text(3,z(3), num2str(fa), 'HorizontalAlignment','center','VerticalAlignment','bottom'); % intitializes number of false alarms

%% Define trials
MaxTrials = 1000; % Max Trials
randomize = RandStream('mlfg6331_64'); % creates random stream of numbers for later data sampling 
StopForLick = []; % initializes empty array for stop for lick
for i = 1:48 % 48 groups of 21 trials, each 21 trials is balanced
    StopForLick(i,:) = datasample(randomize, [1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3],21,'Replace',false);
end
StopForLick = StopForLick'; % transposes stop for lick phase
tic;
%% Initialize plots
TotalRewardDisplay('init2'); % Initialize reward display for lever press
%% Prepare state machine
sma = PrepareStateMachine(S, 1, []); % Prepare state machine for trial 1 with empty "current events" variable
TrialManager.startTrial(sma); % Sends & starts running first trial's state machine. A MATLAB timer object updates the 
                              % console UI, while code below proceeds in parallel.
% In this case, we don't need trial events to build the state machine - but
% they are available in currentTrialEvents.
%% Main trial loop
for currentTrial = 1:MaxTrials
    currentTrialEvents = TrialManager.getCurrentEvents({'WaitForPress', 'OpenValve'}); % Hangs here until Bpod enters one of the listed trigger states, then returns current trial's states visited + events captured to this point
    if BpodSystem.Status.BeingUsed == 0; return; end % If user hit console "stop" button, end session 
    [sma, S] = PrepareStateMachine(S, currentTrial+1, currentTrialEvents); % Prepare next state machine.
    % Since PrepareStateMachine is a function with a separate workspace, pass any local variables needed to make 
    % the state machine as fields of settings struct S e.g. S.learningRate = 0.2.
    SendStateMachine(sma, 'RunASAP'); % With TrialManager, you can send the next trial's state machine while the current trial is ongoing
    RawEvents = TrialManager.getTrialData; % Hangs here until trial is over, then retrieves full trial's raw data
    if BpodSystem.Status.BeingUsed == 0; return; end % If user hit console "stop" button, end session 
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    TrialManager.startTrial(sma); % Start processing the next trial's events (** can call with no argument since SM was already sent)
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.OpenValve(1)) % update reward display
        TotalRewardDisplay('add', (S.GUI.RewardAmount));
        TotalRewardDisplay('presses');
    end
    if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.StopForLick) % hit
        fa = fa+1; % updates number of false alarms in probe
        z=[z(1) z(2) fa]; % adds number to array
        set(LickGraph, 'YData', z); % Updates probe performance plot  
        figure(lick); delete(numFA); numFA = text(3,z(3), num2str(fa), 'vert', 'bottom', 'horiz', 'center');
    elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Drinking) % hit
        hit = hit+1; % updates number of hits in probe
        z=[hit z(2) z(3)]; % adds number to array
        set(LickGraph, 'YData', z); % Updates probe performance plot
        figure(lick); delete(numHit);numHit = text(1:length(c(1)),z(1),num2str(hit),'HorizontalAlignment','center','VerticalAlignment','bottom');
    elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Miss) % hit
        miss = miss+1; % updates number of misses in probe
        z=[z(1) miss z(3)]; % adds number to array
        set(LickGraph, 'YData', z); % Updates probe performance plot  
        figure(lick); delete(numMiss);numMiss = text(2,z(2), num2str(miss), 'vert', 'bottom', 'horiz', 'center');
    end
end
function [sma, S] = PrepareStateMachine(S, currentTrial, ~)
sma = NewStateMatrix(); % Assemble state matrix
sma = SetCondition(sma, 1, 'Port1', 1); % high is in
R = GetValveTimes(S.GUI.RewardAmount, 1); ValveTime = R;  % Update reward amounts

sma = AddState(sma, 'Name', 'WaitForPress', ... % wait for animal to initiate trial
    'Timer', 2, ... 
    'StateChangeConditions', {'Port2Out', 'OpenValve', 'SoftCode1', 'ManualDelivery', 'Condition1', 'StopForLick'},... % lever press opens valve OR button press leads to manual delivery
    'OutputActions', {'ValveState', 2}); 
sma = AddState(sma, 'Name', 'StopForLick', ... % Stop period to assure no activity during wait for press
    'Timer', 1.5, ...
    'StateChangeConditions', {'Tup', 'exit'}, ...
    'OutputActions', {'ValveState', 2});
sma = AddState(sma, 'Name', 'OpenValve', ... % water delivery
    'Timer', ValveTime,...
    'StateChangeConditions', {'Tup', 'Response'},...
    'OutputActions', {'ValveState', 1});
sma = AddState(sma, 'Name', 'ManualDelivery', ... % water delivery
    'Timer', ValveTime,...
    'StateChangeConditions', {'Tup', 'Drinking'},...
    'OutputActions', {'ValveState', 1});
sma = AddState(sma, 'Name', 'Response', ... % water delivery
    'Timer', 4,...
    'StateChangeConditions', {'Port1In', 'Drinking', 'Tup', 'Miss'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'Drinking', ... % 2 seconds for drinking
    'Timer', 2,...
    'StateChangeConditions', {'Tup', 'ITI', 'SoftCode1', 'ManualDelivery'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'Miss', ... % 2 seconds for drinking
    'Timer', .1,...
    'StateChangeConditions', {'Tup', 'ITI'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'ITI', ... % Tup Action
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'exit'},... % exit trial
    'OutputActions', {'ValveState', 2});
