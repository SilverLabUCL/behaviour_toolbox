%% Select ROI across many videos

% What won't work (yet) 
% - add a new videotype

%% If you have a folder of video and want to set the MI ROIs :
% batch_select_video_ROIs('Z:/Antoine/VIDEOS/');
%
%
% batch_select_video_ROIs('Z:/Antoine/VIDEOS/', all_videos, {'Laser','Wheel','WhiskerPad','Eye','UpperBody/Forelimbs'}, true, {});

% To extract MI, check batch_measure_MIs_from_ROIs

function [analysis, failed_video_loading, splitvideo] = batch_select_video_ROIs(video_folder_path, existing_experiments, subplot_tags, display_duration, filter_list, fig_handle, select_ROIs)

    %% Get all video folders
    % This is your top folder. You must sort your data by experiment, because
    % you will select the ROIs only once per experiment. If you moved the
    % cameras during an experiment, you may want to split the experiment in 2
    % for now (the code could be adjusted for that scenario but not yet)
    video_folders = dir([video_folder_path, '/*-*-*/experiment_*']); 

    %% Initialize variables
    % Globals are quite bad i know, but you don't want to loose info half 
    % way in the annotation because it so tedious to do. If you stop half
    % way, the cleanup function should send the current result in the base
    % workspace. If you reload a previous experiment and want to check
    % videos, updates ROIs or file lists, you can pass a previous analysis
    % as first input arguement
    %global all_experiments 
    if nargin < 2 || isempty(existing_experiments)
        analysis = Analysis_Set;
    else
        analysis = existing_experiments;
        analysis.recordings = analysis.recordings(~arrayfun(@isempty, analysis.recordings));
        clear existing_experiments;
    end
    
    if nargin < 3 || isempty(subplot_tags)
        subplot_tags = ''; % {'Laser','Wheel','WhiskerPad','Eye','UpperBody/Forelimbs'}
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
    analysis.video_folder = [video_folder_path, '/'];
    splitvideo = {}; % that will indicates problematic split videos
    failed_video_loading = {};

    %% This will send the current output to base workspace even if the
    % analysis is incomplete
    cleanupObj = onCleanup(@() cleanMeUp());

    %% Print selected folders. Filter rogue sets. 
    % This section could be used for further filtering
    for el = 1:numel(video_folders)
        if contains(video_folders(el).name,' unidentified')
            %1
        else
            fprintf([strrep(video_folders(el).folder,'\', '/'),'/',video_folders(el).name, '/\n'])
        end
    end

    video_folders = arrayfun(@(x) [strrep(fullfile(x.folder, x.name),'\', '/'),'/'], video_folders, 'UniformOutput', false);   
    
    %% Debugging section
    % this would print problematic folders
%     for expe_idx = 1:numel(all_experiments)
%         for video_type_idx = 1:numel(all_experiments{expe_idx}.MI_windows)
%             for video_record = 1:numel(all_experiments{expe_idx}.MI_windows{video_type_idx})
%                 for roi = 1:numel(all_experiments{expe_idx}.MI_windows{video_type_idx}(1,:))
%                     rois = all_experiments{expe_idx}.MI_windows{video_type_idx}(1,:);
%                     rois{roi}
%                 end
%             end
%         end
%     end
  
%     %% For the initial call, or if all_experiments is '', generate an struct
%     if isempty(analysis)
%         analysis = cell(1, numel(video_folders));
%     end

    %% Use this function to edit the fname field or check for modified files
    [analysis, video_folders] = check_or_fix_path_issues(analysis, video_folders, filter_list);

    %% Analyse each experiment (i.e, with the camera pointing at the same mouse)
    % Go through all experiment folder
    for exp_idx = 1:numel(video_folders)

        %% Get all videos in the experiment
        % Videos are expected to be avi fiels in a subfolder. This is the
        % structure provided by the export software
        expe_folder = video_folders{exp_idx}; 
        recordings_paths = dir([expe_folder, '/**/*.avi']);

        %% QQ Need to be sorted by merging exported files
        % This happens for some very big files i think, or when you use the
        % wrong codec
        if any(any(contains({recordings_paths.name}, '-2.avi')))
            id = contains({recordings_paths.name}, '-2.avi');
            splitvideo = [splitvideo, {recordings_paths(id).folder}];
            fprintf([strrep(splitvideo{end},'\','/'),' contains a split video and will not be analyzed\n'])
        end

        %% For valid videos, reload any existing ROI and let the user do some editing (if display_duration = 0)
        if ~isempty(recordings_paths) && ~any(contains({recordings_paths.name}, '-2.avi')) %no video files or segmented videos
            %% Check if we do a new analysis or an update. 
            % This check if there is already an experiment for these files.
            % If yes, it will locate and adjust the exp_idx in case it
            % changed
            [already_there, analysis, list_of_videotypes, exp_idx] = check_if_new_video(analysis, expe_folder, exp_idx, recordings_paths);

            close all
            [analysis.recordings(exp_idx), failed_video_loading{exp_idx}] = select_video_ROIs(analysis.recordings(exp_idx), already_there, list_of_videotypes, recordings_paths, display_duration, subplot_tags, fig_handle, select_ROIs);
        end
    end
end

function [already_there, analysis, list_of_videotypes, exp_idx] = check_if_new_video(analysis, expe_folder, exp_idx, recordings_paths)
    %% We check if this experient has already be listed somewhere. If yes, 
    % we adjust the index to update the video. If not, we create a new
    % experiment at current index
    
    %% Regroup videos by video type (eyecam, bodycam etc...)
    filenames = {recordings_paths.name};
    [filenames, videotypes, list_of_videotypes] = unique(filenames(cellfun('isclass', filenames, 'char')));
    
    already_there = false;
    
    %% If we find the recording somewhere, we update the index
    % This doesn't mean the analysis was complete
    for el = 1:analysis.n_expe
        if isfield(analysis.recordings(el),'filenames') && ~all(isempty(analysis.recordings(el).filenames))
            test = horzcat(analysis.recordings(el).filenames{:});
%             if isempty(test)
%                 break
%             end
            if ~isempty(test) && any(contains(strrep(test,'\','/'), expe_folder))
                %% Update exp_idx
                exp_idx         = el;
                video_paths     = analysis.recordings(exp_idx).filenames;
                video_type      = analysis.recordings(exp_idx).video_types;
                already_there   = true;  
                %% qq we can add here a detection for any mismatch between fields
                break
            end
        end
    end

    %% If it is the first time we see this experiment, we create new fields
    if ~already_there
        %% Initialise variables. 
        % QQ there will be an issue here if we start adding new videotypes
        if exp_idx > analysis.n_expe
            % pass, idx can be used
        elseif ~(isempty(analysis.recordings(exp_idx).filenames)) % If it's a new video, but you are editing a previous analys, we add a new index
            exp_idx = numel(analysis)+1;
        end
        analysis.recordings(exp_idx)                 = Recording(numel(videotypes));
    end
end

function [analysis, video_folders] = check_or_fix_path_issues(analysis, video_folders, filter_list)
    for expe_idx = analysis.n_expe:-1:1     
        recording = analysis.recordings(expe_idx);
        if ~isempty(fieldnames(recording)) && (isempty(filter_list) || any(cellfun(@(x) contains(strrep(recording.filenames{1}{1},'\','/'), strrep(x, '\','/')), filter_list)))
            for video_type_idx = numel(recording.filenames):-1:1
                for video_record = numel(recording.filenames{video_type_idx}):-1:1

                    temp = strsplit(strrep(recording.filenames{video_type_idx}{video_record},'\','/'),'/');

                    %% Check if folderpath is right (should contain VidRec)
                    if ~contains(temp{6}, ' VidRec') && contains(temp{6}, '_')
                        temp{6} = [temp{6},' VidRec'];
                    end      
                    videopath = strrep(strjoin(temp,'\'),'\','/');
                    recording.filenames{video_type_idx}{video_record} = videopath;

                    %% Check if file has not been deleted
                    if ~isfile(videopath)
                        %% If it was, delete any corresponding fields
                        try
                            recording.filenames{video_type_idx}(video_record) = [];
                            recording.video_types{video_type_idx}(video_record) = [];
                            recording.MI_windows{video_type_idx}(video_record,:) = [];
                            recording.reference_image{video_type_idx} = []; % will force the regeneration of the thumbail
                            % This part could fail if there was no export yet
                            recording.motion_indexes{video_type_idx}(video_record) = [];
                            recording.timestamps{video_type_idx}(video_record) = [];
                            recording.absolute_time{video_type_idx}(video_record) = [];
                        end
                        fprintf([videopath,'\n'])
                    end
                end
            end
        elseif ~isempty(filter_list) 
            analysis.pop(expe_idx);
        end
        analysis.recordings(expe_idx) = recording;        
    end
    
    %% Filter video folders accordingly
	for el = numel(video_folders):-1:1
        if ~isempty(filter_list) && ~any(cellfun(@(x) contains(video_folders{el}, strrep(x, '\','/')), filter_list))
            video_folders(el) = [];
        end
    end    
end

function cleanMeUp()
    %% if interrupted, send experiment to base workspace
    global all_experiments
    assignin('base', 'all_experiments_output', all_experiments);
    clear global all_experiments
end 