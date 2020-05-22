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
% * Experiments is a handle. If you extract assign a set of experiment
%   from an Analysis_Set for conveniency and edit it, it will be updated
%   into your original Analysis_Set too
% -------------------------------------------------------------------------
% Examples - How To
%
% * Add experiment 1 and all its recordings
%   s = Analysis_Set();
%   s.experiments(1).populate(experiment_path);
%
% * Remove empty recordings and sort alphabetically
%   s.experiments(1).cleanup();
%
% * Same as above + remove deleted/missing folders
%   s.experiments(1).cleanup(true);
% -------------------------------------------------------------------------
% Author(s):
%   Antoine Valera
% -------------------------------------------------------------------------
% Revision Date:
% 21-04-2020
%
% See also Analysis_Set, Recording, Video, ROI

classdef Experiment < handle
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
        parent_set              ; % handle to parent object
    end
    
    methods
        function obj = Experiment(n_recordings, expe_path)
            %% Experiment Object Constructor. 
            % -------------------------------------------------------------
            % Syntax: 
            %   this = Experiment(n_recordings, expe_path)
            % -------------------------------------------------------------
            % Inputs:
            %   n_recordings (INT) - Optional - default is 0
            %       path to the top folder containing all videos
            %
            %   expe_path (STR PATH)
            %       path to the experiment folder
            % -------------------------------------------------------------
            % Outputs: 
            %   this (Analysis_Set)
            %   	The container for all the analyzed data
            % -------------------------------------------------------------
            % Extra Notes:
            % * Once created, and once a path is set, see
            %   Experiment.populate to detect all the videos.
            % -------------------------------------------------------------
            % Examples:
            %
            % * Create a new Experiment object
            %     experiment = Experiment();
            %
            % * Create a new Experiment object and assign a folder
            %     experiment = Experiment('','/Expe/Folder/path');
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            %
            % See also: Analysis_Set.update, Analysis_Set.add_experiment,
            %   Experiment.populate()
            
            if nargin < 1 || isempty(n_recordings)
                n_recordings    = 0;    % Empty recording
            end
            if nargin < 2
                expe_path       = '';   % Empty recording
            end
            for el = 1:(n_recordings - 1)
                obj.recordings = [obj.recordings, Recording];
            end
            obj.path            = fix_path(expe_path);
        end
        
        function add_recording(obj, to_add)
            %% Remove a specific recording objct based on the video index
            % -------------------------------------------------------------
            % Syntax: 
            %   Experiment.add_recording(to_add)
            % -------------------------------------------------------------
            % Inputs:
            %   to_add (INT) - Optional - default is 1
            %   	Add an N empty recordig at the designated index
            % -------------------------------------------------------------
            % Outputs: 
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            
            if nargin < 2 || isempty(to_add)
                to_add = 1;
            end
            if isnumeric(to_add)
                obj.Recording(end + 1:end + to_add) = Recording;
            else
                % TODO : add cell array char support
            end
        end

        function pop(obj, recording_idx)
            %% Remove a specific recording objct based on the video index
            % -------------------------------------------------------------
            % Syntax: 
            %   Experiment.pop(recording_idx)
            % -------------------------------------------------------------
            % Inputs:
            %   recording_idx (INT)
            %   	delete recording at specified location
            % -------------------------------------------------------------
            % Outputs: 
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020

            obj.recordings(recording_idx) = [];
        end
        
        function cleanup(obj, clear_missing)
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
                obj.pop(to_remove);
            end
        end
 
        function populate(obj, current_expe_path, parent)  
            %% To prevent creating duplicates, see analysis.add_experiment();
            if (nargin < 2 || isempty(current_expe_path)) && isdir(obj.path)
                obj.path = fix_path(obj.path);
            elseif isdir(current_expe_path)
                obj.path = fix_path(current_expe_path);
            else
                fprintf([fix_path(current_expe_path),' is not a valid path\n']);
                return
            end
            if nargin >= 3
                obj.parent_set = parent;
            end
            
            %% List all recordings
            recordings_folder = dir([obj.path, '*_*_*']);

            obj.splitvideos = {};
            if ~isempty(recordings_folder) %% Only empty if there is no video or if the folder structure is wrong
                for recording_idx = 1:numel(recordings_folder)
                    %% Get all videos in the experiment
                    % Videos are expected to be avi files in a subfolder,as provided by the labview export software
                    current_recording_path  = fix_path([recordings_folder(recording_idx).folder,'/',recordings_folder(recording_idx).name]);
                    recordings_videos       = dir([current_recording_path, '**/*.avi']);

                    %% Code doesn't handle the *-2.avi videos
                    if any(any(contains({recordings_videos.name}, '-2.avi')))
                        % QQ Need to be sorted by merging exported files. This happens for some very big files i think, or when you use the
                        obj.splitvideo{recording_idx} = current_recording_path;
                        fprintf([current_recording_path,' contains a split video and will not be analyzed\n'])
                    end

                    %% Check if recording is new or if it's an update
                    [recording_idx, rec_already_there] = check_if_new_rec(obj, current_recording_path);
                    if ~rec_already_there
                        %% If it is the first time we see this experiment, we create the Experiment object
                        current_recording = Recording(numel(recordings_videos), current_recording_path);
                    else
                        current_recording = obj.recordings(recording_idx); % QQ MAY NEED DEEPCOPY
                    end
                    obj.recordings(recording_idx) = update_recording(current_recording, recordings_videos);
                end
                
                %% Sort alphabetically and remove empty/missing recordings
                obj.cleanup(true);
            else
                fprintf([obj.path,' has no detectable video. Please check path and content\n'])
            end
        end 
        
        function failed_video_loading = select_ROIs(obj, fig_handle, default_tags)   
            if nargin < 2 || isempty(fig_handle)
                fig_handle = '';
            end
            if nargin < 3 || isempty(default_tags)
                default_tags = obj.parent_set.default_tags;
            end

            if ~isempty(obj)
                clear global current_offset current_pos roi_handles
                global current_pos current_offset

                failed_video_loading    = {};
                list_of_videotypes      = obj.videotypes;

                %% For each videotype, get a representative frame
                for video_type_idx = 1:numel(list_of_videotypes)
                    %% Reset position to center, with 1 ROI
                    current_pos         = {}; 

                    existing_windows    = false(1, obj.n_rec);
                    existing_motion_indexes = false(1, obj.n_rec);
                    for rec = 1:obj.n_rec
                        real_idx = find(contains({obj.recordings(rec).videos.path}, list_of_videotypes{video_type_idx}));
                        if real_idx % When one video is missing for a specific recording
                            existing_windows(1, rec)        = ~isempty(obj.recordings(rec).videos(real_idx).ROI_location); % no nested indexing method available as far as i know
                            existing_motion_indexes(1, rec) = ~all(cellfun(@isempty, obj.recordings(rec).videos(real_idx).motion_indexes)); % no nested indexing method available as far as i know
                        end
                    end

                    if all(existing_motion_indexes)
                        obj.recordings.plot_MIs(123, true, list_of_videotypes{video_type_idx});
                    end

                    %% Plot the representative_frame for the current expe
                    names = [];
                    [obj, names] = display_video_frame(obj, video_type_idx, 0, fig_handle, default_tags);

                    %% Clear empty cells if you deleted some ROIs. get id of deleted cells
                    to_keep     = cellfun(@numel , current_pos) == 5;
                    poped       = find(cellfun(@numel , current_pos) == 1);
                    if ~isempty(poped)
                        poped   = [current_pos{poped}];
                    end
                    current_pos = current_pos(to_keep);
                    current_offset = current_offset(to_keep);
                    names       = names(to_keep);

                    %% If there were some preexisitng values, check if we need an update
                    roi_change_detected = false;

                    %% Check if there was any change            
                    for el = 1:numel(current_pos)
                        window_location = current_pos{el};
                        offsets         = current_offset{el};

                        try
                            roi_change_detected = isempty(window_location) || ~all(existing_windows) || numel(current_pos) ~= obj.recordings(1).videos(video_type_idx).n_roi || roi_change_detected;
                        catch
                            error_box('Unable to store result for this video. This is usually due to a missing video');
                            roi_change_detected = true;
                        end

                        %% If N ROI didn't obviously change, check location
                        if ~roi_change_detected
                            %% Check if location changed
                            former_rois         = obj.recordings(1).videos(video_type_idx).ROI_location;
                            roi_change_detected = ~any(sum(vertcat(former_rois{:}) == window_location,2) == 5);

                            %% Check if offsets were updated
                            if ~roi_change_detected
                                former_offsets      = cell2mat(arrayfun(@(x) x.videos(video_type_idx).video_offset, [obj.recordings], 'UniformOutput', false)');
                                roi_change_detected = roi_change_detected || (~isempty(offsets) && ~all(all(former_offsets == offsets)));
                            end
                        else
                            break
                        end
                    end

                    %% Add new windows and update motion indexes windows location  
                    try
                        roi_available = isprop(obj.recordings(rec).videos(video_type_idx),'n_roi');
                    catch
                        roi_available = false;    
                    end
                    if roi_change_detected || (isempty(current_pos) && roi_available)% && current_experiment.recordings(rec).videos(video_type_idx).n_roi > 0)
                        for rec = 1:obj.n_rec
                            target = obj.videotypes{video_type_idx};
                            local_video_type_idx = find(contains(obj.recordings(rec).videotypes, target));
                            if ~isempty(local_video_type_idx) % empty if video is missing
                                n_rois = obj.recordings(rec).videos(local_video_type_idx).n_roi;
                                previous_ids = vertcat(obj.recordings(rec).videos(local_video_type_idx).ROI_location{:});
                                if isempty(current_pos) % Because you deleted everything !
                                    obj.recordings(rec).videos(local_video_type_idx).rois = repmat(ROI, 1, 0);
                                else
                                    obj.recordings(rec).videos(local_video_type_idx).video_offset = mean(cell2mat(cellfun(@(x) x(rec,:), current_offset, 'UniformOutput', false)'),1); % only store mean displacement
                                    for roi = 1:numel(current_pos) 
                                        %% Check if it is a new ROI
                                        if isempty(previous_ids) || isempty(find(previous_ids(:,5) == current_pos{roi}(5)))                   
                                            n_roi = obj.recordings(rec).videos(local_video_type_idx).n_roi;
                                            if n_roi == 0 %% QQ NEED TO CREATE AMETHOD FOR THAT
                                                obj.recordings(rec).videos(local_video_type_idx).rois = ROI;
                                            else
                                                obj.recordings(rec).videos(local_video_type_idx).rois(n_roi + 1) = ROI;
                                            end
                                            obj.recordings(rec).videos(local_video_type_idx).rois(n_roi + 1).ROI_location = current_pos{roi}; % no nested indexing method available as far as i know
                                            obj.recordings(rec).videos(local_video_type_idx).rois(n_roi + 1).name = names{roi};
                                        else    
                                            %% List ROIs to delete
                                            to_pop = [];
                                            for pop = poped
                                                to_pop = [to_pop, find(previous_ids(:,5) == pop)];
                                            end

                                            if isempty(to_pop)
                                                %% Then it's an update (or the same location)
                                                obj.recordings(rec).videos(local_video_type_idx).motion_indexes{roi} = {}; % Clear any MI content
                                                obj.recordings(rec).videos(local_video_type_idx).rois(roi).ROI_location = current_pos{roi}; % update location
                                                obj.recordings(rec).videos(local_video_type_idx).rois(roi).name = names{roi};
                                            else
                                                %% Then it's a deletion
                                                obj.recordings(rec).videos(local_video_type_idx).rois(to_pop) = [];
                                                previous_ids = vertcat(obj.recordings(rec).videos(local_video_type_idx).ROI_location{:});
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        function analyze(obj, force, display)
            %% Extract MIs for current experiments
            % -------------------------------------------------------------
            % Syntax: 
            %   Experiment.analyze(force, display)
            % -------------------------------------------------------------
            % Inputs:
            %   force (BOOL) - Optional - default is false
            %   	If true, reanalyze previous MIs. If false, only analyze
            %   	missing ones
            %
            %   display (BOOL or STR) - Optional - default is false
            %   	- If true or 'auto', MIs are displayed for each 
            %   	recording (after extraction). If extraction was already
            %   	done, MIs are also shown.
            %       - If 'pause' MIs display will pause until the figure
            %   	 is closed
            % -------------------------------------------------------------
            % Outputs:
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % * Analyze all ROIs where an un-analysed ROI is set
            %   Experiment.analyze()
            %
            % * Analyze all ROIs. Reanalyse old ones.
            %   Experiment.analyze(true)
            %
            % * Analyze missing ROIs, plot result
            %   Experiment.analyze('', true)
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also: Experiment.analyze
            
            if nargin < 2 || isempty(force)
                force = false;
            end
            if nargin < 3 || isempty(display)s
                display = false;
            end
            
            for rec = 1:obj.n_rec
                for vid = 1:obj.recordings(rec).n_vid
                    if any(cellfun(@isempty, obj.recordings(rec).videos(vid).motion_indexes)) || force
                        %% Update MI's
                        obj.recordings(rec).videos(vid).analyze();

                        %% Store results
                        if any(strcmp(display, {'auto', 'pause'})) || (islogical(display) && display)
                            obj.recordings(rec).videos(vid).plot_MIs();
                        end
                    else
                        fprintf(['No analysis required for ',obj.recordings(rec).videos(vid).path,'. Skipping extraction\n'])
                    end
                end 
            end

            if any(strcmp(display, {'auto', 'pause'})) || (islogical(display) && display)
                obj.recordings.plot_MIs(123, '', '', '', '', strcmp(display, 'pause'));
            end
        end
        
        function [all_data, all_t_axes] = plot_MIs(obj, fig_number, zero_t, manual_browsing, videotype_filter, output_filter, regroup, ROI_filter)
            %% Display and return MIs for all ecordings in the experiment
            % -------------------------------------------------------------
            % Syntax: 
            %   [all_data, all_t_axes] = Experiment.plot_MIs(fig_number, 
            %       zero_t, manual_browsing, videotype_filter, filter, 
            %       regroup, ROI_filter)
            % -------------------------------------------------------------
            % Inputs:
            %   fig_number (1 x N_vid INT OR 1 x n_vid FIGURE HANDLE) - 
            %       Optional - default will use figure [1:n_vid]
            %   	This defines the figures/figure handles to use. If
            %   	figure number don't match the number of vieos, default
            %   	behaviour is used
            %
            %   zero_t (BOOL) - Optional - default is true
            %   	If true, time axis starts at 0 for the first recording,
            %   	otherwise absolute time is displayed. See 
            %   	Recording.t_start documentation for more information.
            %
            %   manual_browsing (BOOL) - Optional - default is false
            %   	If true, MIs display will pause until the figure is 
            %   	closed
            %
            %   videotype_filter (STR or CELL ARRAY of STR) - Optional - 
            %       default is unique([obj.videotypes])
            %   	Only videos matching videotype_filter are displayed.
            %
            %   output_filter (function handle) - Optional - default is ''
            %   	if a function hande is provided, the function is
            %   	applied to each MI array during extraction. see
            %   	Recording.plot_MI for more information
            %
            %   regroup (BOOL) - Optional - default is true
            %   	if true, ROIs with the same name are displayed together
            %
            %   ROI_filter (STR or CELL ARRAY of STR) - Optional - 
            %       default is unique([obj.roi_labels])
            %   	display only selected ROIs
            % -------------------------------------------------------------
            % Outputs:
            %   all_data ([1 x n_expe] CELL ARRAY of [1 x n_vid] CELL ARRAY
            %                of [T x n_roi] MATRIX) - 
            %   	For all experiments, returns the MI for the selected
            %   	videos. Videos that are filtered out return an empty
            %   	cell. Recordings are concatenated.
            %
            %   all_t_axes ([1 x n_expe] CELL ARRAY of [1 x n_vid] CELL ARRAY
            %                of [T x 1] MATRIX) - 
            %   	For all experiments, returns the time for the selected
            %   	videos. Videos that are filtered out return an empty
            %   	cell. time is either absolute or starting from the
            %   	beginning of the recording depending on zero_t
            % -------------------------------------------------------------
            % Extra Notes:
            % * When using Videotype filter, the videos that are filtered
            %   out are returning an empty cell array.
            % -------------------------------------------------------------
            % Examples:
            % * Get and Plot MI for current experiment
            %   [MI, t] = Experiment.plot_MIs()
            %
            % * Analyze all ROIs. Reanalyse old ones.
            %   Experiment.analyze(true)
            %
            % * Analyze missing ROIs, plot result
            %   Experiment.analyze('', true)
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also: Experiment.analyze

            if nargin < 2 || isempty(fig_number)
                auto        = 0;
            else
                auto        = '';
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
            if nargin < 6 || isempty(output_filter)
                output_filter = false;
            end
            if nargin < 7 || isempty(regroup)
                regroup     = true;
            end
            if nargin < 8 || isempty(ROI_filter)
                ROI_filter = unique([obj.roi_labels]);
            end

            all_data    = {};
            all_t_axes  = {};
            for exp = 1:numel(obj) % usually 1 but can be more
                if ~isempty(auto)
                    fig_number  = (1:numel(obj(exp).videotypes)) + auto;
                    auto        = max(fig_number);                    
                end
                [all_data{exp}, all_t_axes{exp}] = obj(exp).recordings.plot_MIs(fig_number, zero_t, videotype_filter, output_filter, '', manual_browsing, regroup, ROI_filter);
            end
        end

        function videotypes = get.videotypes(obj)
            %% List all video_types available in the Experiment recordings
            % -------------------------------------------------------------
            % Syntax: 
            %   videotypes = Experiment.videotypes
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   videotypes (CELL ARRAY of STR)
            %   	The name of all videos in the experiment, without the
            %   	extensions
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also:

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

        function set.path(obj, experiment_path)
            %% Set a new experiment path and fix synatx
            % -------------------------------------------------------------
            % Syntax: 
            %   Experiment.path = experiment_path
            % -------------------------------------------------------------
            % Inputs:
            %   experiment_path (STR PATH)
            %   	The folder containing all the recordings
            % -------------------------------------------------------------
            % Outputs: 
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also:

            obj.path = fix_path(experiment_path);
        end

        function roi_labels = get.roi_labels(obj)
            %% List all ROI labels available in the Experiment recordings
            % -------------------------------------------------------------
            % Syntax: 
            %   roi_labels = Experiment.roi_labels
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   roi_labels (CELL ARRAY of STR)
            %   	The name of all labels in the experiment, without the
            %   	extensions
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also:
            
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
            %% List the earliest t_start of the recordings in the experiment
            % -------------------------------------------------------------
            % Syntax: 
            %   t_start = Experiment.t_start
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   t_start (DOUBLE)
            %   	t_start of the experiment (based on the first
            %   	recording)
            % -------------------------------------------------------------
            % Extra Notes:
            % * t_start is expressed as posixtime, which can be
            %   converted to a date using
            %   datetime(t, 'ConvertFrom', 'posixtime' ,
            %            'Format','dd-MMM-yyyy HH:mm:ss.SSSSS')
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also: Recording.t_start
            
            t_start = NaN;
            for rec = 1:obj.n_rec
                t_start = [t_start, nanmin(obj.recordings(rec).t_start)];
            end
            t_start = nanmin(t_start); % qq maybe min instead of nanmin, so we can know if one value hasn't been extracted
        end
        
        function n_rec = get.n_rec(obj)
            %% Return the number of recordings available (including empty)
            % -------------------------------------------------------------
            % Syntax: 
            %   n_rec = Experiment.n_rec
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   t_start (INT)
            %   	number of recordings listed in the experiment
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020

            n_rec = numel(obj.recordings);
        end 
    end
end

