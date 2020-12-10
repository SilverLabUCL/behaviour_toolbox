%% Experiment Class
% 	This the class container for all the recordings of an experiment
%
%   Type doc Experiment.function_name or Experiment Class.function_name 
%   to get more details about the methods inputs and outputs.
% -------------------------------------------------------------------------
% Syntax: 
%   this = Experiment(n_recordings, expe_path);
% -------------------------------------------------------------------------
% Class Generation Inputs: 
%   n_recordings(INT) - Optional - Default is 0
%                               Number of Recordings object to initialize. 
%                               They will need to be populated
%
%   expe_path(STR) - Optional - Default is ''
%                               Path to your experiment folder
% -------------------------------------------------------------------------
% Outputs: 
%   this (Experiment object)
% -------------------------------------------------------------------------
% Class Methods (ignoring get()/set() methods):
%
% * Add one / several empty recording.
%   Experiment.add_recording(to_add)   
%
% * Remove a specific recording / set of recording
%   Experiment.pop(rec_number) 
%
% * Remove empty/missing experiments
%   Experiment.cleanup(clear_missing)
%
% * List all recordings in the experiment
%   Experiment.populate(current_expe_path)
%
% * Select ROI location for all recordings in experiment      
%   failed = Experiment.select_ROIs(fig_handle, default_tags)         
%
% * Extract all results for the experiment         
%   Experiment.analyse(force, display)
%
% * Remove empty/missing experiments
%   Experiment.clear_results(clear_missing)
%
% * Plot Results for current variable
%   [all_data, all_t_axes] = Experiment.plot_results(fig_number, zero_t, 
%                               manual_browsing, videotype_filter, 
%                               output_filter, regroup, ROI_filter)
%
% * Clear results or delete specifc ROIS
%   Experiment.clear_results(   idx_to_clear, videotype_filter,
%                           ROI_filter, delete_ROI)
% -------------------------------------------------------------------------
% Extra Notes:
% * Experiments is a handle. You can assign a set of Experiments to a 
%   variable from an Analysis_Set for conveniency and edit it. As a handle,
%   modified variables will be updated in your original Analysis_Set too
% -------------------------------------------------------------------------
% Examples:
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
%
% -------------------------------------------------------------------------
%                               Notice
%
% Author(s): Antoine Valera
%
% This function was initially released as part of a toolbox for 
% manipulating Videos acquired in the SIlverlab. The software was 
% developed in the laboratory of Prof Robin Angus Silver at University
% College London with funds from the NIH, ERC and Wellcome Trust.
%
% Copyright © 2015-2020 University College London
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%     http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License. 
% -------------------------------------------------------------------------
% Revision Date:
% 21-05-2020
%
% See also Analysis_Set, Recording, Video, ROI

