function PhotogateTest
global BpodSystem
%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    S.GUI.CurrentBlock = 1; % Training level % 1 = Direct Delivery at both ports 2 = Poke for delivery
    S.GUI.RewardAmount = 5; % ul
    S.GUI.PortOutRegDelay = 0.5; % How long the mouse must remain out before poking back in
    S.GUI.ResponseTimeGo = 2; % How long until the mouse must make a choice, or forefeit the trial
end
%% Define trials
MaxTrials = 1000;
TrialTypes = ceil(rand(1,1000)*2); % Trial types randomly interleaved, type 1 or 2
BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
%% Initialize plots
BpodParameterGUI('init', S); % Initialize parameter GUI plugin

%% Main trial loop
for currentTrial = 1:MaxTrials
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    R = GetValveTimes(S.GUI.RewardAmount, [1]); LeftValveTime = R;  % Update reward amounts
    switch TrialTypes(currentTrial) % Determine trial-specific state matrix fields
        case 1
            StateOnLeftPoke1 = 'LeftReward'; 
            Tup_Action = 'ITI';
        case 2
            StateOnLeftPoke1 = 'WaitForPokeOut1';       
    end
    sma = NewStateMatrix(); % Assemble state matrix
    sma = AddState(sma, 'Name', 'WaitForPoke', ... 
        'Timer', 2, ... 
        'StateChangeConditions', {'Port1In', 'InsidePort1', 'Port2In', 'InsidePort2'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'InsidePort1', ...
        'Timer', 2,...
        'StateChangeConditions', {'Port1Out', 'exit'},...
        'OutputActions', {}); 
    sma = AddState(sma, 'Name', 'InsidePort2', ...
        'Timer', 2,...
        'StateChangeConditions', {'Tup', 'Wait'},...
        'OutputActions', {}); 
    sma = AddState(sma, 'Name', 'Wait', ...
        'Timer', 2,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {}); 
    
    SendStateMatrix(sma); % Sends a state machine description to a Bpod 
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        %BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0
        return
    end
    
end
end