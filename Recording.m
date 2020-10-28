%% Recording Class
% 	This the class container for all the Video of an recording
%
%   Type doc Recording.function_name or Recording Class.function_name 
%   to get more details about the methods inputs and outputs.
% -------------------------------------------------------------------------
% Syntax: 
%   this = Recording(n_video, recording_path);
% -------------------------------------------------------------------------
% Class Generation Inputs: 
%   n_video(INT) - Optional - Default is 0
%                               Number of Video object to initialize. They
%                               will need to be populated
%
%   recording_path(STR) - Optional - Default is ''
%                               Path to you recording folder
% -------------------------------------------------------------------------
% Outputs: 
%   this (Recording object)
% -------------------------------------------------------------------------
% Class Methods (ignoring get()/set() methods):
%
% * Update video list if you chenged in in the recording
%   Recording.update()
%
% * Remove a specific video / set of videos
%   Recording.pop(vid_number)
%
% * Plot Motion indices for selected recordings
%   [all_data, all_t_axes] = Recording.plot_MIs(fig_number, zero_t, 
%                               manual_browsing, videotype_filter, 
%                               output_filter, regroup, ROI_filter,
%                               normalize)
%
% * Clear MIs or delete specifc ROIS
%   Recording.clear_MIs(videotype_filter, ROI_filter, delete_ROI)
% -------------------------------------------------------------------------
% Extra Notes:
% * Recording is a handle. You can assign a set of Recording to a variable
%   from an Experiment for conveniency and edit it. As a handle, modified 
%   variables will be updated in your original Experiments too
% -------------------------------------------------------------------------
% Examples:
%
% * Refresh video list if you deleted a recording
%   s = Analysis_Set();
%   s.experiments(1).populate(experiment_path);
%   s.experiments(1).recordings(1).update
%
% * Remove one video in a specific recording
%   s.experiments(1).recordings(2).pop(1)
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
% See also Analysis_Set, Experiment, Video, ROI