classdef Experiment < handle
    properties
        recordings  = Recording ; % Contain individual recordings
        path                    ; % The path of the experiment
        videotypes              ; % The names of all videos in this experiment
        roi_labels              ; % The names of all ROI labels in this experiment
        n_rec       = 0         ; % The number of recordings in this experiment
        global_reference_images ; % The global ref image, if generated
        t_start                 ; % experiment aboslute t_start
        comment                 ; % User comment
        splitvideos = {}        ; % A list of split videos
        parent_h                ; % handle to parent Analysis_Set object
        current_varname         ; % The metric currently used
    end
    
    methods
        function obj = Experiment(parent, n_recordings, expe_path)
            %% Experiment Object Constructor. 
            % -------------------------------------------------------------
            % Syntax: 
            %   this = Experiment(n_recordings, expe_path)
            % -------------------------------------------------------------
            % Inputs:
            %   n_recordings (INT) - Optional - default is 0
            %       number of empty Recordings to generate
            %
            %   expe_path (STR PATH)
            %       path to the experiment folder
            % -------------------------------------------------------------
            % Outputs: 
            %   this (Analysis_Set)
            %   	The container for all the analysed data
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
            
            if nargin < 2 || isempty(n_recordings)
                n_recordings    = 0;    % Empty recording
            end
            if nargin < 3
                expe_path       = '';   % Empty recording
            end
            for el = 1:(n_recordings - 1)
                obj.recordings = [obj.recordings, Recording(obj)];
            end
            obj.parent_h        = parent;
            obj.path            = fix_path(expe_path);
        end
        
        function add_recording(obj, to_add)
            %% Add one or several Recording objects
            % -------------------------------------------------------------
            % Syntax: 
            %   Experiment.add_recording(to_add)
            % -------------------------------------------------------------
            % Inputs:
            %   to_add (INT) - Optional - default is 1
            %   	Add an N empty Recording objects
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
                obj.recordings(end + 1:end + to_add) = Recording(obj);
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
            %% Remove empty recordings, and optionaly, invalid recordings
            % -------------------------------------------------------------
            % Syntax: 
            %   Experiment.cleanup(clear_missing)
            % -------------------------------------------------------------
            % Inputs:
            %   clear_missing (BOOL) - Optional - Default is false
            %   	remove recordings where path doesn't point to a real
            %   	file
            % -------------------------------------------------------------
            % Outputs: 
            % -------------------------------------------------------------
            % Extra Notes:
            %  * Be careful if you use clear_missing == true. Make sure the
            %   video paths did not change, or valid recordings may get
            %   deleted. You may want to update paths first using 
            %   Analysis_Set.update_all_path
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See alos: Analysis_Set.update_all_path
            
            if nargin < 2 || isempty(clear_missing)
                clear_missing = false;
            end
            
            %% Sort alphabetically and remove empty recordings
            %% Make sure everything is in alphabetical order
            [~, idx] = sort({obj.recordings.path});
            obj.recordings = obj.recordings(idx);

            %% Make sure there is no empty recording after reordering
            obj.recordings = obj.recordings(~cellfun(@isempty, {obj.recordings.path}) & cellfun(@(x) x > 0, {obj.recordings.n_vid}));    
            
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
            %% Browse experiment folder and add all possible valid videos
            % -------------------------------------------------------------
            % Syntax: 
            %   Experiment.populate(current_expe_path, parent)
            % -------------------------------------------------------------
            % Inputs:
            %   current_expe_path (BOOL) - Optional - Default is obj.path
            %   	The experiment path that contains all the videos.
            %   	Search is based on folder names, so read documentation
            %   	to see what the requirements are.
            %
            %   parent (Analysis_Set HANDLE) - Optional - Default is ''
            %   	The handle to the analysis set enable the use of some
            %   	gloal settings such as default tags when using
            %   	Experiment.select_ROIs instead of
            %   	Analysis_Set.select_ROIs
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
            % See alos: Analysis_Set.select_ROIs
            
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
                obj.parent_h = parent;
            end
            
            fprintf(['Adding recordings in folder ... ',obj.path,' \n'])
            
            %% List all recordings
            recordings_folder = dir([obj.path, obj.parent_h.expdate,'*_*_*VidRec*']);
            
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
                        %obj.splitvideo{recording_idx} = current_recording_path;
                        fprintf(['WARNING !!!!!!!!!!!!!! - TO FIX - ', current_recording_path,' contains a split video and will not be analysed\n'])
                        recordings_videos = recordings_videos(~contains({recordings_videos.name}, '-1.avi'));
                    end

                    %% Check if recording is new or if it's an update
                    [recording_idx, rec_already_there] = check_if_new_rec(obj, current_recording_path);
                    if ~rec_already_there
                        %% If it is the first time we see this recording, we create the Recording object
                        obj.recordings(recording_idx) = Recording(obj, numel(recordings_videos), current_recording_path);
                    end
                    obj.recordings(recording_idx).update();
                end
                
                %% Sort alphabetically and remove empty/missing recordings
                obj.cleanup(true);
            else
                fprintf([obj.path,' has no detectable video. Please check path and content\n'])
            end
        end 
        
        function [failed, modified] = select_ROIs(obj, fig_handle, default_tags)   
            %% Browse experiment folder and add all possible valid videos
            % -------------------------------------------------------------
            % Syntax: 
            %   [failed, modified] = 
            %               Experiment.select_ROIs(fig_handle, default_tags)  
            % -------------------------------------------------------------
            % Inputs:
            %   fig_handle (BOOL) - Optional - Default is ''
            %   	The figure handle where you want to display the ROI
            %   	selection
            %
            %   default_tags (CELL ARRAY of STR) - Optional - Default is
            %   collected from obj.parent_h.default_tags
            %   	The list of default buttons/ROI names. If not provided,
            %   	but if a Analysis_Set handle was set in obj.parent_h,
            %   	the Analysis_Set.default_tags field can be used.
            % -------------------------------------------------------------
            % Outputs: 
            %   failed (CELL ARRAY of STR PATHS)
            %       List of video paths that had an issue during loading
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
            % See alos: Analysis_Set.select_ROIs

            if nargin < 2 || isempty(fig_handle)
                fig_handle = '';
            end
            if (nargin < 3 || isempty(default_tags)) && isprop(obj.parent_h, 'default_tags')
                default_tags = obj.parent_h.default_tags;
            elseif nargin < 3 || isempty(default_tags)
                default_tags = '';
            end

            modified = false(1, numel(obj.videotypes));
            if ~isempty(obj)
                clear global current_offset current_pos roi_handles
                global current_pos current_offset

                %% Make sure there is no funny/empty video folder listed
                obj.cleanup()
                
                %% Prepare extraction
                failed                  = {};
                list_of_videotypes      = obj.videotypes;

                %% For each videotype, get a representative frame
                for video_type_idx = 1:numel(list_of_videotypes)
                    %% Reset position to center, with 1 ROI
                    current_pos         = {}; 

                    existing_windows    = false(1, obj.n_rec);
                    existing_extracted_results = false(1, obj.n_rec);
                    for rec = 1:obj.n_rec
                        if obj.recordings(rec).n_vid % for non empty-folders
                            real_idx = find(contains({obj.recordings(rec).videos.path}, list_of_videotypes{video_type_idx}));
                            if real_idx % When one video is missing for a specific recording
                                existing_windows(1, rec)        = ~isempty(obj.recordings(rec).videos(real_idx).ROI_location); % no nested indexing method available as far as i know
                                existing_extracted_results(1, rec) = ~all(cellfun(@isempty, obj.recordings(rec).videos(real_idx).extracted_results)); % no nested indexing method available as far as i know
                            end
                        end
                    end

                    if all(existing_extracted_results)
                        obj.recordings.plot_results(123, true, '', list_of_videotypes{video_type_idx});
                    end

                    %% Plot the representative_frame for the current expe
                    [obj, names] = display_video_frame(obj, list_of_videotypes{video_type_idx}, 0, fig_handle, default_tags);

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

                    %% Add new windows and update ROI windows location  
                    try
                        roi_available = isprop(obj.recordings(rec).videos(video_type_idx),'n_roi') && obj.recordings(rec).videos(video_type_idx).n_roi;
                    catch
                        roi_available = false;    
                    end
                    if roi_change_detected || (isempty(current_pos) && roi_available)% && current_experiment.recordings(rec).videos(video_type_idx).n_roi > 0)
                        modified(video_type_idx) = true;
                        for rec = 1:obj.n_rec
                            target = obj.videotypes{video_type_idx};
                            local_video_type_idx = find(contains(obj.recordings(rec).videotypes, target));
                            if ~isempty(local_video_type_idx) % empty if video is missing
                                n_rois = obj.recordings(rec).videos(local_video_type_idx).n_roi;
                                previous_ids = vertcat(obj.recordings(rec).videos(local_video_type_idx).ROI_location{:});
                                if isempty(current_pos) % Because you deleted everything !
                                    obj.recordings(rec).videos(local_video_type_idx).rois = repmat(ROI(obj.recordings(rec).videos(local_video_type_idx)), 1, 0);
                                elseif obj.recordings(rec).n_vid % this will only exclude completely empty/irrelevant folders
                                    obj.recordings(rec).videos(local_video_type_idx).video_offset = mean(cell2mat(cellfun(@(x) x(rec,:), current_offset, 'UniformOutput', false)'),1); % only store mean displacement. % IF YOU HAV AN ERROR HERE< CONSIDER CALLING experiment.cleanup()
                                    for roi = 1:numel(current_pos) 
                                        %% Check if it is a new ROI
                                        if isempty(previous_ids) || isempty(find(previous_ids(:,5) == current_pos{roi}(5)))                   
                                            n_roi = obj.recordings(rec).videos(local_video_type_idx).n_roi;
                                            if n_roi == 0 %% QQ NEED TO CREATE A METHOD FOR THAT
                                                obj.recordings(rec).videos(local_video_type_idx).rois = ROI(obj.recordings(rec).videos(local_video_type_idx));
                                            else
                                                obj.recordings(rec).videos(local_video_type_idx).rois(n_roi + 1) = ROI(obj.recordings(rec).videos(local_video_type_idx));
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
                                                obj.recordings(rec).videos(local_video_type_idx).extracted_results{roi} = {}; % Clear any result content
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
        
        function [consensus_frame, all_frames] = get_consensus_frame(obj, videotype, force)
            %% Generate a consensus frame for the whole experiment
            %   Consensus frame is an image build using the first frame of
            %   each recording, in order to give an idea of the amount of
            %   stability of the of the video location
            % -------------------------------------------------------------
            % Syntax: 
            %   [reference_frame, all_frames] =
            %    Experiment.get_consensus_frame(videotype, force)
            % -------------------------------------------------------------
            % Inputs:
            %   videotype (STR) - Optional - default is ''
            %   	The name of the video type to use for image
            %   	regeneration 
            %
            %   force (BOOL) - Optional - default is false
            %   	If true, the first frame will be extracted again
            % -------------------------------------------------------------
            % Outputs:
            %   consensus_frame (X x Y x 3 DOUBLE)
            %   	Consensus frame generated using all the recordings. See
            %   	extra notes for color-code.
            %
            %   all_frames ({X x Y} x N_REC CELL ARRAY)
            %   	One frame per recording, obtained from
            %   	Video.reference_frame
            % -------------------------------------------------------------
            % Extra Notes:
            % * Red indicates for the normalized sum
            %   Green indicates the normalized variance
            %   Blue indicates the normalized max
            %   Saturated regions are NaNd, and displayed in black.
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also: Recording.get_representative_frame
            
            if nargin < 2 || isempty(videotype)
                videotype = obj.videotypes(1);
            end
            if nargin < 3 || isempty(force)
                force = false;
            end

            consensus_frame = cell(1, obj.n_rec);
            labels          = cell(1, obj.n_rec);
            for rec = 1:obj.n_rec
                [consensus_frame{rec}, labels{rec}] = obj.recordings(rec).get_representative_frame(force);
            end
            
            %% Make sure we get one frame for the correct video, or a frame of NaN of similar size
            real_idx        = cellfun(@(x) find(contains(x, videotype)), labels, 'UniformOutput', false);
            missing         = cellfun(@isempty, real_idx) | cellfun(@(x,y) isempty(y) || isempty(x{y}), consensus_frame, real_idx);
            first_valid     = find(~missing,1,'first');
            consensus_frame(missing) = {{NaN(size(consensus_frame{first_valid}{real_idx{first_valid}}))}};
            real_idx(missing) = {1};
            consensus_frame = cellfun(@(x, y) x{y}, consensus_frame, real_idx, 'UniformOutput', false);
 
            %% Concatenate
            consensus_frame = cat(3,consensus_frame{:});
            if obj.parent_h.auto_register_ref_image
                for im = find(~[1, missing(2:end)])
                    [offset, ~] = dftreg(consensus_frame(1:100,:,first_valid), consensus_frame(1:100,:,im), 100);
                    [~, consensus_frame(:,:,im)] = dftreg(consensus_frame(:,:,first_valid), consensus_frame(:,:,im), 1,'','','','',offset);
                end
            end
            
            %% Preparocessing for consensus frame
            corrimage       = correlation_image(consensus_frame);
            mask            = repmat(isnan(corrimage),1,1,3); % No DATA

            %% Generate consensus frame
            all_frames = consensus_frame;
            meanimage   = nanmean(consensus_frame, 3);        
            varimage    = nanvar(consensus_frame, 1, 3);
            maximage    = nanmax(consensus_frame, [], 3);
            maximage    = (maximage-meanimage);
            consensus_frame = cat(3,...
                                  (meanimage - nanmin(meanimage(:))) / (nanmax(meanimage(:)) - nanmin(meanimage(:))),...
                                  (3*varimage - nanmin(varimage(:))) / (nanmax(varimage(:)) - nanmin(varimage(:))),...
                                  (3*maximage - nanmin(maximage(:))) / (nanmax(maximage(:)) - nanmin(maximage(:))));
            consensus_frame(imerode(mask, strel('disk',3))) = 0; % blank saturated regions  
        end
        
        function all_offsets = autoestimate_offsets(obj, videotypes)
            if nargin < 2 || isempty(videotypes)
                videotypes = obj.videotypes;
            elseif ischar(videotypes)
                videotypes = {videotypes};
            end
            
            all_offsets = {};
            for type = 1:numel(videotypes)
                [~, all_frames] = obj.get_consensus_frame(videotypes{type});

                %% Get some info to help choosing ROIs
                offsets = {[0, 0]};
                ref = find(~isnan(all_frames(1,1,:)),1,'first');
                for rec_idx = 2:size(all_frames, 3)
                    if ~isnan(mean2(all_frames(:,:,rec_idx)))
                        offsets{rec_idx} = dftregistration(all_frames(1:100,:,ref), all_frames(1:100,:,rec_idx), 100);
                        offsets{rec_idx} = offsets{rec_idx}([4,3])*-1;
                        
                        local_video_type_idx = find(contains(obj.recordings(rec_idx).videotypes, videotypes{type}));                    
                        obj.recordings(rec_idx).videos(local_video_type_idx).video_offset = offsets{rec_idx};                        
                    else
                        offsets{rec_idx} = [NaN, NaN];
                    end
                end

                %% Update ROI position, or return values
                all_offsets{type} = cell2mat(offsets');
            end
        end

        function new_data_available = analyse(obj, force, display)
            %% Extract results for current experiments
            % -------------------------------------------------------------
            % Syntax: 
            %   Experiment.analyse(force, display)
            % -------------------------------------------------------------
            % Inputs:
            %   force (BOOL) - Optional - default is false
            %   	If true, reanalyse previous results. If false, only analyse
            %   	missing ones
            %
            %   display (BOOL or STR) - Optional - default is false
            %   	- If true or 'auto', results are displayed for each 
            %   	recording (after extraction). If extraction was already
            %   	done, results are also shown.
            %       - If 'pause' results display will pause until the figure
            %   	 is closed
            % -------------------------------------------------------------
            % Outputs:
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % * Analyse all ROIs where an un-analysed ROI is set
            %   Experiment.analyse()
            %
            % * Analyse all ROIs. Reanalyse old ones.
            %   Experiment.analyse(true)
            %
            % * Analyse missing ROIs, plot result
            %   Experiment.analyse('', true)
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also: Experiment.analyse
            
            if nargin < 2 || isempty(force)
                force = false;
            end
            if nargin < 3 || isempty(display)
                display = false;
            end
            
            new_data_available = false;
            for rec = 1:obj.n_rec
                is_new = obj.recordings(rec).analyse(force, false);
                new_data_available = new_data_available || is_new;
            end

            if any(strcmp(display, {'auto', 'pause'})) || (islogical(display) && display)
                obj.plot_results(123, '', strcmp(display, 'pause'));
            end
        end

        function clear_results(obj, idx_to_clear, videotype_filter, ROI_filter, delete_ROI)
            %% Clear results matching ROI_filter, or delete ROI
            % -------------------------------------------------------------
            % Syntax: 
            %   Experiment.clear_results(   idx_to_clear, videotype_filter,
            %                           ROI_filter, delete_ROI)
            % -------------------------------------------------------------
            % Inputs:
            %   idx_to_clear (1 x N INT) - Optional - Default will clear
            %       all recordings
            %   	list of recordings to filter. Any recording to filter
            %   	will be filtered
            %
            %   videotype_filter (STR or CELL ARRAY of STR) - Optional 
            %     Default - will clear all videos
            %   	list of video to filter. Any video name matching the
            %       filter will be cleared 
            %
            %   ROI_filter (STR or CELL ARRAY of STR) - Optional - Default
            %           will clear all ROIs
            %   	list of ROIs to filter. Any ROI label matching the
            %       filter will be cleared 
            %
            %   delete_ROI (BOOL) - Default is false
            %   	If true, the whole ROI is deleted
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
            % See also: Video.clear_results, Experiment.clear_results
            
            for exp = 1:numel(obj)
                if nargin < 2 || isempty(idx_to_clear)
                    idx_to_clear_exp = 1:obj(exp).n_rec;
                else
                    idx_to_clear_exp = idx_to_clear;
                end
                if nargin < 3 || isempty(videotype_filter)
                    videotype_filter_exp = obj(exp).videotypes;
                else
                    videotype_filter_exp = videotype_filter;
                end
                if nargin < 4 || isempty(ROI_filter)
                    ROI_filter_exp = obj(exp).roi_labels;
                else
                    ROI_filter_exp = ROI_filter;
                end
                if nargin < 5 || isempty(delete_ROI)
                    delete_ROI = false;
                end

                for rec = idx_to_clear_exp
                    obj(exp).recordings(rec).clear_results(videotype_filter_exp, ROI_filter_exp, delete_ROI);
                end
            end
        end
        
        function [all_data, all_t_axes] = plot_results(obj, fig_number, zero_t, manual_browsing, videotype_filter, output_filter, regroup, ROI_filter, normalize)
            %% Display and return results for all recordings in the experiment
            % -------------------------------------------------------------
            % Syntax: 
            %   [all_data, all_t_axes] = Experiment.plot_results(fig_number, 
            %       zero_t, manual_browsing, videotype_filter, 
            %       output_filter, regroup, ROI_filter)
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
            %   	If true, results display will pause until the figure is 
            %   	closed
            %
            %   videotype_filter (STR or CELL ARRAY of STR) - Optional - 
            %       default is unique([obj.videotypes])
            %   	Only videos matching videotype_filter are displayed.
            %
            %   output_filter (function handle) - Optional - default is ''
            %   	if a function hande is provided, the function is
            %   	applied to each result array during extraction. see
            %   	Recording.plot_result for more information
            %
            %   regroup (BOOL) - Optional - default is true
            %   	if true, ROIs with the same name are displayed together
            %
            %   ROI_filter (STR or CELL ARRAY of STR) - Optional - 
            %       default is unique([obj.roi_labels])
            %   	display only selected ROIs
            %
            %   normalize (STR) - Optional - any in {'none','local',
            %       'global'} - Default is 'global'
            %   	Define if results are normalized or not, and if
            %   	normalization is done per recording
            % -------------------------------------------------------------
            % Outputs:
            %   all_data ([1 x n_expe] CELL ARRAY of [1 x n_vid] CELL ARRAY
            %                of [T x n_roi] MATRIX) - 
            %   	For all experiments, returns the result for the selected
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
            %
            % * See general documentation for examples
            % -------------------------------------------------------------
            % Examples:
            % * Get and Plot result for current experiment
            %   [result, t] = Experiment.plot_results()
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also: Experiment.analyse

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
            if nargin < 9 || isempty(normalize)
                normalize = 'global';
            end
            
            all_data    = {};
            all_t_axes  = {};
            for exp = 1:numel(obj) % usually 1 but can be more
                if ~isempty(auto)
                    fig_number  = (1:numel(obj(exp).videotypes)) + auto;
                    auto        = max(fig_number);                    
                end
                [all_data{exp}, all_t_axes{exp}] = obj(exp).recordings.plot_results(fig_number, zero_t, manual_browsing, videotype_filter, output_filter, regroup, ROI_filter, normalize);
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
            % See also: Recording.videotypes

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
            global_reference_images = cell(obj.n_rec, numel(obj.videotypes));
            for rec = 1:obj.n_rec
                for vid = 1:obj.recordings(rec).n_vid
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
                
        function current_varname = get.current_varname(obj)
            current_varname = obj.parent_h.current_varname;
        end
        
        function set.current_varname(obj, current_varname)
            obj.parent_h.current_varname = current_varname;
        end         
    end
end

