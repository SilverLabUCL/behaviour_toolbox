%% Select ROI across many videos

% What won't work (yet) 
% - add a new videotype

% batch_select_MI_rois('Z:/Antoine/VIDEOS/', all_videos, {'Laser','Wheel','WhiskerPad','Eye','UpperBody/Forelimbs'}, true, {});

% To extract MI, check batch_measure_MIs_from_ROIs

function [failed_video_loading, splitvideo] = batch_select_video_ROIs(video_folder_path, existing_experiments, subplot_tags, display_duration, filter_list)

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
    global all_experiments 
    if nargin < 2 
        all_experiments = {};
    else
        all_experiments = existing_experiments;
        all_experiments = all_experiments(~cellfun(@isempty, all_experiments));
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

    video_folders = arrayfun(@(x) strrep(fullfile(x.folder, x.name),'\', '/'), video_folders, 'UniformOutput', false);   
    
    %% Debugging section
    % this would print problematic folders
%     for expe_idx = 1:numel(all_experiments)
%         for video_type_idx = 1:numel(all_experiments{expe_idx}.windows)
%             for video_record = 1:numel(all_experiments{expe_idx}.windows{video_type_idx})
%                 for roi = 1:numel(all_experiments{expe_idx}.windows{video_type_idx}(1,:))
%                     rois = all_experiments{expe_idx}.windows{video_type_idx}(1,:);
%                     rois{roi}
%                 end
%             end
%         end
%     end
  
    %% Use this function to edit the fname field or check for modified files
    [all_experiments, video_folders] = check_or_fix_path_issues(all_experiments, video_folders, filter_list);

    %% Analyse each experiment (i.e, with the camera pointing at the same mouse)
    % Go through all experiment folder
    for exp_idx = 5:numel(video_folders) 

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

        %% For valid videos, reload any exisitng ROI and let the user do some editing (if display_duration = 0)
        if ~isempty(recordings_paths) && ~any(contains({recordings_paths.name}, '-2.avi')) %no video files or segmented videos
            %% Check if we do a new analysis or an update. 
            % This check if there is already an experiment for these files.
            % If yes, it will locate and adjust the exp_idx in case it
            % changed
            [already_there, all_experiments, list_of_videotypes, exp_idx] = check_if_new_video(all_experiments, expe_folder, exp_idx, recordings_paths);

            close all
            [all_experiments{exp_idx}, failed_video_loading{exp_idx}] = select_video_ROIs(all_experiments{exp_idx}, already_there, list_of_videotypes, recordings_paths, display_duration, subplot_tags);
        end
    end
end

function [already_there, all_videos, list_of_videotypes, exp_idx] = check_if_new_video(all_videos, expe_folder, exp_idx, recordings_paths)
    %% We check if this experient has already be listed somewhere. If yes, 
    % we adjust the index to update the video. If not, we create a new
    % experiment at current index
    
    %% Regroup videos by video type (eyecam, bodycam etc...)
    filenames = {recordings_paths.name};
    [filenames, videotypes, list_of_videotypes] = unique(filenames(cellfun('isclass', filenames, 'char')));
    
    already_there = false;
    
    %% If we find the recording somewhere, we update the index
    % This doesn't mean the analysis was complete
    for el = 1:numel(all_videos)
        if isfield(all_videos{el},'fnames')
            test = horzcat(all_videos{el}.fnames{:});
            if any(contains(strrep(test,'\','/'), expe_folder))
                %% Update exp_idx
                exp_idx         = el;
                video_paths     = all_videos{exp_idx}.fnames;
                video_type      = all_videos{exp_idx}.types;
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
        if ~isempty(all_videos{exp_idx}) % If it's a new video, but you are editing a previous analys, we add a new index
            exp_idx = numel(all_videos)+1;
        end
        video_paths = {};
        video_type  = [];
        all_videos{exp_idx}.windows         = cell(1, numel(videotypes));
        all_videos{exp_idx}.MI              = cell(1, numel(videotypes));
        all_videos{exp_idx}.reference_image = cell(1, numel(videotypes));
        all_videos{exp_idx}.timestamps      = cell(1, numel(videotypes));
    end
end

function [all_experiments, video_folders] = check_or_fix_path_issues(all_experiments, video_folders, filter_list)
    for expe_idx = numel(all_experiments):-1:1        
        if isempty(filter_list) || any(cellfun(@(x) contains(strrep(all_experiments{expe_idx}.fnames{1}{1},'\','/'), strrep(x, '\','/')), filter_list))
            for video_type_idx = numel(all_experiments{expe_idx}.fnames):-1:1
                for video_record = numel(all_experiments{expe_idx}.fnames{video_type_idx}):-1:1

                    temp = strsplit(strrep(all_experiments{expe_idx}.fnames{video_type_idx}{video_record},'\','/'),'/');

                    %% Check if folderpath is right (should contain VidRec)
                    if ~contains(temp{6}, ' VidRec') && contains(temp{6}, '_')
                        temp{6} = [temp{6},' VidRec'];
                    end      
                    videopath = strrep(strjoin(temp,'\'),'\','/');
                    all_experiments{expe_idx}.fnames{video_type_idx}{video_record} = videopath;

                    %% Check if file has not been deleted
                    if ~isfile(videopath)
                        %% If it was, delete any corresponding fields
                        try
                            all_experiments{expe_idx}.fnames{video_type_idx}(video_record) = [];
                            all_experiments{expe_idx}.types{video_type_idx}(video_record) = [];
                            all_experiments{expe_idx}.windows{video_type_idx}(video_record,:) = [];
                            all_experiments{expe_idx}.reference_image{video_type_idx} = []; % will force the regeneration of the thumbail
                            % This part could fail if there was no export yet
                            all_experiments{expe_idx}.MI{video_type_idx}(video_record) = [];
                            all_experiments{expe_idx}.timestamps{video_type_idx}(video_record) = [];
                            all_experiments{expe_idx}.absolute_time{video_type_idx}(video_record) = [];
                        end
                        fprintf([videopath,'\n'])
                    end
                end
            end
        else
            all_experiments(expe_idx) = [];
        end
    end
    
	for el = numel(video_folders):-1:1
        if ~any(cellfun(@(x) contains(video_folders{el}, strrep(x, '\','/')), filter_list))
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