classdef Recording < handle
   
    properties
        videos = []         ; % List of Video objects in this recording
        n_vid = 0           ; % Number of videos in the recording
        path                ; % Path of the recording
        videotypes          ; % List the types of videos in this recording
        roi_labels          ; % List of the ROI labels per Video
        reference_images 	; % Reference image per Video
        name                ; % User-defined recording name
        duration            ; % recording duration
        t_start             ; % recording t start
        t_stop              ; % recording t stop
        trial_number        ; % number of trials in the recording
        motion_indexes      ; % MI per video per ROI
        comment             ; % User comment
        default_video_types = {'EyeCam'           ,...
                               'BodyCam'          ,...
                               'WhiskerCam'}      ; % Default camera names
        analyzed            ; % true if all set ROIs were analyzed
    end
    
    methods
        function obj = Recording(n_video, recording_path)
            %% Recording Object Constructor. 
            % -------------------------------------------------------------
            % Syntax: 
            %   this = Recording(n_video, recording_path)
            % -------------------------------------------------------------
            % Inputs:
            %   n_video (INT) - Optional - default is 0
            %       number of empty Recordings to generate
            %
            %   recording_path (STR PATH)
            %       path to the Recording folder
            % -------------------------------------------------------------
            % Outputs: 
            %   this (Recording)
            %   	The container for a given Recording with one or
            %   	multiple Videos
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            %
            % * Create a new Recording object
            %     recording = Recording();
            %
            % * Create a new Recording object and assign a folder
            %     recording = Recording('','/Rec/Folder/path');
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            %
            % See also:
            
            if nargin < 1
                n_video         = 0;    % Empty recording
            end
            if nargin < 2
                recording_path  = '';   % Empty recording
            end
            for el = 1:n_video
                obj.videos = [obj.videos, Video];
            end
            obj.path            = recording_path;
        end
        
        function update(obj, full_update)
            %% Update list of videos in the recording
            % -------------------------------------------------------------
            % Syntax: 
            %   Recording.update(full_update)
            % -------------------------------------------------------------
            % Inputs:
            %   full_update (BOOL) - Optional - default is falif true,
            %   video timestamps will be computed too. This will slow down
            %   refresh for a big database, and can be handled when
            %   extracting MIs
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
            
            if nargin < 2 || isempty(full_update)
                full_update = false;
            end

            recordings_videos = dir([obj.path, '**/*.avi']);
            %% Check if all videos are in place
            if obj.n_vid
                need_update = ~isfile({obj.videos.path}') | isempty({obj.videos.path}');

                %% If you added a video, Figure out which one
                if numel(recordings_videos) > numel(need_update)
                    error_box('Re-addition of video not fully implemented. ask if needed. As a work around you can remove the recording, update the table and re-add the recording')
                end

                for vid = 1:numel(recordings_videos)
                    if need_update(vid) % If you added videos in a recording, or if there is no information
                        obj.videos(vid).path = fix_path([recordings_videos(vid).folder,'/',recordings_videos(vid).name]);
                        if full_update
                            obj.videos(vid).set_timestamps();
                        end
                    end
                end
            end
        end
        
        function pop(obj, video_type_idx)
            %% Remove a specific video objct based on the video index
            % -------------------------------------------------------------
            % Syntax: 
            %   Recording.pop(video_type_idx)
            % -------------------------------------------------------------
            % Inputs:
            %   video_type_idx (INT)
            %   	delete video at specified location
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
            
            obj.videos(video_type_idx) = [];
        end

        function analyze(obj, force, display)
            %% Extract MIs for current recording
            % -------------------------------------------------------------
            % Syntax: 
            %   Recording.analyze(force, display)
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
            if nargin < 3 || isempty(display)
                display = false;
            end

            %% Go through video, and extract MI when required
            for vid = 1:obj.n_vid    
                obj.videos(vid).analyze('', force, display);
            end 
        end
        
           
        function [all_data, all_taxis] = plot_MIs(obj, fig_number, zero_t, manual_browsing, videotype_filter, output_filter, regroup, ROI_filter, normalize)
            %% Display and return MIs for current Recording
            % -------------------------------------------------------------
            % Syntax: 
            %   [all_data, all_t_axes] = Recording.plot_MIs(fig_number, 
            %       zero_t, manual_browsing, videotype_filter, 
            %       output_filter, regroup, ROI_filter, normalize)
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
            %
            %   normalize (STR) - Optional - any in {'none','local',
            %       'global'} - Default is 'global'
            %   	Define if MIs are normalized or not, and if
            %   	normalization is done per recording
            % -------------------------------------------------------------
            % Outputs:
            %   all_data ([1 x n_vid] CELL ARRAY of [T x n_roi] MATRIX) - 
            %   	For all recordings, returns the MI for the selected
            %   	videos. Videos that are filtered out return an empty
            %   	cell. Recordings are concatenated.
            %
            %   all_t_axes ([1 x n_vid] CELL ARRAY of [T x 1] MATRIX) - 
            %   	For all recordings, returns the time for the selected
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
            % * Get and Plot MI for current recording
            %   [MI, t] = Recording.plot_MIs()
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also: Experiment.plot_MIs
 
            if nargin < 2 || isempty(fig_number)
            	fig_number = '';
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
                output_filter = false; % eg : @(x) movmin(x, 3)
            end
            if nargin < 7 || isempty(regroup)
                regroup = true;
            end
            if nargin < 8 || isempty(ROI_filter)
                ROI_filter = unique([obj.roi_labels]);
            end
            if nargin < 9 || isempty(normalize)
                normalize = 'global';
            end
            
            %% Regroup MIs in a matrix and fill missing cells
            type_list = unique(horzcat(obj.videotypes));
            all_types = cell(numel(obj), numel(type_list));
            all_MIs   = cell(numel(obj), numel(type_list));
            all_labels= cell(numel(obj), numel(type_list));
            for rec = 1:numel(obj)
                for vid = 1:numel(type_list)
                    match = find(ismember(obj(rec).videotypes, type_list(vid)));
                    if ~isempty(match)
                        all_types(rec, vid) = type_list(vid);
                        all_MIs(rec, vid)   = obj(rec).motion_indexes(match)   ;
                        if strcmp(normalize, 'local')
                            for roi = 1:numel(all_MIs{rec, vid})
                                all_MIs{rec, vid}{roi}(:,1) = all_MIs{rec, vid}{roi}(:,1) - prctile(all_MIs{rec, vid}{roi}(:,1), 1);
                                all_MIs{rec, vid}{roi}(:,1) = all_MIs{rec, vid}{roi}(:,1) ./ nanmax(all_MIs{rec, vid}{roi}(:,1));
                            end
                        end
                        all_labels(rec, vid)= {obj(rec).videos(match).roi_labels};
                    else
                        all_types(rec, vid) = {''};
                        all_MIs(rec, vid)   = {cell(1,0)};
                        all_labels(rec, vid)= {cell(1,0)};
                    end
                end
            end
            all_MIs(cellfun(@(x) isempty(x), all_MIs)) = {[]};

            %% Filter video types by name if required, and flag NaN type (missing videos)
            to_use              = cellfun(@(x) contains(x, videotype_filter), all_types) & ~cellfun(@(x) all(isempty(x)), all_types);
            all_MIs(~to_use)    = {[]}; % clear content for ignored MI's
            all_labels(~to_use) = {[]}; % clear content for ignored MI's 
            all_MIs             = reshape(all_MIs   , size(to_use));
            all_labels          = reshape(all_labels, size(to_use));
            
            %% Remove t 0
            if islogical(zero_t) && zero_t
                t_offset = min([obj.t_start]); % t start is expressed in posixtime, in seconds + decimals for ms
            else
                t_offset = double(zero_t); % if false or any other value, set it as offset
            end

            %% Now generate plot
            ROI_names           = obj.roi_labels;  % a list of all labels
            if isempty(fig_number) || numel(fig_number) ~= numel(unique(all_types))
            	fig_number = 1:numel(unique(all_types)); 
            end
            
            all_data          = {};
            all_taxis         = {};
            for videotype_idx = 1:numel(type_list)
                if contains(type_list(videotype_idx), videotype_filter) % ignore filters videos
                    all_data{videotype_idx} = [];
                    all_taxis{videotype_idx} = [];
                    current_MIs     = all_MIs(:,videotype_idx);
                    current_labels  = all_labels(:,videotype_idx);
                    if all(cellfun(@isempty, current_MIs)) %% If all MI are missing, we set all_rois to [];
                        all_rois    = [];
                    elseif any(cellfun(@isempty, [current_MIs{:}])) %% If some MI are missing, we set a NaN array of the same size instead
                        all_rois    = vertcat(current_MIs{:});
                        to_fix      = cellfun(@isempty, all_rois);
                        if any(to_fix(:))
                            [~, ref] = max(~to_fix, [], 2);
                            for rec = 1:size(all_rois, 1)
                                tp  = size(all_rois{rec, ref(rec)},1);
                                all_rois(rec, to_fix(rec,:)) = {NaN(tp, 2)};
                            end
                        end
                        all_rois = cell2mat(all_rois);
                    else %% Optimal case
                        all_rois = vertcat(current_MIs{:});
                        all_rois = cell2mat(all_rois);
                    end

                    %% Set image to full screen onm screen 2 (if any)
                    screens = get(0,'MonitorPositions');
                    f = figure(fig_number(videotype_idx));clf(); hold on;                    
                    set(f,'Color','w');hold on;                    
