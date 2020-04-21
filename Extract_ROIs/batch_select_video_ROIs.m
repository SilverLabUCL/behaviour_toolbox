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
    splitvideo = {}; % that will indicates problematic split videos
    failed_video_loading = {};

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
    % Go through all experiment folder
    skipped = []; %% When updating dynamically index, we make sure that we don't leave non-existing videos behind
    for experiment_idx = 1:numel(experiment_folders)
        current_expe_path = experiment_folders{experiment_idx};
        recordings_folder = dir([current_expe_path, '/*_*_*']);
        
        
        if ~isempty(recordings_folder) %% Only empty if there is no video or if the folder structure is wrong
            [experiment_idx, expe_already_there] = check_if_new_expe(analysis, current_expe_path);              
            if ~expe_already_there
                %% If it is the first time we see this experiment, we create the Experiment object
                current_experiment = Experiment(numel(recordings_folder), current_expe_path);
            else
                current_experiment = analysis.experiments(experiment_idx);
            end
            
            for recording_idx = 1:numel(recordings_folder)

                %% Get all videos in the experiment
                % Videos are expected to be avi files in a subfolder. This is the
                % structure provided by the export software
                current_recording_path = strrep([recordings_folder(recording_idx).folder,'/',recordings_folder(recording_idx).name],'\','/');
                recordings_videos = dir([current_recording_path, '/**/*.avi']);

                %% QQ Need to be sorted by merging exported files
                % This happens for some very big files i think, or when you use the
                % wrong codec
                if any(any(contains({recordings_videos.name}, '-2.avi')))
                    id = contains({recordings_videos.name}, '-2.avi');
                    splitvideo = [splitvideo, {recordings_videos(id).folder}];
                    fprintf([strrep(splitvideo{end},'\','/'),' contains a split video and will not be analyzed\n'])
                end

                %% For valid videos, reload any existing ROI and let the user do some editing (if display_duration = 0)
                if ~isempty(recordings_videos) && ~any(contains({recordings_videos.name}, '-2.avi')) %no video files or segmented videos
                    %% Check if we do a new analysis or an update. 
                    % This check if there is already an experiment for these files.
                    % If yes, it will locate and adjust the exp_idx in case it
                    % changed

                    current_experiment = check_if_new_video(current_experiment, recording_idx, current_recording_path, numel(recordings_videos), recordings_videos);
                end
                
                %% Update or add experiment
                analysis.experiments(experiment_idx) = current_experiment;
            end

            %% Sort alphabetically and remove empty recordings
            analysis.experiments(experiment_idx) = analysis.experiments(experiment_idx).cleanup();

            %% Now that all recordings were added, we can select ROIs
            close all
            [analysis.experiments(experiment_idx), failed_video_loading{experiment_idx}] = select_video_ROIs(analysis.experiments(experiment_idx), select_ROIs, display_duration, fig_handle, default_tags);
            
            %% Safety backup after each video export
            assignin('base', 'analysis_temp_backup', analysis);
        end
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
                            fprintf(['Could no find ', experiment.recordings(recording_idx).videos(video_type_idx).path,'\n'])
                            experiment.recordings(recording_idx) = experiment.recordings(recording_idx).pop(video_type_idx);                        
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