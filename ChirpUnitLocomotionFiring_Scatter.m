%% Locomotion-firing analysis - Scatter Plots
% Correlates firing rates of mouse LGN neurons with locomotion speeds,
% creating a scatter plot of mean firing rate against mean speed per trial


%% TODO:
% WHAT PLOTS: 
%   (A) correlate mean_speed and mean_firing rate for entire 
%   ~PROBLEM: data.Locomotion only contains mean_speed for entire expt, not
%   trial-wise or per unit (ie only 7 mean_speeds)
%   (B) extract actual time series, calculate mean_speed and get
%   mean_firing from data.TrialSpikesExtra (validate with own calculation)
%   (1) create subplots per mouse_counter (2) include info title
% IDEAS:
% co-plot spikes, mean spike density function and mean speed in one plot

%% General
clear all, close all, clc

%% Data Joint startup
startup_cin

%% Load Data
load('units_for_chirp_sorted.mat');

%% Parameters

samplingRate = 30000; % sampling rate of locomotion data

%% make example key (ChirpUnit#1):
% key.mouse_counter = 58;
% key.series_num = 6;
% key.unit_id = 2;
% key.exp_num = 11;
% 
% %% check some datajoint tables using key:
% data.Locomotion(key) 
%     % Primary key:  mouse_counter, series_num, exp_num
%     % Dependent attributes:  roll, pitch, yaw, timestamps, sampling_rate, speed, direction,...
%                              movement_threshold, percent_moving, mean_speed, max_speed, locomotion_ts
% data.TrialSpikesExtra(key)
%     % Primary key:  mouse_counter, series_num, exp_num, cond_num, trial_num, unit_id
%     % Dependent attributes:  spike_times, spike_rate, trialspikesextra_ts
% data.Mice(key)
% 
% erd('data')

%% Correlate mean speeds and mean firing rates 
% Go through units of interest out of 49 chirp units 
% > for each unit, extract mean speed and firing rate for each of ca. 18 trials

% Select units of interest
units = [28:49];

% Start counters for appropriate plot numbers and titles
% Mouse counter (at #1) to create separate figures for each mouse containing multiple subplots
MouseCounter = units_for_chirp_sorted(units(1)).mouse_counter;
seriesNum = 0;
exptNum = 0;

for unit = units
    %% Get Mean firing rates
    % NB: spike times are here if necessary
    
    % ##YB: find better solution than having to clear every loop - e.g.
    % larger cell array filled with results from each loop
    clear spikeTimes meanSpikeRatesPerTrial motionTimeStamps speeds onsets offsets meanSpeedPerTrial
    [spikeTimes, meanSpikeRatesPerTrial] = ...
        fetchn(data.TrialSpikesExtra(units_for_chirp_sorted(unit)),'spike_times', 'spike_rate');
    
    % Debug: Continue to next for-iteration if unit does not have any entries
    if isempty(meanSpikeRatesPerTrial)
        continue
    end

    %% Get Locomotion timestamps (s) and speed (cm/s)
    % this gives timestamps and speed for each unit for a continuous 600 s period
    % > 600 s period only for continuous chirp stimulus experiment?
    % - NB: spike times are only given relative to stimulus-time (0-30 s)
    
    [motionTimeStamps, speeds] =...
        fetchn(data.Locomotion(units_for_chirp_sorted(unit)), 'timestamps', 'speed');
    motionTimeStamps = cell2mat(motionTimeStamps);
    speeds = cell2mat(speeds);
    
    % divide by sampling rate to get seconds on x-axis
    motionTimeStamps = motionTimeStamps/samplingRate;
    % timeStamps = cellfun(@(v) v./samplingRate, timeStamps,'UniformOutput', false);
    
    % fetch(data.Locomotion(key))
    % fetch(data.Locomotion(key), 'timestamps');
    
    %     [MotionTimeStamps, speeds] = fetchn(data.Locomotion(units_for_chirp_sorted),...
    %         'timestamps', 'speed'); % this one gives 7 speeds for 7 expts
    
    % Plot Speed
    %     figure;
    %     plot(MotionTimeStamps{1},speeds{1}, 'k-');
    %     plot(MotionTimeStamps, speeds);
    %% Get trial onsets & offsets to extract trial periods from speed vector to compute mean speeds
    % > get data.ExtraTrials trial_onset and trial_offset
    [onsets, offsets] =...
        fetchn(data.ExtraTrials(units_for_chirp_sorted(unit)),'trial_onset', 'trial_offset');
    onsets = onsets/samplingRate; % ###YB: any way to combine the two lines?
    offsets = offsets/samplingRate;
    
    for trial = 1:length(onsets)
        timeIdx = find(motionTimeStamps >= onsets(trial) & motionTimeStamps <= offsets(trial));
        speedIdx = speeds(timeIdx);
        meanSpeedPerTrial(trial,:) = mean(speedIdx);
    end
    
    %     figure,
    %     plot(MotionTimeStamps(timeIdx), speedIdx);
    % stimPeriods = (offset - onset)/ samplingRate; % sanity check that all times are 32 s
    
    %% Make scatter plot for mean speed against mean firing & draw regression line
    
    % Determine mouse number to create one figure per mouse
    % Check if we are still in the same mouse number
    if units_for_chirp_sorted(unit).mouse_counter == MouseCounter;
    else % if not, update mouse number to create new figure
        MouseCounter = units_for_chirp_sorted(unit).mouse_counter;
        figure
    end
    
    % reserve appropriate number of subplots for current mouse
    subPlotNumber = ...
        find([units_for_chirp_sorted.mouse_counter] == MouseCounter);
    % Divide number of subplots into rows and colums
    subPlotRows = floor(sqrt(length(subPlotNumber)));
    subPlotColumns = subPlotRows+1;
    subPlotCount = find(subPlotNumber == unit);
    subplot(subPlotRows, subPlotColumns, subPlotCount)
    
    % Scatter plot
    scatter(meanSpeedPerTrial,meanSpikeRatesPerTrial);
    ax = gca;
    % Insert labels only for first plot
    if subPlotCount == 1      
        xlabel('mean speed (cm/s) per trial');
        ylabel('mean spike rate (Hz) per trial');
    end
    % insert subplottitle only for new series/experiment for visual grouping of plots
        % NB: grouping into separate columns/rows does not make sense for cases
        % where there is only one series/experiment and 10+ plots in one row/column
    % initialize counter at random number
    if seriesNum ~= units_for_chirp_sorted(unit).series_num || exptNum ~= units_for_chirp_sorted(unit).exp_num ;
        seriesNum = units_for_chirp_sorted(unit).series_num;
        exptNum = units_for_chirp_sorted(unit).exp_num;
        subPlotTitle = strcat('Mouse:',num2str(MouseCounter),...
            ' Series: ',num2str(seriesNum),...
            ' Expt: ', num2str(exptNum),...
            ' Unit: ',num2str(units_for_chirp_sorted(unit).unit_id));
        title(subPlotTitle);
    else
        subPlotTitle = strcat('Unit: ',num2str(units_for_chirp_sorted(unit).unit_id));
        title(subPlotTitle);
    end
    
    % Regression
    [r,slope,intercept] = regression(meanSpeedPerTrial',meanSpikeRatesPerTrial');
    regressionLine = slope*meanSpeedPerTrial'+intercept;
    % alternative to line regression: fit a first-order polynomial (i.e., line)
    %     [beta,S] = polyfit(meanSpeedPerTrial',meanSpikeRatesPerTrial',1);
    % beta = coefficients; S = structure information about the fit
    hold on
    plot(meanSpeedPerTrial',regressionLine,'b','linewidth',1.5)
    %     plot(meanSpeedPerTrial',beta(1)*meanSpeedPerTrial'+beta(2),'r','linewidth',1.5)
    hold off
    % alternatives for regression line plotting
    %     lsline % plot least squares line in current plot - cheap
    % plot regression plot ~ imposes same axes
    %     plotregression(meanSpeedPerTrial',meanSpikeRatesPerTrial','Regression');
    
    % Insert r-value as textbox
    text(ax.XLim(end),ax.YLim(end),['r = ',num2str(r)],'FontSize',12,...
        'HorizontalAlignment','right', 'VerticalAlignment','top')
    
    % Create Info panel: mouse, unit, series, experiment
    % NB: plot after using tightfig!
%     infoTitle = strcat('Info: Mouse:', num2str(units_for_chirp_sorted(unit).mouse_counter));
%     axSuperTitle = suptitle(infoTitle); 
%     axSuperTitle.Position(2) = -0.1; % lower supertitle
    
end % end unit-loop