%                     if size(screens, 1) > 1
%                         set(f, 'Position', screens(2,:)/1.1);
%                     end

                    %% Create subplot
                    axes            = [];
                    if regroup
                        n_rois      = sum(contains(unique(current_labels{1}), ROI_filter)); 
                    else
                        n_rois      = sum(contains(current_labels{1}, ROI_filter)); 
                        ROI_names   = current_labels{1};
                    end   
                    sz              = 0.9/n_rois; % use (numel(unique([ROI_names{:}]))) instead to insert gaps and match locations across videos
                    roi_count       = 0;
                    for roi = 0:numel(ROI_names)-1
                        if regroup
                            rois        = unique(cell2mat(cellfun(@(x) find(strcmp(x, ROI_names{roi+1})), current_labels, 'UniformOutput', false)));
                            real_roi    = rois-1;
                        else
                            rois        = roi+1;
                            real_roi    = rois;
                        end   
                        if ~isempty(real_roi) && contains(ROI_names{roi+1},ROI_filter)
                            roi_count   = roi_count + 1; % use real_roi instead to insert gaps and match locations across videos
                            
                            %% Prepare subplot for the ROI
                            ax          = subplot('Position',[0.1, 0.95 - sz*roi_count, 0.85, sz - 0.01]);
                            if roi_count == 1; title([type_list{videotype_idx},' ; ', fix_path(fileparts(obj(1).path),true)]);hold on; end
                            ax.XAxis.Visible = 'off';
                            ylabel(ROI_names{roi+1});hold on

                            %% Select the right column(s)
                            mi_data     = all_rois(:,rois*2 - 1);

                            %% Averages ROIs with the same name
                            if size(mi_data, 2) > 1
                                mi_data = nanmean(mi_data, 2);
                            end

                            %% Normalize mi_data, get timescale
                            if strcmp(normalize, 'global')
                                mi_data = (mi_data - min(mi_data)) / (range(mi_data));
                            end
                            novid       = diff(all_rois(:,rois(1)*2));
                            [idx]       = find(novid > (median(novid) * 2));
                            taxis       = (all_rois(:,rois(1)*2)- t_offset);
                            if isa(output_filter,'function_handle')
                                mi_data = output_filter(mi_data);
                            end
                            plot(taxis, mi_data); hold on;
                            for p = 1:numel(idx)
                                x       = [taxis(idx(p)), taxis(idx(p)+1), taxis(idx(p)+1), taxis(idx(p))];
                                y       = [max(mi_data), max(mi_data), min(mi_data), min(mi_data)];
                                patch(x, y, [0.8,0.8,0.8], 'EdgeColor', 'none'); hold on;
                            end
                            axes        = [axes, ax]; hold on;
                            all_data{videotype_idx} = [all_data{videotype_idx}, mi_data];
                        end
                    end

                    if ~isempty(axes) % empty when no ROIs were selected in the Video
                        ax.XAxis.Visible = 'on';
                        all_taxis{videotype_idx} = taxis;
                        linkaxes(axes, 'x'); hold on;
                    end

                    if manual_browsing
                        uiwait(f);
                    end
                end
            end
        end

        function clear_MIs(obj, videotype_filter, ROI_filter, delete_ROI)
            %% Clear MIs matching ROI_filter, or delete ROI
            % -------------------------------------------------------------
            % Syntax: 
            %   Recording.clear_MIs(videotype_filter, ROI_filter, delete_ROI)
            % -------------------------------------------------------------
            % Inputs:
            %   videotype_filter (STR or CELL ARRAY of STR) - Optional 
            %           Default - will clear all videos
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
            % See also: Video.clear_MIs, Experiment.clear_MIs
            
            if nargin < 2 || isempty(videotype_filter)
                videotype_filter = obj.videotypes;
            end
            if nargin < 3 || isempty(ROI_filter)
                ROI_filter = obj.roi_labels;
            end
            if nargin < 4 || isempty(delete_ROI)
                delete_ROI = false;
            end

            for vid = find(contains(obj.videotypes, videotype_filter))
                obj.videos(vid).clear_MIs(ROI_filter, delete_ROI);
            end
        end

        function set.path(obj, recording_path)
            %% Set a new recording path and fix synatx
            % -------------------------------------------------------------
            % Syntax: 
            %   Recording.path = recording_path
            % -------------------------------------------------------------
            % Inputs:
            %   recording_path (STR PATH)
            %   	The folder containing all the videos for a recording
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

            obj.path = fix_path(recording_path);
        end

        function n_vid = get.n_vid(obj)
            %% Return the number of video available
            % -------------------------------------------------------------
            % Syntax: 
            %   n_vid = Recording.n_vid
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   n_vid (INT)
            %   	number of videos listed in the recording
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
            
            n_vid = numel(obj.videos);
        end
        
        function videotypes = get.videotypes(obj)
            %% List all video_types available in the Recording
            % -------------------------------------------------------------
            % Syntax: 
            %   videotypes = Recording.videotypes
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   videotypes (CELL ARRAY of STR)
            %   	The name of all videos in the recording, without the
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
            % See also: Experiment.videotypes
            
            if obj.n_vid % for non-empty folders
                videotypes = {obj.videos.video_types};
            else
                videotypes = '';
            end
        end 

        function [reference_images, video_label] = get_representative_frame(obj, force)
            %% Generate a consensus frame for the whole experiment
            %   Consensus frame is an image build using the first frame of
            %   each recording, in order to give an idea of the amount of
            %   stability of the of the video location
            % -------------------------------------------------------------
            % Syntax: 
            %   [reference_frame, all_frames] =
            %               Experiment.get_representative_frame(force)
            % -------------------------------------------------------------
            % Inputs:
            %   force (BOOL) - Optional - default is false
            %   	If true, the first frame will be extracted again
            % -------------------------------------------------------------
            % Outputs:
            %   all_frames ({X x Y} x N_VIDEO CELL ARRAY)
            %   	One frame per video type, obtained from
            %   	Video.reference_frame
            %
            %   video_label ({STR} x N_VIDEO CELL ARRAY)
            %   	One label per video type, to enable filtering of
            %   	specific video types
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
            % See also: Experiment.get_consensus_frame,
            %   Video.reference_image 
            
            if nargin < 2 || isempty(force)
                force = false;
            end
            
            reference_images    = cell(1, obj.n_vid);
            video_label         = cell(1, obj.n_vid);
            for vid = 1:obj.n_vid
                if force
                    obj.videos(vid).reference_image = [];
                end
                reference_images{vid}   = obj.videos(vid).reference_image;
                video_label{vid}        = obj.videos(vid).video_types;
            end
        end
        
        function motion_indexes = get.motion_indexes(obj)
            %% Get MIs for each video
            % -------------------------------------------------------------
            % Syntax: 
            %   motion_indexes = Analysis_Set.motion_indexes
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   motion_index (N CELL ARRAY of M CELL Array of
            %                       T x 2 MATRIX)
            %   	1 cell for each N video, in which one 1 cell for each
            %       M ROI. If motion indexes were extracted, T x 2 Matrix
            %       (values, time). Cell is empty is no ROI was extracted.
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   21-05-2020
            
            motion_indexes = {};
            for vid = 1:obj.n_vid
                motion_indexes = [motion_indexes, {obj.videos(vid).motion_indexes}];
            end
        end

        function roi_labels = get.roi_labels(obj)
            %% Get all ROIs labels for all videos in the recording
            % -------------------------------------------------------------
            % Syntax: 
            %   roi_labels = Analysis_Set.roi_labels
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   roi_labels (CELL ARRAY of STR)
            %   	list of all the ROI labels in all the videos in this
            %   	recording
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   21-05-2020
            
            roi_labels = {};
            for vid = 1:obj.n_vid
                roi_labels = [roi_labels, {obj.videos(vid).roi_labels}];
            end
            roi_labels = [roi_labels{:}];
            if ~isempty(roi_labels)
                roi_labels = unique(roi_labels(cellfun('isclass', roi_labels, 'char')));  
            end
        end 
        
        function t_start = get.t_start(obj)
            %% Returns the start time of the recording/recording set
            % -------------------------------------------------------------
            % Syntax: 
            %   t_start = Analysis_Set.t_start
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   t_start (posix time)
            %   	posix time of the start of the first recording in the
            %   	selection.
            % -------------------------------------------------------------
            % Extra Notes:
            % * To convert posixtime to a timestamp, use:
            %   datetime(t, 'ConvertFrom', 
            %           'posixtime' ,'Format','dd-MMM-yyyy HH:mm:ss.SSSSS')
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   21-05-2020
            %
            % See also: Experiment.t_start
            
            t_start = [];
            for vid = 1:obj.n_vid
                if obj.videos(vid).n_roi && ~isempty(obj.videos(vid).absolute_times)
                    if isdatetime(obj.videos(vid).absolute_times(1))
                        t = posixtime(obj.videos(vid).absolute_times(1)) + rem(second(obj.videos(vid).absolute_times(1)),1); % similar to MI time column
                    else
                        t = obj.videos(vid).absolute_times(1);
                    end
                    t_start = [t_start, t_start, t];
                end
            end
            t_start = nanmin(t_start);
        end
        
        function analyzed = get.analyzed(obj)
            %% Returns the analyzis status of the recording
            % -------------------------------------------------------------
            % Syntax: 
            %   analyzed = Analysis_Set.analyzed
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   analyzed (BOOL)
            %   	true if all ROIs were extracted, false otherwise
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   21-05-2020
            
            analyzed = true;
            for vid = 1:obj.n_vid
                if obj.videos(vid).n_roi > 0 && any(cellfun(@isempty, {obj.videos(vid).motion_indexes{:}}))
                    analyzed = false;
                    break
                end
            end
        end
    end
end

