%% Select ROI across many videos

% What won't work (yet) 
% - add a new videotype

%% If you have a folder of video and want to set the MI ROIs :
% batch_select_video_ROIs('Z:/Antoine/VIDEOS/');
%
%
% batch_select_video_ROIs('Z:/Antoine/VIDEOS/', all_videos, {'Laser','Wheel','WhiskerPad','Eye','UpperBody/Forelimbs'}, true, {});

% To extract MI, check batch_measure_MIs_from_ROIs

function [analysis, failed_video_loading, splitvideo, invalid] = batch_select_video_ROIs(video_folder_path, analysis, default_tags, display_duration, filter_list, fig_handle, select_ROIs)

    %% Get all video folders
    % This is your top folder. You must sort your data by experiment, because
    % you will select the ROIs only once per experiment. If you moved the
    % cameras during an experiment, you may want to split the experiment in 2
    % for now (the code could be adjusted for that scenario but not yet)
    experiment_folders = dir([video_folder_path, '/*-*-*/experiment_*']); 

    %% Initialize variables
    if nargin < 2 || isempty(analysis)
        analysis = Analysis_Set;
    else
        analysis.experiments = analysis.experiments(~arrayfun(@isempty, analysis.experiments));
    end
    
    if nargin < 3 || isempty(default_tags)
        default_tags = ''; % {'Laser','Wheel','WhiskerPad','Eye','UpperBody/Forelimbs'}
    end
    if nargin < 4 || isempty(display_duration)
        display_duration = 0;
    end
    if nargin < 5 || isempty(filter_list)
        filter_list = {};
    end
    if nargin < 6 || isempty(fig_handle)
        fig_handle = '';
    end
    if nargin < 7 || isempty(select_ROIs)
        select_ROIs = true; % If false, we just list everythin and create empty cells
    end
    
    %% Add Video folder field
    analysis.video_folder = strrep([video_folder_path, '/'],'\','/');
    assignin('base', 'analysis_temp_backup', analysis); %% Setup a safety backup

    %% Print selected folders. Filter rogue sets. 
    % This section could be used for further filtering
    for el = 1:numel(experiment_folders)
        if contains(experiment_folders(el).name,' unidentified')
            %1
        else
            fprintf([strrep(experiment_folders(el).folder,'\', '/'),'/',experiment_folders(el).name, '/\n'])
        end
    end

    experiment_folders = arrayfun(@(x) [strrep(fullfile(x.folder, x.name),'\', '/'),'/'], experiment_folders, 'UniformOutput', false);   

    %% Use this function to edit the fname field or check for modified files
    [analysis, experiment_folders] = check_or_fix_path_issues(analysis, experiment_folders, filter_list);

    %% Analyse each experiment (i.e, with the camera pointing at the same mouse)
    % Go through all experiment folder. Add experiments if missing
    splitvideo              = {}; % that will indicates problematic split videos
    failed_video_loading    = {};
    for experiment_idx = 1:numel(experiment_folders)
        current_expe_path                   = experiment_folders{experiment_idx};
        [analysis, experiment_idx]          = analysis.add_experiment(current_expe_path); %% add or update experiment
        splitvideo                          = [splitvideo, analysis.experiments(experiment_idx).splitvideos]; % if any

        %% Sort alphabetically and remove empty experiments
        analysis.experiments(experiment_idx)= analysis.experiments(experiment_idx).cleanup();

        %% Now that all recordings were added, we can select ROIs
        close all;
        [analysis.experiments(experiment_idx), failed_video_loading{experiment_idx}] = select_video_ROIs(analysis.experiments(experiment_idx), select_ROIs, display_duration, fig_handle, default_tags);

        %% Safety backup after each video export
        assignin('base', 'analysis_temp_backup', analysis);
    end

    %% Last check, if some folders were removed
    for exp = analysis.n_expe:-1:1
        if ~isdir(analysis.experiments(exp).path)
            analysis.experiments(exp) = [];
        end        
    end   
    [~, idx] = sort({analysis.experiments.path});
    analysis.experiments = analysis.experiments(idx);
    
    %% Empty experiments an be detected here 
    invalid = arrayfun(@(x) isempty(x.path), analysis.experiments);
end

function [analysis, video_folders] = check_or_fix_path_issues(analysis, video_folders, filter_list)
    %% Remove filtered or absent files/folders
    for expe_idx = analysis.n_expe:-1:1     
        experiment = analysis.experiments(expe_idx);
        if ~isempty(experiment.recordings) && ~isempty(experiment.path) && isfolder(experiment.path) %&& (isempty(filter_list) || any(cellfun(@(x) contains(strrep(experiment.filenames{1}{1},'\','/'), strrep(x, '\','/')), filter_list)))
            for recording_idx = experiment.n_rec:-1:1
                if isfolder(experiment.recordings(recording_idx).path)
                    for video_type_idx = experiment.recordings(recording_idx).n_vid:-1:1                
                        video = experiment.recordings(recording_idx).videos(video_type_idx);

                        %% Check if file has not been deleted
                        if ~isfile(video.path)
                            %% Remove the whole video object
                            fprintf(['Could no find ', experiment.recordings(recording_idx).videos(video_type_idx).path,'\n']);
                            if experiment.recordings(recording_idx).n_vid > 0
                                experiment.recordings(recording_idx).videos(video_type_idx) = [];  
                            else
                                experiment.recordings(recording_idx) = experiment.recordings.pop(recording_idx);  
                            end
                        end
                    end
                else
                    %% Remove the whole recording
                    experiment = experiment.pop(recording_idx);
                end
            end
            analysis.experiments(expe_idx) = experiment;  
        elseif ~isempty(filter_list) || (~isempty(experiment.path) && ~isfolder(experiment.path))
            %% Remove the whole experiment
            analysis = analysis.pop(expe_idx);
        end  
    end
    
    %% Filter video folders accordingly
	for el = numel(video_folders):-1:1
        if ~isempty(filter_list) && ~any(cellfun(@(x) contains(video_folders{el}, strrep(x, '\','/')), filter_list))
            video_folders(el) = [];
        end
    end    
end