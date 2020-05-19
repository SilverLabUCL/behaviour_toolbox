%% Experiment Class
% 	This the class container for all the recordings of an experiment
%
%   Type doc Experiment.function_name or Experiment Class.function_name 
%   to get more details about the methods inputs and outputs.
% -------------------------------------------------------------------------
% Model: 
%   this = Experiment();
% -------------------------------------------------------------------------
% Class Generation Inputs: 
% -------------------------------------------------------------------------
% Outputs: 
%   this (Experiment object)
% -------------------------------------------------------------------------
% Methods Index (ignoring get()/set() methods):
%
% * List all recordings in th experiment
%   Recording.populate(current_expe_path)
%
% * Remove a specific recording / set of recording
%   Recording.pop(rec_number) 
%
% * Add one / several empty recording.
%   Recording.add_recording(to_add)   
%
% * Remove empty/missing experiments
%   Recording.cleanup(clear_missing)
% -------------------------------------------------------------------------
% Extra Notes:
%   For now, Experiment is NOT a handle, which means you have to reassign
%   the ouput of the object to itself
% -------------------------------------------------------------------------
% Examples - How To
%
% * Add experiment 1 and all its recordings
%   s = Analysis_Set();
%   s.experiments(1) = s.experiments(1).populate(experiment_path);
%
% * Remove empty recordings and sort alphabetically
%   s.experiments(1) = s.experiments(1).cleanup();
%
% * Same as above + remove deleted/missing folders
%   s.experiments(1) = s.experiments(1).cleanup(true);
% -------------------------------------------------------------------------
% Author(s):
%   Antoine Valera
% -------------------------------------------------------------------------
% Revision Date:
% 21-04-2020
%
% See also Analysis_Set, Recording

