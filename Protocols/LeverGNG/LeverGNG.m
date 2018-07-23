function LeverGNG
global BpodSystem
global probe1
%% Create trial manager object
TrialManager = TrialManagerObject;
%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    S.GUI.RewardAmount = 5; % ul
    S.GUI.SoundDuration = 0.1; % seconds
    S.GUI.ResponseTime = 3; % time allowed to respond
    S.GUI.SinWaveFreqGo = 4756; % Frequency of go cue
    S.GUI.SinWaveFreqNoGo = 8000; % Frequency of no-go cue
    S.GUIPanels.Sound = {'SinWaveFreqGo', 'SinWaveFreqNoGo', 'SoundDuration'};
end
%% Define trials
MaxTrials = 500; 
n = 5; % first n trials are GO (Type 1)
probe1= [81 100];
% probe2 = [81 100];
S.context = ones(MaxTrials, 1); %1 = reinforced context, licktube in
S.context(probe1(1):probe1(2)) = 0; % 0 = probe context, licktube out
% S.context(probe2(1):probe2(2)) = 0; % probe trials
randomize = RandStream('mlfg6331_64');
TrialTypes = []; 
for i = 1:25 % 25 groups of 20 trials, each 20 trials is balanced
    TrialTypes(i,:) = datasample(randomize, [1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2],20,'Replace',false);
end
% TrialTypes = reshape(TrialTypes, [20, 25]); % array of 500 balanced trials
TrialTypes = TrialTypes';
TrialTypes(1:n) = 1; % overwrites first n trials
TrialTypes(probe1(1):probe1(1)+1) = 1; % first 2 trials of probe are GO
TrialTypes((probe1(1)+2):probe1(2)) = datasample(randomize, [1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2],18,'Replace',false); % balances remaining 18 trials of probe
BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
tic; % starts timer

