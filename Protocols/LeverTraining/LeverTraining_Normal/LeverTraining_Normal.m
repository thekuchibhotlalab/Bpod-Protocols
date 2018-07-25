function LeverTraining_Normal
global BpodSystem
%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    S.GUI.RewardAmount = 5.2; % ul
end
% Initialize performance graph
lick = figure('Name','Lick Tracker','NumberTitle','off', 'Position', [10 500 500 600]); % open appropriate figure
b = categorical({'Hits','Miss', 'FA'}); c = reordercats(b, {'Hits', 'Miss', 'FA'}); % set x-axis
hit = 0; miss = 0; fa =0; % initalizes numbers of hits, miss, cr, fa to 0
z = [0 0 0];
LickGraph = bar(gca,c , z); title('Lick Tracker'); xlabel('Outcome'); ylabel('Number of Licks'); ylim([0 800]); yticks(0:50:800) % Performance figure
numHit = text(1:length(c(1)),z(1),num2str(hit),'HorizontalAlignment','center','VerticalAlignment','bottom');
numMiss = text(2,z(2), num2str(miss), 'HorizontalAlignment','center','VerticalAlignment','bottom');
numFA = text(3,z(3), num2str(fa), 'HorizontalAlignment','center','VerticalAlignment','bottom');

%% Define trials
MaxTrials = 1000; % Max Trials
randomize = RandStream('mlfg6331_64');
StopForLick = [];
for i = 1:48 % 25 groups of 20 trials, each 20 trials is balanced
    StopForLick(i,:) = datasample(randomize, [1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3],21,'Replace',false);
end
StopForLick = StopForLick';
%% Initialize plots
TotalRewardDisplay('init2'); % Initialize reward display for lever press
%% Main trial loop
for currentTrial = 1:MaxTrials
    R = GetValveTimes(S.GUI.RewardAmount, 1); ValveTime = R;  % Update reward amounts
    
    sma = NewStateMatrix(); % Assemble state matrix
    sma = SetCondition(sma, 1, 'Port1', 1); % high is in

    sma = AddState(sma, 'Name', 'WaitForPress', ... % wait for animal to initiate trial
        'Timer', 2, ... 
        'StateChangeConditions', {'Port2Out', 'OpenValve', 'SoftCode1', 'ManualDelivery', 'Condition1', 'StopForLick'},... % lever press opens valve OR button press leads to manual delivery
        'OutputActions', {}); 
    sma = AddState(sma, 'Name', 'StopForLick', ... % Stop period to assure no activity during wait for press
        'Timer', 0.5, ...
        'StateChangeConditions', {'Tup', 'exit'}, ...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'OpenValve', ... % water delivery
        'Timer', ValveTime,...
        'StateChangeConditions', {'Tup', 'Response'},...
        'OutputActions', {'ValveState', 1});
    sma = AddState(sma, 'Name', 'ManualDelivery', ... % water delivery
        'Timer', ValveTime,...
        'StateChangeConditions', {'Tup', 'Drinking'},...
        'OutputActions', {'ValveState', 1});
    sma = AddState(sma, 'Name', 'Response', ... % water delivery
        'Timer', 2,...
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
        'OutputActions', {});
    SendStateMatrix(sma); % Sends a state machine description to a Bpod 
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0
        return
    end
    if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.OpenValve(1)) % update reward display
        TotalRewardDisplay('add', (S.GUI.RewardAmount));
        TotalRewardDisplay('presses');
    end
    if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.StopForLick) % hit
        fa = fa+1; % updates number of hits in probe
        z=[z(1) z(2) fa]; % change percentage difference between hit and miss
        set(LickGraph, 'YData', z); % Updates probe performance plot  
        figure(lick); delete(numFA); numFA = text(3,z(3), num2str(fa), 'vert', 'bottom', 'horiz', 'center');
    elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Drinking) % hit
        hit = hit+1; % updates number of hits in probe
        z=[hit z(2) z(3)]; % change percentage difference between hit and miss
        set(LickGraph, 'YData', z); % Updates probe performance plot
        figure(lick); delete(numHit);numHit = text(1:length(c(1)),z(1),num2str(hit),'HorizontalAlignment','center','VerticalAlignment','bottom');
    elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Miss) % hit
        miss = miss+1; % updates number of hits in probe
        z=[z(1) miss z(3)]; % change percentage difference between hit and miss
        set(LickGraph, 'YData', z); % Updates probe performance plot  
        figure(lick); delete(numMiss);numMiss = text(2,z(2), num2str(miss), 'vert', 'bottom', 'horiz', 'center');
    end
    
end
end
