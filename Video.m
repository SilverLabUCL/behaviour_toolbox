%% Video Class
% 	This the class container for a video and all its ROIs
%
%   Type doc Video.function_name or Video Class.function_name 
%   to get more details about the methods inputs and outputs.
% -------------------------------------------------------------------------
% Syntax: 
%   this = Video(n_roi, file_path);
% -------------------------------------------------------------------------
% Class Generation Inputs: 
%   n_roi(INT) - Optional - Default is 0
%                               Number of ROI object to initialize. They
%                               will need to be edited later
%
%   file_path(STR) - Optional - Default is ''
%                               Path to you recording folder
% -------------------------------------------------------------------------
% Outputs: 
%   this (Video object)
% -------------------------------------------------------------------------
% Class Methods (ignoring get()/set() methods):
%
% * Get timestamps and extract MI or run any function set in func for all
%   ROIs
%   Video.analyze(func)
%
% * Extract absolute and relative timestamps
%   Video.set_timestamps()
%
% * Plot Motion indices for selected recordings
%   [all_data, all_t_axes] = Video.plot_MIs(fig_number, use_subplots,
%                                               normalize)
%
% * Clear MIs or delete specifc ROIS
%   Video.clear_MIs(ROI_filter, delete_ROI)
% -------------------------------------------------------------------------
% Extra Notes:
% * Video is a handle. You can assign a set of Videos to a variable
%   from a Recording for conveniency and edit it. As a handle, modified 
%   variables will be updated in your original Recordings too
% -------------------------------------------------------------------------
% Examples:
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
% Copyright � 2015-2020 University College London
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
% 22-05-2020
%
% See also Analysis_Set, Experiment, Recordings, ROI