%% Initialize plots
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [10 750 1900 400],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off'); % Initializes figure for Outcome plot
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .9 .6]); % Initializes axes for Outcome plot
% BpodSystem.GUIHandles.ProbeContextLine2 = line((probe2),[-3,-3],'LineStyle','-', 'LineWidth', 10,'Color','b', 'MarkerSize',100); % draws line for probe trials
TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',TrialTypes) % 'ntrials',MaxTrials); % Initializes Outcome plot
% GUI plugin displays the settings from the "GUI" subfield of a settings struct.
BpodParameterGUI('init', S); % Initialize parameter GUI plugin--Creates a user interface for viewing and manual override
% Initialize performance graph
figure('Name','OutcomesGraph','NumberTitle','off', 'Position', [1250 100 500 600]); % open appropriate figure
b = categorical({'Hits','Miss','CR', 'FA'}); c = reordercats(b, {'Hits', 'Miss', 'CR', 'FA'}); % set x-axis
subplot(2,2,1); % graph 1
hit = 0; miss = 0; cr = 0; fa =0; % initalizes numbers of hits, miss, cr, fa to 0
z = [0 0 0 0]; % initiates array of graph
OutcomesGraph = bar(gca,c , z); title('Reinforcement (Lever)'); xlabel('Outcome'); ylabel('% Correct'); ylim([0 110]); % Performance figure
numHit = text(1:length(c(1)),z(1),num2str(hit),'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2,2,1);
numMiss = text(2,z(2), num2str(miss), 'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2,2,1);
numCR = text(3,z(3), num2str(cr), 'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2,2,1);
numFA = text(4,z(4), num2str(fa), 'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2,2,1);
subplot(2, 2, 2); % graph 2
hit2 = 0; miss2 = 0; cr2 = 0; fa2 =0; % initializes numbers of hits, miss, cr, fa in probe to 0
z2 = [0 0 0 0]; % initiates array of graph
ProbeGraph = bar(gca, c, z2); title('Probe (Lever)'); xlabel('Outcome'); ylabel('% Correct'); ylim([0 110]); % performance in probe
numHit2 = text(1:length(c(1)),z2(1),num2str(hit2),'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2, 2, 2);
numMiss2 = text(2,z2(2), num2str(miss2), 'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2, 2, 2);
numCR2 = text(3, z2(3),num2str(cr2),'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2, 2, 2);
numFA2 = text(4,z2(4), num2str(fa2), 'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2, 2, 2);
% subplot(223); % graph 3
% hit3 = 0; miss3 = 0; cr3 = 0; fa3 = 0; % initializes numbers of hits, miss, cr, fa, in reinforcement for licks to 0
% z3 = [0 0 0 0]; % initiates array of graph
% OutcomesGraph2 = bar(gca, c,z3); title('Reinforcement (Licks)'); xlabel('Outcome'); ylabel('% Correct'); ylim([0 110]); % lick in reinforcement
% numHit3 = text(1:length(c(1)),z3(1),num2str(hit3),'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2,2,3);
% numMiss3 = text(2,z3(2), num2str(miss3), 'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2,2,3);
% numCR3 = text(3,z3(3), num2str(cr3), 'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2,2,3);
% numFA3 = text(4,z3(4), num2str(fa3), 'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2,2,3);
% subplot(224);
% hit4 = 0; miss4 = 0; cr4 = 0; fa4 = 0; % initializes numbers of hits, miss, cr, fa, in reinforcement for licks to 0
% z4 = [0 0 0 0]; % initiates array of graph
% ProbeGraph2 = bar(gca, c,z4); title('Probe (Licks)'); xlabel('Outcome'); ylabel('% Correct'); ylim([0 110]); % lick in reinforcement
% numHit4 = text(1:length(c(1)),z4(1),num2str(hit4),'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2,2,4);
% numMiss4 = text(2,z4(2), num2str(miss4), 'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2,2,4);
% numCR4 = text(3,z4(3), num2str(cr4), 'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2,2,4);
% numFA4 = text(4,z4(4), num2str(fa4), 'HorizontalAlignment','center','VerticalAlignment','bottom'); subplot(2,2,4);
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
    currentTrialEvents = TrialManager.getCurrentEvents({'WaitForPress', 'OpenValve'}); % Hangs here until Bpod enters one of the listed trigger states, then returns current trial's states visited + events captured to this point
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
        UpdateOutcomePlot(TrialTypes, BpodSystem.Data);
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end   
    % Updates lever performance graphs
    if S.context(currentTrial) == 0 & ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.OpenValve) % hit
        hit2 = hit2+1; % updates number of hits in probe
        z2=[((hit2/(hit2+miss2))*100) ((miss2/(hit2+miss2))*100) z2(3) z2(4)]; % change percentage difference between hit and miss
        set(ProbeGraph, 'YData', z2); % Updates probe performance plot
    elseif S.context(currentTrial) == 0 & TrialTypes(currentTrial) == 1 % go
        miss2 = miss2 +1; % update num of misses in probe
        z2=[((hit2/(hit2+miss2))*100) ((miss2/(hit2+miss2))*100) z2(3) z2(4)]; % change percentage difference between hit and miss
        set(ProbeGraph, 'YData', z2); % Update probe performance plot
    elseif S.context(currentTrial) == 0 & TrialTypes(currentTrial) == 2 & ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.CorrectReject) % If no-go and correct reject
        cr2 = cr2 +1; % update num of correct rejects
        z2 = [z2(1) z2(2) ((cr2/(cr2+fa2))*100) ((fa2/(fa2+cr2))*100)]; % change percentage difference between false alarm and correct rejects
        set(ProbeGraph, 'YData', z2); % Update performance plot
    elseif S.context(currentTrial) == 0 & TrialTypes(currentTrial) == 2 % no go
        fa2 = fa2+1; % update num of false alarms
        z2 = [z2(1) z2(2) ((cr2/(cr2+fa2))*100) ((fa2/(fa2+cr2))*100)]; % change percentage difference between false alarm and correct rejects
        set(ProbeGraph, 'YData', z2); % Update performance plot
    elseif S.context(currentTrial) == 1 & ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.OpenValve)
        hit = hit +1; % update num of hits
        z=[((hit/(hit+miss))*100) ((miss/(hit+miss))*100) z(3) z(4)]; % change percentage difference between hit and miss
        set(OutcomesGraph, 'YData', z); % Update reinforcement performance plot
    elseif S.context(currentTrial) == 1 & TrialTypes(currentTrial) == 1 % go
        miss = miss +1; % update num of misses
        z=[((hit/(hit+miss))*100) ((miss/(hit+miss))*100) z(3) z(4)]; % change percentage difference between hit and miss
        set(OutcomesGraph, 'YData', z); % Update reinforcement performance plot
    elseif S.context(currentTrial) == 1 & TrialTypes(currentTrial) == 2 & ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.CorrectReject) % If no-go and correct reject
        cr = cr +1; % update num of correct rejects
        z = [z(1) z(2) ((cr/(cr+fa))*100) ((fa/(fa+cr))*100)]; % change percentage difference between false alarm and correct rejects
        set(OutcomesGraph, 'YData', z); % Update reinforcement performance plot
    elseif S.context(currentTrial) == 1 & TrialTypes(currentTrial) == 2 % no go
        fa = fa+1; % update num of false alarms
        z = [z(1) z(2) ((cr/(cr+fa))*100) ((fa/(fa+cr))*100)]; % change percentage difference between false alarm and correct rejects
        set(OutcomesGraph, 'YData', z); % Update reinforcement performance plot       
    end
    % Update numbers of hit, misses, cr, and false alarms above each bin in performance graphs (deletes previous, updates number in specific plot)    
    delete(numHit2); subplot(222); numHit2 = text(1:length(c(1)),z2(1),num2str(hit2),'vert','bottom','horiz','center'); 
    delete(numMiss2);subplot(222); numMiss2 = text(2,z2(2), num2str(miss2), 'vert', 'bottom', 'horiz', 'center');
    delete(numCR2);subplot(222);numCR2 = text(3,z2(3), num2str(cr2), 'vert', 'bottom', 'horiz', 'center');
    delete(numFA2);subplot(222);numFA2 = text(4,z2(4), num2str(fa2), 'vert', 'bottom', 'horiz', 'center');
    delete(numHit);subplot(221);numHit = text(1:length(c(1)),z(1),num2str(hit),'HorizontalAlignment','center','VerticalAlignment','bottom');
    delete(numMiss);subplot(221);numMiss = text(2,z(2), num2str(miss), 'vert', 'bottom', 'horiz', 'center');
    delete(numCR);subplot(221);numCR = text(3,z(3), num2str(cr), 'vert', 'bottom', 'horiz', 'center');
    delete(numFA);subplot(221);numFA = text(4,z(4), num2str(fa), 'vert', 'bottom', 'horiz', 'center');
%     % Updates lick performance graphs
%     if S.context(currentTrial) == 0 & ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Lick) % hit
%         hit3 = hit3+1; % updates number of hits in lick reinforcement
%         z3=[((hit3/(hit3+miss3))*100) ((miss3/(hit3+miss3))*100) z3(3) z3(4)]; % change percentage difference between hit and miss
%         set(OutcomesGraph2, 'YData', z3); % Updates performance plot
%     elseif S.context(currentTrial) == 0 & TrialTypes(currentTrial) == 1 % go
%         miss3 = miss3 +1; % update num of misses in lick reinforcement
%         z3=[((hit3/(hit3+miss3))*100) ((miss3/(hit3+miss3))*100) z3(3) z3(4)]; % change percentage difference between hit and miss
%         set(OutcomesGraph2, 'YData', z3); % Update performance plot
%     elseif S.context(currentTrial) == 0 & TrialTypes(currentTrial) == 2 & ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.NoLick) % If no-go and correct reject
%         cr3 = cr3 +1; % update num of correct rejects in lick reinforcement
%         z3 = [z3(1) z3(2) ((cr3/(cr3+fa3))*100) ((fa3/(fa3+cr3))*100)]; % change percentage difference between false alarm and correct rejects
%         set(OutcomesGraph2, 'YData', z3); % Update performance plot
%     elseif S.context(currentTrial) == 0 & TrialTypes(currentTrial) == 2 % no go
%         fa3 = fa3+1; % update num of false alarms in lick reinforcement
%         z3 = [z3(1) z3(2) ((cr3/(cr3+fa3))*100) ((fa3/(fa3+cr3))*100)]; % change percentage difference between false alarm and correct rejects
%         set(OutcomesGraph2, 'YData', z3); % Update performance plot
%     elseif S.context(currentTrial) == 0 & ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Lick) % hit
%         hit4 = hit4+1; % updates number of hits in lick probe
%         z4=[((hit4/(hit4+miss4))*100) ((miss4/(hit4+miss4))*100) z4(3) z4(4)]; % change percentage difference between hit and miss
%         set(ProbeGraph2, 'YData', z4); % Updates performance plot
%     elseif S.context(currentTrial) == 0 & TrialTypes(currentTrial) == 1 % go
%         miss4 = miss4 +1; % update num of misses in lick probe
%         z4=[((hit4/(hit4+miss4))*100) ((miss4/(hit4+miss4))*100) z4(3) z4(4)]; % change percentage difference between hit and miss
%         set(ProbeGraph2, 'YData', z4); % Update performance plot
%     elseif S.context(currentTrial) == 0 & TrialTypes(currentTrial) == 2 & ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.NoLick) % If no-go and correct reject
%         cr4 = cr4 +1; % update num of correct rejects in lick probe
%         z4 = [z4(1) z4(2) ((cr4/(cr4+fa4))*100) ((fa4/(fa4+cr4))*100)]; % change percentage difference between false alarm and correct rejects
%         set(ProbeGraph2, 'YData', z4); % Update performance plot
%     elseif S.context(currentTrial) == 0 & TrialTypes(currentTrial) == 2 % no go
%         fa4 = fa4+1; % update num of false alarms in lick probe
%         z4 = [z4(1) z4(2) ((cr4/(cr4+fa4))*100) ((fa4/(fa4+cr4))*100)]; % change percentage difference between false alarm and correct rejects
%         set(ProbeGraph2, 'YData', z4); % Update performance plot        
%     end
%     % Update numbers of hit, misses, cr, and false alarms above each bin in performance graphs (deletes previous, updates number in specific plot)    
%     delete(numHit3); subplot(223); numHit3 = text(1:length(c(1)),z3(1),num2str(hit3),'vert','bottom','horiz','center'); 
%     delete(numMiss3);subplot(223); numMiss3 = text(2,z3(2), num2str(miss3), 'vert', 'bottom', 'horiz', 'center');
%     delete(numCR3);subplot(223);numCR3 = text(3,z3(3), num2str(cr3), 'vert', 'bottom', 'horiz', 'center');
%     delete(numFA3);subplot(223);numFA3 = text(4,z3(4), num2str(fa3), 'vert', 'bottom', 'horiz', 'center');
%     delete(numHit4); subplot(224); numHit4 = text(1:length(c(1)),z4(1),num2str(hit4),'vert','bottom','horiz','center'); 
%     delete(numMiss4);subplot(224); numMiss4 = text(2,z4(2), num2str(miss4), 'vert', 'bottom', 'horiz', 'center');
%     delete(numCR4);subplot(224);numCR4 = text(3,z4(3), num2str(cr4), 'vert', 'bottom', 'horiz', 'center');
%     delete(numFA4);subplot(224);numFA4 = text(4,z4(4), num2str(fa4), 'vert', 'bottom', 'horiz', 'center');
end
function [sma, S] = PrepareStateMachine(S, TrialTypes, currentTrial, ~)
sma = NewStateMatrix(); % Assemble state matrix
sma = SetCondition(sma, 1, 'Port2', 1); % ensure lever is unpressed (high = 1 =unpressed)
sma = SetCondition(sma, 2, 'Port1', 0); % ensure no licking (low = 0 = no lick)
GoFreq = GenerateSineWave(S.SF, S.GUI.SinWaveFreqGo, S.GUI.SoundDuration); % Sampling freq (hz), Sine frequency (hz), duration (s)
NoGoFreq = GenerateSineWave(S.SF, S.GUI.SinWaveFreqNoGo, S.GUI.SoundDuration); % Sampling freq (hz), Sine frequency (hz), duration (s)
PsychToolboxSoundServer('Load', 1, GoFreq);
PsychToolboxSoundServer('Load', 2, NoGoFreq);
S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
R = GetValveTimes(S.GUI.RewardAmount, 1); ValveTime = R;  % Update reward amounts
switch TrialTypes(currentTrial) % Determine trial-specific state matrix fields
    case 1 % GO Trial
        Stimulus = 1; % GoTone
        INResponse = 'OpenValve';
        NOResponse = 'Miss';
        Lick = 'Lick';
        NoLick = 'NoLick';
    case 2 % NO GO Trial
        Stimulus = 2; % NoGoTone 
        INResponse = 'Punish';
        NOResponse = 'CorrectReject';
        Lick = 'Lick';
        NoLick = 'NoLick';
end
   
if S.context(currentTrial) == 1 % Reinforced context 
    sma = AddState(sma, 'Name', 'PreTrial', ... % PreTrial period, ensuring no action until next trial begins
        'Timer', 2, ...
        'StateChangeConditions', {'Tup', 'Stimulus', 'Port2Out', 'StopForLever', 'Port1In', 'StopForLick'}, ... % if no action, stimulus activated; if action, stop period
        'OutputActions', {'PWM2', 255});            
    sma = AddState(sma, 'Name', 'StopForLever', ... % Stop period to assure no activity during Pre-Trial
        'Timer', 0, ...
        'StateChangeConditions', {'Condition1', 'PreTrial'}, ...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'StopForLick', ...
        'Timer', 0, ...
        'StateChangeConditions', {'Condition2', 'PreTrial'}, ...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'Stimulus', ... % Presentation of stimulus
        'Timer', S.GUI.SoundDuration, ...
        'StateChangeConditions', {'Tup', 'Dead'}, ...
        'OutputActions', {'SoftCode',Stimulus}); 
    sma = AddState(sma, 'Name', 'Dead', ... % 100ms dead period
        'Timer', .1, ...
        'StateChangeConditions', {'Tup', 'WaitForPress'}, ...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'WaitForPress', ... % Waiting for response
        'Timer', S.GUI.ResponseTime, ... 
        'StateChangeConditions', {'Port2Out', INResponse, 'Tup', NOResponse},... % Lever press leads to reward, no response leads to a Miss
        'OutputActions', {});     
    sma = AddState(sma, 'Name', 'OpenValve', ... % Opens valve
        'Timer', ValveTime,...
        'StateChangeConditions', {'Tup','Drinking'},...
        'OutputActions', {'ValveState', 1});           
%     sma = AddState(sma, 'Name', 'NoLick', ... 
%         'Timer', 0, ...
%         'StateChangeConditions', {'Tup', NOResponse}, ...
%         'OutputActions', {'PWM2', 255});
%     sma = AddState(sma, 'Name', 'Lick', ...
%         'Timer', 0, ...
%         'StateChangeConditions', {'Tup', 'WaitForPress'}, ...
%         'OutputActions', {'PWM2', 255});
    sma = AddState(sma, 'Name', 'Drinking', ... % 4 seconds for drinking
        'Timer', 4,...
        'StateChangeConditions', {'Tup', 'CheckLever'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'CorrectReject', ... % 1 second correct reject state
        'Timer', 2,...
        'StateChangeConditions', {'Tup', 'CheckLever'}, ...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'Punish', ... % 1 second correct reject state
        'Timer', 7,...
        'StateChangeConditions', {'Tup', 'CheckLever'}, ...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'Miss', ... % Miss period
        'Timer', 2,...
        'StateChangeConditions', {'Tup', 'CheckLever'}, ...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'CheckLever', ... % Miss period
        'Timer', 0,...
        'StateChangeConditions', {'Condition1', 'CheckLick'}, ...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'CheckLick', ... % Miss period
        'Timer', 0,...
        'StateChangeConditions', {'Condition2', 'ITI'}, ...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'ITI', ... % Tup Action
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {});
else % Probe context
    sma = AddState(sma, 'Name', 'PreTrial', ... % Pre trial period ensuring no activity for 2 seconds
        'Timer', 2, ...
        'StateChangeConditions', {'Tup', 'Stimulus', 'Port1In', 'Stop'}, ... % if no action, stimulus activated; if action, stop period
        'OutputActions', {'ValveState', 2}); % Keeps lick tube out
    sma = AddState(sma, 'Name', 'Stop', ... % Stop period to assure no activity during Pre-Trial
        'Timer', 0, ...
        'StateChangeConditions', {'Tup', 'PreTrial'}, ... % returns to PreTrial
        'OutputActions', {'ValveState', 2}); % Keeps lick tube out
    sma = AddState(sma, 'Name', 'Stimulus', ... % Tone
        'Timer', S.GUI.SoundDuration, ...
        'StateChangeConditions', {'Tup', 'Dead'}, ...
        'OutputActions', {'SoftCode', Stimulus, 'ValveState', 2}); % Keeps lick tube out 
    sma = AddState(sma, 'Name', 'Dead', ... % 100ms dead period
        'Timer', .1, ...
        'StateChangeConditions', {'Tup', 'WaitForPress'}, ...
        'OutputActions', {'ValveState', 2}); % Keeps lick tube out
    sma = AddState(sma, 'Name', 'WaitForPress', ... % Waiting for response
        'Timer', S.GUI.ResponseTime, ... 
        'StateChangeConditions', {'Port2Out', INResponse, 'Tup', NOResponse},... % Lever press leads to reward, no response leads to a Miss
        'OutputActions', {'ValveState', 2}); % Keeps lick tube out
    sma = AddState(sma, 'Name', 'OpenValve', ... % Opens valve
        'Timer', ValveTime,...
        'StateChangeConditions', {'Tup','Drinking',},...
        'OutputActions', {'ValveState', 2}); 
    sma = AddState(sma, 'Name', 'Drinking', ... % 4 seconds for drinking
        'Timer', 4,...
        'StateChangeConditions', {'Tup', 'CheckLever'},...
        'OutputActions', {'ValveState', 2});
    sma = AddState(sma, 'Name', 'CorrectReject', ... % 1 second correct reject state
        'Timer', 2,...
        'StateChangeConditions', {'Tup', 'CheckLever'}, ...
        'OutputActions', {'ValveState', 2});
    sma = AddState(sma, 'Name', 'Punish', ... % 1 second correct reject state
        'Timer', 7,...
        'StateChangeConditions', {'Tup', 'CheckLever'}, ...
        'OutputActions', {'ValveState', 2});
    sma = AddState(sma, 'Name', 'Miss', ... % Miss period
        'Timer', 2,...
        'StateChangeConditions', {'Tup', 'CheckLever'}, ...
        'OutputActions', {'ValveState', 2});
    sma = AddState(sma, 'Name', 'CheckLever', ... % Miss period
        'Timer', 0,...
        'StateChangeConditions', {'Condition1', 'CheckLick'}, ...
        'OutputActions', {'ValveState', 2});
    sma = AddState(sma, 'Name', 'CheckLick', ... % Miss period
        'Timer', 0,...
        'StateChangeConditions', {'Condition2', 'ITI'}, ...
        'OutputActions', {'ValveState', 2});
    sma = AddState(sma, 'Name', 'ITI', ... % Tup Action
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {'ValveState', 2});
end

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
    elseif TrialTypes(x) == 2 % no go
        Outcomes(x) = 0; % red X for false alarm
    end
end
TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'update',Data.nTrials+1,TrialTypes,Outcomes);  