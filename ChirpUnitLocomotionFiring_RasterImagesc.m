%% Locomotion-firing analysis - SpikeRaster + MotionImagesc
% Co-visualizes firing rate and and locomotion of the mouse, where spike raster plots are plotted
% next to locomotion plotted in imagesc


%% TODO:
% (1) include speed underlaid under raster plot

%% General
clear all, close all, clc

%% Data Joint startup
startup_cin

%% Load Data
load('units_for_chirp_sorted.mat');

%% Parameters

samplingRate = 30000; % sampling rate of locomotion data
savefigure = 1;

%% Correlate mean speeds and mean firing rates
% Go through units of interest out of 49 chirp units
% > for each unit, extract mean speed and firing rate for each of ca. 18 trials

% Select units of interest
units = [1:5];

for unit = units
    %% Get Mean firing rates
    
    % ##YB: find better solution than having to clear every loop - e.g.
    % larger cell array filled with results from each loop
    clear spikeTimes meanSpikeRatesPerTrial motionTimeStamps speeds onsets offsets meanSpeedPerTrial
    [spikeTimes, meanSpikeRatesPerTrial] = ...
        fetchn(data.TrialSpikesExtra(units_for_chirp_sorted(unit)),'spike_times', 'spike_rate');
    
    % Convert spikeTimes data format to fit plotSpikeRaster function format
    spikeTimes = cellfun(@transpose,spikeTimes,'un',0);
    
    % Debug: Continue to next iteration and skip rest of current loop if unit does not have any entries
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
        
    %% Make (a) Raster Plot, juxtapose (b) mean firing rate and (c) speed using imagesc 
    % and (d) scatter plot + Regression
    
    fig = figure;
    set(fig,'units','normalized','outerposition',[0 0 1 0.4]); % adjust figure window
    set(fig, 'PaperUnits', 'inches', 'PaperPosition', [0 0 16 5.5]); % adjusts figure for printing
    % (a) Raster Plot
    ax1 = subplot(1,4,1);
    plotSpikeRaster(spikeTimes,'PlotType','vertline');
    xlabel('Peristimulus time (s)', 'FontSize', 14);
    ylabel('Trial', 'FontSize', 14);
    
    % (b) Mean Firing Rate (imagesc)
    ax2 = subplot(1,4,2);
    colormap autumn;
    imagesc(meanSpikeRatesPerTrial);
    ax2.Title.String = {'mean' 'rate' '(Hz)'};
    
    % (c) Locomotion speed (imagesc)
    ax3 = subplot(1,4,3);
    imagesc(meanSpeedPerTrial);
    ax3.Title.String = {'mean' 'speed' '(cm/s)'};
    
     % (d) Scatter plot + Regression
    ax4 = subplot(1,4,4);
    scatter(meanSpeedPerTrial,meanSpikeRatesPerTrial);
    xlabel('mean speed (cm/s) per trial');
    ylabel('mean spike rate (Hz) per trial');    
    
    % Regression
    [r,slope,intercept] = regression(meanSpeedPerTrial',meanSpikeRatesPerTrial');
    regressionLine = slope*meanSpeedPerTrial'+intercept;
    hold on
    plot(meanSpeedPerTrial',regressionLine,'b','linewidth',1.5)
    hold off        
    
    % Make plot adjustments
    set(ax1, 'Position', [0.065 ax1.Position(2) 0.5 ax1.Position(4)])
    set(ax2, 'Position', [ax1.Position(1)+ax1.Position(3)+0.02, ax1.Position(2),...
        ax1.Position(4)/numel(meanSpeedPerTrial)/2 ax1.Position(4)],...
        'XTick', [], 'XTickLabel', []);
    set(ax3, 'Position', [ax2.Position(1)+ax2.Position(3)+0.02, ax1.Position(2), ...
        ax1.Position(4)/numel(meanSpeedPerTrial)/2, ax1.Position(4)],...
        'XTick', [], 'XTickLabel', [], 'YTickLabel', []);
    set(ax4, 'Position', [ax3.Position(1)+ax3.Position(3)+0.03, ax1.Position(2), ...
        0.25, ax1.Position(4)]);
    bar1 = colorbar(ax2, 'north');
    bar1.Ticks = [min(bar1.Ticks) max(bar1.Ticks)]; % show only min and max tick values in colorbar legend
    bar2 = colorbar(ax3, 'north');
    bar2.Ticks = [min(bar2.Ticks) max(bar2.Ticks)];
    
    % Insert r-value as textbox
    text(ax4.XLim(end),ax4.YLim(end),['r = ',num2str(r)],'FontSize',12,...
        'HorizontalAlignment','right', 'VerticalAlignment','top');
    
    % Create Info panel: mouse, unit, series, experiment
    % NB: plot after using tightfig!
    infoTitle = strcat('Info: Mouse:', num2str(units_for_chirp_sorted(unit).mouse_counter),...        
        ', Series:', num2str(units_for_chirp_sorted(unit).series_num),...
        ', Experiment:', num2str(units_for_chirp_sorted(unit).exp_num),...
        ', Unit:', num2str(units_for_chirp_sorted(unit).unit_id));
    axSupTitle = suptitle(infoTitle); 
%     axSupTitle.Position(2) = -0.1; % lower supertitle

%% savefig
if savefigure == true
    filename = strcat('ChirpUnit_MotionFiring_RasterImagescScatter_',...
        'M', num2str(units_for_chirp_sorted(unit).mouse_counter),...        
        '-S', num2str(units_for_chirp_sorted(unit).series_num),...
        '-E', num2str(units_for_chirp_sorted(unit).exp_num),...
        '-U', num2str(units_for_chirp_sorted(unit).unit_id),...
        '.jpg');
    saveas(fig, filename);
end
    
   
end % end unit-loop