classdef Experiment
    properties
        recordings = Recording  ; % Contain individual recordings
        path                    ; % The path of the experiment
        videotypes              ; % The names of all videos in this experiment
        roi_labels              ; % The names of all ROI labels in this experiment
        n_rec       = 0         ; % The number of recordings in this experiment
        global_reference_images ; % The global ref image, if generated
        t_start                 ; % experiment aboslute t_start
        comment                 ; % User comment
        splitvideos = {}        ; % A list of split videos
    end
    
    methods
        function obj = Experiment(n_recordings, expe_path)
            if nargin < 1 || isempty(n_recordings)
                n_recordings    = 0;    % Empty recording
            end
            if nargin < 2
                expe_path       = '';   % Empty recording
            end
            obj.recordings      = repmat(Recording, 1, n_recordings);
            obj.path            = expe_path;
        end
        
        function obj = add_recording(obj, to_add)
            if nargin < 2 || isempty(to_add)
                to_add = 1;
            end
            if isnumeric(to_add)
                obj.Recording(end + 1:end + to_add) = Recording;
            else
                % TODO : add cell array char support
            end
        end

        function obj = pop(obj, recording_idx)
            %% Remove a specific recording objct based on the video index
            obj.recordings(recording_idx) = [];
        end
        
        function obj = cleanup(obj, clear_missing)
            if nargin < 2 || isempty(clear_missing)
                clear_missing = false;
            end
            
            %% Sort alphabetically and remove empty recordings
            %% Make sure everything is in alphabetical order
            [~, idx] = sort({obj.recordings.path});
            obj.recordings = obj.recordings(idx);

            %% Make sure there is no empty recording after reordering
            obj.recordings = obj.recordings(~cellfun(@isempty, {obj.recordings.path}));    
            
            if clear_missing
                %% Remove folders that are not pointing at a real path
                to_remove = [];
                for rec = 1:obj.n_rec   
                    if ~isdir(obj.recordings(rec).path)
                        to_remove = [to_remove, rec]; 
                    end
                end 
                obj = obj.pop(to_remove);
            end
        end
 
        function obj = populate(obj, current_expe_path)  
            %% To prevent creating duplicates, see analysis.add_experiment();
            if (nargin < 2 || isempty(current_expe_path)) && isdir(obj.path)
                obj.path = strrep(obj.path,'\','/');
            elseif isdir(current_expe_path)
                obj.path = strrep(current_expe_path,'\','/');
            else
                fprintf([current_expe_path,' is not a valid path\n']);
                return
            end
            
            %% List all recordings
            recordings_folder = dir([obj.path, '/*_*_*']);

            obj.splitvideos = {};
            if ~isempty(recordings_folder) %% Only empty if there is no video or if the folder structure is wrong
                for recording_idx = 1:numel(recordings_folder)
                    %% Get all videos in the experiment
                    % Videos are expected to be avi files in a subfolder,as provided by the labview export software
                    current_recording_path  = strrep([recordings_folder(recording_idx).folder,'/',recordings_folder(recording_idx).name],'\','/');
                    recordings_videos       = dir([current_recording_path, '/**/*.avi']);

                    %% Code doesn't handle the *-2.avi videos
                    if any(any(contains({recordings_videos.name}, '-2.avi')))
                        % QQ Need to be sorted by merging exported files. This happens for some very big files i think, or when you use the
                        obj.splitvideo{recording_idx} = current_recording_path;
                        fprintf([strrep(current_recording_path,'\','/'),' contains a split video and will not be analyzed\n'])
                    end

                    %% Check if recording is new or if it's an update
                    [recording_idx, rec_already_there] = check_if_new_rec(obj, current_recording_path);
                    if ~rec_already_there
                        %% If it is the first time we see this experiment, we create the Experiment object
                        current_recording = Recording(numel(recordings_videos), current_recording_path);
                    else
                        current_recording = obj.recordings(recording_idx);
                    end
                    obj.recordings(recording_idx) = update_recording(current_recording, recordings_videos);
                end
                
                %% Sort alphabetically and remove empty/missing recordings
                obj = obj.cleanup(true);
            else
                fprintf([obj.path,' has no detectable video. Please check path and content\n'])
            end
        end 
        
        function obj = analyze(obj)
            % To add. For now see Recording.analyze
        end
        
        function plot_MIs(obj, fig_number, zero_t, manual_browsing, videotype_filter, filter)
            if nargin < 2 || isempty(fig_number)
                fig_number = 1:numel(obj);
            end
            if nargin < 3 || isempty(zero_t)
                zero_t = true;
            end
            if nargin < 4 || isempty(manual_browsing)
                manual_browsing = false;
            end
            if nargin < 5 || isempty(videotype_filter)
                videotype_filter = unique([obj.videotypes]);
            end
            if nargin < 6 || isempty(filter)
                filter = false;
            end

            for exp = 1:numel(obj) % usually 1 but can be more
                obj(exp).recordings.plot_MIs(fig_number(exp), zero_t, manual_browsing, videotype_filter, filter);
            end
        end

        function videotypes = get.videotypes(obj)
            %% List all video_types available in the Children
            filenames = {};
            for rec = 1:obj.n_rec
                filenames = [filenames, obj.recordings(rec).videotypes];
            end
            
            %% Create a helper to extract video name
            function second = Out2(varargin)
                [~,second] = fileparts(varargin{:}); % get only the second output of the function
            end
            filenames = cellfun(@(x) Out2(x),filenames,'UniformOutput',false);
            
            %% Regroup videos by video type (eyecam, bodycam etc...)
            videotypes = unique(filenames(cellfun('isclass', filenames, 'char')));
        end   

        function roi_labels = get.roi_labels(obj)
            %% List all video_types available in the Children
            roi_labels = {};
            for rec = 1:obj.n_rec
                roi_labels = [roi_labels, obj.recordings(rec).roi_labels];
            end

            %% Regroup videos by video type (eyecam, bodycam etc...)
            roi_labels = unique(roi_labels(cellfun('isclass', roi_labels, 'char')));
        end   

        function global_reference_images = get.global_reference_images(obj)
            %% List all video_types available in the Children
            % [N x M] Cell orray, of N recordings and M videos
            videotypes = obj.videotypes;
            global_reference_images = cell(obj.n_rec, numel(videotypes));
            for rec = 1:obj.n_rec
                for vid = 1:numel(videotypes)
                    real_idx = find(contains({obj.recordings(rec).videos.path}, obj.videotypes{vid}));
                    if ~isempty(real_idx)
                        global_reference_images{rec, vid} = obj.recordings(rec).reference_images{real_idx};
                    else
                        global_reference_images{rec, vid} = NaN;
                    end
                end
            end
        end 

        function t_start = get.t_start(obj)
            t_start = NaN;
            for rec = 1:obj.n_rec
                t_start = [t_start, nanmin(obj.recordings(rec).t_start)];
            end
            t_start = nanmin(t_start); % qq maybe min instead of nanmin, so we can know if one value hasn't been extracted
        end
        
        function n_rec = get.n_rec(obj)
            %% Return the number of recordings available (including empty)
            n_rec = numel(obj.recordings);
        end 
    end
end