classdef Video < handle
    properties
        path            ; % Full path to the Video file
        video_types     ; % Name of the video without extension
        timestamps      ; % Relative tiemstamps from the beginning of the video
        absolute_times  ; % Absolute timestamps in posix time
        sampling_rate   ; % Video sampling rate
        reference_image ; % The reference image of the video
        comment         ; % User Comment
        pixel_size      ; % ---
        quality = 5     ; % field for video quality assessement
        rois            ; % Array of ROI objects
        n_roi           ; % Number of ROIs
        roi_labels      ; % Name of each ROI
        ROI_location    ; % ROI location
        motion_indexes  ; % All Extracted Motion indices
        motion_index_norm;% All Extracted normalized Motion indices
        video_offset    ; % Video offset relative to first experiment recording
        position        ; % ?
        name            ; % ---
    end
    
    methods
        function obj = Video(n_roi, file_path) 
            %% Video Object Constructor. 
            % -------------------------------------------------------------
            % Syntax: 
            %   this = Video(n_roi, file_path)
            % -------------------------------------------------------------
            % Inputs:
            %   n_roi (INT) - Optional - default is 0
            %       number of empty ROIs to generate
            %
            %   file_path (STR PATH)
            %       path to the the video file
            % -------------------------------------------------------------
            % Outputs: 
            %   this (Video)
            %   	The container for a given Video with one or
            %   	multiple ROIs
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            %
            % * Create a new Recording object
            %     video = Video();
            %
            % * Create a new Recording object and assign a folder
            %     video = Video('','/Video/File/path.avi');
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            %
            % See also:
            
            if nargin < 1
                n_roi = 0; % Empty recording
            end
            if nargin < 2
                file_path = ''; % Empty recording
            end
            obj.path            = file_path;
            obj.reference_image = [];
            obj.timestamps      = cell(1, n_roi);
            obj.video_types     = cell(1, n_roi);
            for el = 1:n_roi
                obj.rois(el)      = ROI;
            end
        end
        
        
        function metric = analyze(obj, func)
            %% Store and format absolute timestamps for the current video
            % -------------------------------------------------------------
            % Syntax: 
            %   metric = Video.analyze(func)
            % -------------------------------------------------------------
            % Inputs:
            %   func (FUNCTION HANDLE) - Optional - default is
            %       get_MI_from_video().
            %       The function determines the operation applied to the
            %       ROI coordinates
            % -------------------------------------------------------------
            % Outputs:
            %   metric (FUNCTION HANDLE OUTPUT) - defaut is T x 2 Matrix of
            %       Motion indices
            %       The output of the function.
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
            
            if nargin < 2 || isempty(func)
                default = true;
            else
                default = false;
            end
            
            %% Set timing info if missing
            if isempty(obj.timestamps) || default
                set_timestamps(obj);
            end

            %% Get MI (or other function handle)
            if default    
                if isdatetime(obj.absolute_times(1))
                    t = obj.timestamps + posixtime(obj.absolute_times(1)) + rem(second(obj.absolute_times(1)),1); % posixtime in seconds
                else
                    t = obj.absolute_times(1);
                end  
                obj.motion_indexes = get_MI_from_video(obj.path, obj.ROI_location, t, false, false, '', obj.video_offset);
                metric = obj.motion_indexes;
            else
                metric = func();
            end
        end
        
        function set_timestamps(obj)
            %% Store and format absolute timestamps for the current video
            % -------------------------------------------------------------
            % Syntax: 
            %   Video.set_timestamps()
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs:
            % -------------------------------------------------------------
            % Extra Notes:
            % * The function requires the presence of a file in the format 
            %   [Video_name_no_extension, '-relative times.txt'] in the
            %   folder above the one where the video is. This file is
            %   generated during VIdeo extraction
            %
            % * the function generate a relative timestamp, starting at the
            %   beginning of the video, an absolute timestamp, expressed in
            %   posix time and a video sampling rate value
            % -------------------------------------------------------------
            % Examples:
            % * Plot MI for current Video in a single plot
            %   Video.set_timestamps()
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also: Recording.plot_MIs     
            
            [timepstamp_path, file] = fileparts(obj.path);
            file                    = erase(file, '-1');
            timepstamp_path         = fileparts(timepstamp_path); % To use the parent folder instead (because it has absolute timestamps)
            timepstamp_path         = [timepstamp_path,'/',file,'-relative times.txt'];

            %% Now read data
            if isfile(timepstamp_path)
                fileID = fopen(timepstamp_path,'r');
                timescale = textscan(fileID, '%f%f%s%[^\n\r]', 'Delimiter', '\t', 'TextType', 'string', 'EmptyValue', NaN,  'ReturnOnError', false);
                fclose(fileID);

                %% Get real time
                obj.absolute_times  = datetime(timescale{3},'Format','dd-MM-yyyy;HH:mm:ss.SSSS');

                %% Get camera timestamps
                obj.timestamps      = timescale{2}/1000;
                obj.sampling_rate   = 1/mean(diff(obj.timestamps));
            else
                fprintf(['timestamps not found for video ',obj.path,' \n']);
            end
        end
        
        function plot_MIs(obj, fig_number, use_subplots, normalize)
            %% Display and return MIs for current Recording
            % -------------------------------------------------------------
            % Syntax: 
            %   Video.plot_MIs(fig_number, use_subplots, normalize)
            % -------------------------------------------------------------
            % Inputs:
            %   fig_number (1 x N_vid INT OR 1 x n_vid FIGURE HANDLE) - 
            %       Optional - default will use figure [1:n_vid]
            %   	This defines the figures/figure handles to use. If
            %   	figure number don't match the number of vieos, default
            %   	behaviour is used
            %
            %   use_subplots (BOOL) - Optional - default is false
            %   	If true, each MI is displayed on a different subplot,
            %   	otherwise they are all superimposed for a given Video
            %
            %   normalize (STR) - Optional - any in {'none','local',
            %       'global'} - Default is 'global'
            %   	Define if MIs are normalized or not, and if
            %   	normalization is done per recording
            % -------------------------------------------------------------
            % Outputs:
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % * Plot MI for current Video in a single plot
            %   Video.plot_MIs()
            %
            % * Plot MI for current Video in a subplots
            %   Video.plot_MIs('', true)
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also: Recording.plot_MIs            
            
            if nargin < 2 || isempty(fig_number)
                fig_number = cell(1,numel(obj));
            end
            if nargin < 3 || isempty(use_subplots)
                use_subplots = false;
            end
            if nargin < 4 || isempty(normalize)
                normalize = false;
            end
              
            %% Prepare figure handle to plot MIs
            if use_subplots && ~isempty(fig_number) && (~iscell(fig_number) || ~any(cellfun(@isempty, fig_number)))
            	fig_number = figure(fig_number);
            else
            	for vid = 1:numel(obj)
                	fig_number{vid} = figure(figure);
            	end
            end
            
            %% Load and Plot data
            for vid = 1:numel(obj) % usually 1 but can be more
                figure(fig_number{vid});
                for el = 1:obj(vid).n_roi
                    if use_subplots
                        sz = 0.9/(obj(vid).n_roi);
                        fig_number{vid} = subplot('Position',[0.1, 0.95 - sz*el, 0.85, sz - 0.01]);
                        fig_number{vid}.XAxis.Visible = 'off';
                    end
                    fig_number{vid} = obj(vid).rois(el).plot_MI(fig_number{vid}, normalize);
                end

                %% When using subplot, link x axes
                if use_subplots
                    fig_number{vid}.XAxis.Visible = 'on';
                    xlabel('Frames');
                    linkaxes(fig_number{vid}.Parent.Children, 'x');
                end
            end
        end
        
        function clear_MIs(obj, ROI_filter, delete_ROI)
            %% Clear MIs matching ROI_filter, or delete ROI
            % -------------------------------------------------------------
            % Syntax: 
            %   Video.clear_MIs(ROI_filter, delete_ROI)
            % -------------------------------------------------------------
            % Inputs:
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
            % See also: Recording.clear_MIs, Experiment.clear_MIs
            
            if nargin < 2 || isempty(ROI_filter)
                ROI_filter = obj.roi_labels;
            elseif ~iscell(ROI_filter)
                ROI_filter = {ROI_filter};
            end
            if nargin < 3 || isempty(delete_ROI)
                delete_ROI = false;
            end

            to_clear = [];
            for roi = 1:numel(ROI_filter)
                to_clear = [to_clear, find(contains(obj.roi_labels, ROI_filter{roi}))];
            end
            for el = sort(unique(to_clear), 'descend')
                if ~delete_ROI
                    obj.rois(el).motion_index   = [];
                else
                    obj.rois(el)                = [];
                end
            end
        end

        function set.path(obj, video_path)
            %% Set a new experiment path and fix synatx
            % -------------------------------------------------------------
            % Syntax: 
            %   Video.path = video_path
            % -------------------------------------------------------------
            % Inputs:
            %   experiment_path (STR PATH)
            %   	The path to the individual video
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

            obj.path = fix_path(video_path);
        end

        function set.motion_indexes(obj, motion_indexes)
            %% Set the Motion indices
            % -------------------------------------------------------------
            % Syntax: 
            %   Video.motion_indexes = motion_indexes;
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   motion_indexes (1 x N CELL ARRAY of T x 2 MATRIX)
            %   	For each N ROI, a CELL with a T x 2 Matrix (values, 
            %   	time).
            % -------------------------------------------------------------
            % Extra Notes:
            % * The number of cell in motion_indexes must match
            %   Video.n_roi
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   21-05-2020
                        
            if numel(motion_indexes) == 1 && isempty(motion_indexes)
                obj.clear_MIs();
            elseif numel(motion_indexes) ~= obj.n_roi
                error('Number of MIs provided does not match the number of MIs available')        
            else
                for roi = 1:obj.n_roi
                    obj.rois(roi).motion_index = motion_indexes{roi};
                end
            end
        end
        
        
        function n_roi = get.n_roi(obj)
            %% Return the number of ROIs
            % -------------------------------------------------------------
            % Syntax: 
            %   n_roi = Video.n_roi
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   n_roi (INT)
            %   	Total number of ROIs (valid or empty) in the Video
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
            
            n_roi = numel(obj.rois);
        end

        function ROI_location = get.ROI_location(obj)
            %% Return the ROIs location
            % -------------------------------------------------------------
            % Syntax: 
            %   ROI_location = Video.ROI_location
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   ROI_location (1 x N CELL ARRAY of 1 x 5 INT)
            %   	For each N ROI, provide the X, Y width height and id
            %   	information
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
            
            ROI_location    = cell(1, obj.n_roi);
            for roi = 1:obj.n_roi
                try
                	ROI_location{roi} = obj.rois(roi).ROI_location + obj.video_offset;
                catch
                    obj.video_offset = [0, 0];
                    ROI_location{roi} = obj.rois(roi).ROI_location;
                end
            end
        end
        
        function video_offset = get.video_offset(obj)
            %% Return the video offsets to apply to the ROIs
            % -------------------------------------------------------------
            % Syntax: 
            %   video_offset = Video.video_offset
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   video_offset (1 x 2 FLOAT)
            %   	X and Y offset to apply to the reference ROIs for the
            %   	current Video
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
            
            if isempty(obj.video_offset)
                video_offset = [0, 0];
            else
                video_offset = obj.video_offset;
            end
        end

        function motion_indexes = get.motion_indexes(obj)
            %% Return MI for each ROI
            % -------------------------------------------------------------
            % Syntax: 
            %   motion_indexes = Video.motion_indexes
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   motion_indexes (1 x N CELL ARRAY of T x 2 MATRIX)
            %   	For each N ROI, a CELL with a T x 2 Matrix (values, 
            %   	time).
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
            
            motion_indexes    = cell(1, obj.n_roi);
            for roi = 1:obj.n_roi
                motion_indexes{roi} = obj.rois(roi).motion_index;
            end
        end
        
        function motion_index_norm = get.motion_index_norm(obj)
            %% Return normalized MI for each ROI
            % -------------------------------------------------------------
            % Syntax: 
            %   motion_index_norm = Video.motion_index_norm
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   motion_index_norm (1 x N CELL ARRAY of T x 2 MATRIX)
            %   	For each N ROI, a CELL with a T x 2 Matrix (values, 
            %   	time). MIs are normalized to range.
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
            
            motion_index_norm    = cell(1, obj.n_roi);
            for roi = 1:obj.n_roi
                motion_index_norm{roi} = obj.rois(roi).motion_index_norm;
            end
        end

        function roi_labels = get.roi_labels(obj)
            %% Return label for each ROI
            % -------------------------------------------------------------
            % Syntax: 
            %   roi_labels = Video.roi_labels
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   roi_labels (1 x N CELL ARRAY of STR)
            %   	For each N ROI, a CELL with a the ROI label
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
            
            roi_labels    = cell(1, obj.n_roi);
            for roi = 1:obj.n_roi
                roi_labels{roi} = obj.rois(roi).name;
            end
        end
        

        function video_name = get.video_types(obj)
            %% Return the name of the video without the extension
            % -------------------------------------------------------------
            % Syntax: 
            %   video_types = Video.video_types
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   video_types (STR)
            %   	The video name without the folder or the .avi extension
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
            
            [~, video_name] = fileparts(obj.path);
        end
    end
end

