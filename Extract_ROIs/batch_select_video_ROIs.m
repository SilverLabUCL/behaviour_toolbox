%% Select ROI across many videos

% What won't work (yet) 
% - add a new videotype

%% If you have a folder of video and want to set the MI ROIs :
% batch_select_video_ROIs('Z:/Antoine/VIDEOS/');
%
%
% batch_select_video_ROIs('Z:/Antoine/VIDEOS/', all_videos, {'Laser','Wheel','WhiskerPad','Eye','UpperBody/Forelimbs'}, true, {});

% To extract MI, check batch_measure_MIs_from_ROIs

function [analysis, failed_video_loading] = batch_select_video_ROIs(analysis, default_tags, display_duration, filter_list, fig_handle, select_ROIs)
    analysis.experiments = analysis.experiments(~arrayfun(@isempty, analysis.experiments));
    if nargin < 2 || isempty(default_tags)
        default_tags = ''; % {'Laser','Wheel','WhiskerPad','Eye','UpperBody/Forelimbs'}
    end
    if nargin < 3 || isempty(display_duration)
        display_duration = 0;
    end
    if nargin < 4 || isempty(filter_list)
        filter_list = {};
    end
    if nargin < 5 || isempty(fig_handle)
        fig_handle = '';
    end
    if nargin < 6 || isempty(select_ROIs)
        select_ROIs = true; % If false, we just list everythin and create empty cells
    end
    
    analysis = analysis.update(filter_list);

    %% Now extract ROIs
    experiment_folders = {analysis.experiments.path};
    assignin('base', 'analysis_temp_backup', analysis); %% Setup a safety backup
    for experiment_idx = 1:numel(experiment_folders)
        %% Now that all recordings were added, we can select ROIs
        close all;
        [analysis.experiments(experiment_idx), failed_video_loading{experiment_idx}] = select_video_ROIs(analysis.experiments(experiment_idx), select_ROIs, display_duration, fig_handle, default_tags);

        %% Safety backup after each video export
        assignin('base', 'analysis_temp_backup', analysis);
    end
end