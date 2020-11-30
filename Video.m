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
% * Get timestamps and extract result or run any function set in func for all
%   ROIs
%   Video.analyse(func)
%
% * Extract absolute and relative timestamps
%   Video.set_timestamps()
%
% * Plot Results for selected recording using current variable
%   [all_data, all_t_axes] = Video.plot_results(fig_number, use_subplots,
%                                               normalize)
%
% * Clear results or delete specifc ROIS
%   Video.clear_results(ROI_filter, delete_ROI)
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
% 22-05-2020
%
% See also Analysis_Set, Experiment, Recordings, ROI


classdef Video < handle
    properties
        path            ; % Full path to the Video file
        video_types     ; % Name of the video without extension
        timestamps      ; % Relative tiemstamps from the beginning of the video
        absolute_times  ; % Absolute timestamps in posix time
        t               ; % Absolute timestamps in posix time?
        sampling_rate   ; % Video sampling rate
        reference_image ; % The reference image of the video
        comment         ; % User Comment
        pixel_size      ; % ---
        quality = 5     ; % field for video quality assessement
        rois            ; % Array of ROI objects
        n_roi           ; % Number of ROIs
        roi_labels      ; % Name of each ROI
        ROI_location    ; % ROI location
        extracted_results; % All extracted results
        video_offset    ; % Video offset relative to first experiment recording
        position        ; % Camera Position?
        name            ; % ---
        parent_h        ; % handle to parent Recording object
        current_varname ; % The metric currently used
    end
    
    methods
        function obj = Video(parent, n_roi, file_path) 
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
            
            if nargin < 2 || isempty(n_roi)
                n_roi = 0; % Empty recording
            end
            if nargin < 3 || isempty(file_path)
                file_path = ''; % Empty recording
            end
            
            obj.path            = file_path;
            obj.reference_image = [];
            obj.timestamps      = cell(1, n_roi);
            obj.video_types     = cell(1, n_roi);
            obj.parent_h        = parent;
            for el = 1:n_roi
                obj.rois = [obj.rois, ROI(obj)];
            end
        end
        
        function [metric, new_data_available] = analyse(obj, func, force, display, varname, ROI_filter, varargin)
            %% Store and format absolute timestamps for the current video
            % -------------------------------------------------------------
            % Syntax: 
            %   metric = Video.analyse(func, force, display, varname)
            % -------------------------------------------------------------
            % Inputs:
            %   func (FUNCTION HANDLE) - Optional - default is
            %       get_MI_from_video().
            %       The function determines the operation applied to the
            %       ROI coordinates
            %
            %   force (BOOL) - Optional - default is false
            %   	If true, reanalyse previous results. If false, only analyse
            %   	missing ones
            %
            %   display (BOOL or STR) - Optional - default is false
            %   	- If true or 'auto', results are displayed for each 
            %   	video (after extraction). If extraction was already
            %   	done, results are also shown.
            %       - If 'pause' results display will pause until the figure
            %   	 is closed            
            %
            %   varname (STR) - Optional - default is 'motion_index'
            %   	Set the variable name used for extraction
            %
            %   ROI_filter (STR) - Optional - default is ''
            %   	If non empty, only ROIs matching the name will be
            %   	selected
            % -------------------------------------------------------------
            % Outputs:
            %   metric (FUNCTION HANDLE OUTPUT) - defaut is T x 2 Matrix of
            %       Motion indices. The output of the function depends on
            %       current_varname
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
                func = @(~,~) get_MI_from_video(obj.path, obj.ROI_location, false, false, '', obj.video_offset);
            end
            if nargin < 3 || isempty(force)
                force = false;
            end
            if nargin < 4 || isempty(display)
                display = false;
            end
            if nargin < 5 || isempty(varname)
                obj.current_varname  = 'motion_index';
                callback = '';
            else
                varname = strsplit(varname, '@');
                if numel(varname) > 1
                    callback = strtrim(varname{2});
                else
                    callback = '';
                end
                obj.current_varname = strtrim(varname{1});
            end
            if nargin < 6 || isempty(ROI_filter)
                ROI_filter = '';
            end
            
            %% Extract variable
            new_data_available = false;
            if ~all(cellfun(@isempty, obj.roi_labels)) && any(contains(obj.roi_labels,ROI_filter))
                %% If you used a ROI filter, list the ROIs that will need updating
                valid_for_this_run = contains(obj.roi_labels,ROI_filter);

                %% If you didn't pass an ROI filter and some data is missing (or you force re-analysis), run the function at the video level
                available = false;
                if isempty(ROI_filter) && (force || any(cellfun(@isempty, obj.extracted_results)))
                    new_data_available = true;
                    metric = func();
                    if ~iscell(metric)
                        metric = repmat({metric}, 1, obj.n_roi);
                    end
                elseif isempty(ROI_filter)
                    available = true;
                end
                
                %% Assign values to correct ROI
                for roi = 1:obj.n_roi
                    if valid_for_this_run(roi) 
                        %% If you run function on a ROI by ROI basis
                        if ~isempty(ROI_filter) &&  (force || isempty(obj.rois(roi).extracted_data.(obj.current_varname)))
                            new_data_available = true;
                            metric{roi} = func(); % store directly the ouput at the right place
                        elseif ~isempty(ROI_filter)
                            available = true;
                        end

                        if ~available    
                            %% Store the result in the correct field
                            current_roi = obj.rois(roi);
                            p = findprop(current_roi.extracted_data,(obj.current_varname));
                            if ~isempty(callback)
                                p.GetMethod = str2func(callback);
                            end
                            p.Description   = func2str(func);
                            current_roi.extracted_data.(obj.current_varname)               = metric{roi};
                        end
                    end
                end

                %% Plot results
                if any(strcmp(display, {'auto', 'pause'})) || (islogical(display) && display)
                    obj.plot_results();
                end
                
                %% Now, use get method to retreive data
                metric = obj.extracted_results; % equialent of obj.rois.extracted_data.(obj.current_varname), for all rois;
            else
                fprintf(['No ROI selected/present in ',obj.path,'. Skipping extraction/rendering \n']);
                metric = {};
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
            % * Plot result for current Video in a single plot
            %   Video.set_timestamps()
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also: Recording.plot_results     
            
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
                if obj.timestamps > 0
                    fprintf(['TIMESTAMP BUG IN FILE ',timepstamp_path,'. CORRECTED ASSUMEING T0 = 0\n'])
                    obj.timestamps = obj.timestamps - obj.timestamps(1);
                end
                obj.sampling_rate   = 1/mean(diff(obj.timestamps));
            else
                fprintf(['timestamps not found for video ',obj.path,' \n']);
            end
        end
        
        function add_roi(obj, to_add)
            %% Add one or several ROI objects
            % -------------------------------------------------------------
            % Syntax: 
            %   Video.add_roi(to_add)
            % -------------------------------------------------------------
            % Inputs:
            %   to_add (INT) - Optional - default is 1
            %   	Add an N empty ROI objects
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
                if isempty(obj.rois)
                    obj.rois = ROI(obj); to_add = to_add - 1;
                end
                obj.rois(end + 1:end + to_add) = ROI(obj);
            end
        end
        
        function [all_data, all_taxis] = plot_results(obj, fig_number, use_subplots, normalize)
            %% Display and return results for current Recording
            % -------------------------------------------------------------
            % Syntax: 
            %   [all_data, all_taxis] = Video.plot_results(fig_number, 
            %                       use_subplots, normalize)
            % -------------------------------------------------------------
            % Inputs:
            %   fig_number (INT OR FIGURE HANDLE) - 
            %       Optional - default will use figure(1)
            %   	This defines the figures/figure handles to use. 
            %
            %   use_subplots (BOOL) - Optional - default is false
            %   	If true, each result is displayed on a different subplot,
            %   	otherwise they are all superimposed for a given Video
            %
            %   normalize (STR) - Optional - any in {'none','local',
            %       'global'} - Default is 'global'
            %   	Define if results are normalized or not, and if
            %   	normalization is done per recording
            % -------------------------------------------------------------
            % Outputs:
            %   all_data ([1 x n_vid] CELL ARRAY of [T x n_roi] MATRIX) - 
            %   	For video(s), returns the result for the selected rois
            %
            %   all_t_axes ([1 x n_vid] CELL ARRAY of [T x 1] MATRIX) - 
            %   	For video(s), return time axis. Videos that are 
            %   	filtered out return an empty cell. 
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % * Plot result for current Video in a single plot
            %   Video.plot_results()
            %
            % * Plot result for current Video in a subplots
            %   Video.plot_results('', true)
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also: Recording.plot_results            
            
            if nargin < 2 || isempty(fig_number)
                fig_number = cell(1,numel(obj));
            elseif isnumeric(fig_number)
                fig_number = {fig_number};
            end
            if nargin < 3 || isempty(use_subplots)
                use_subplots = false;
            end
            if nargin < 4 || isempty(normalize)
                normalize = false;
            end
              
            %% Prepare figure handle to plot results
            if use_subplots && ~isempty(fig_number) && (~iscell(fig_number) || ~any(cellfun(@isempty, fig_number)))
            	fig_number = figure(fig_number);
            else
            	for vid = 1:numel(obj)
                	fig_number{vid} = figure(figure);
            	end
            end
            
            %% Load and Plot data
            all_data          = {};
            all_taxis         = {};
            for vid = 1:numel(obj) % usually 1 but can be more
                all_data{vid} = [];
                all_taxis{vid} = [];
                figure(fig_number{vid});
                for el = 1:obj(vid).n_roi
                    if use_subplots
                        sz = 0.9/(obj(vid).n_roi);
                        fig_number{vid} = subplot('Position',[0.1, 0.95 - sz*el, 0.85, sz - 0.01]);
                        fig_number{vid}.XAxis.Visible = 'off';
                    end
                    [fig_number{vid}, result] = obj(vid).rois(el).plot_result(fig_number{vid}, normalize);                    
                    all_data{vid} = [all_data{vid}, result(:, 1)];
                end

                %% When using subplot, link x axes
                all_taxis{vid} = result(:, 2);
                if use_subplots
                    fig_number{vid}.XAxis.Visible = 'on';
                    xlabel('Frames');
                    linkaxes(fig_number{vid}.Parent.Children, 'x');
                end
            end
        end
        
        function clear_results(obj, ROI_filter, delete_ROI)
            %% Clear results matching ROI_filter, or delete ROI
            % -------------------------------------------------------------
            % Syntax: 
            %   Video.clear_results(ROI_filter, delete_ROI)
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
            % See also: Recording.clear_results, Experiment.clear_results
                       
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
            if delete_ROI
                obj.pop(to_clear);
            else
                for el = sort(unique(to_clear))
                    if isprop(obj.rois(el).extracted_data, obj.current_varname)
                        obj.rois(el).extracted_data.(obj.current_varname) = [];
                    end
                end
            end
        end
        
        
        function pop(obj, roi_idx)
            %% Remove a specific roi(s) objct based on the index
            % -------------------------------------------------------------
            % Syntax: 
            %   Video.pop(video_type_idx)
            % -------------------------------------------------------------
            % Inputs:
            %   roi_idx (INT)
            %   	delete roi at specified location
            % -------------------------------------------------------------
            % Outputs: 
            % -------------------------------------------------------------
            % Extra Notes:
            % * For name-based deletion, see clear_results()
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also: Video.clear_results
            
            obj.rois(roi_idx) = [];
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
        
        function set.ROI_location(obj, ROI_location)
            obj.rois = ROI(obj);

            for roi = 1:numel(ROI_location)
                obj.rois(roi) = ROI(obj);
                obj.rois(roi).ROI_location  = ROI_location{roi};
            end
        end
        
        function set.roi_labels(obj, roi_labels)
            if numel(roi_labels) == obj.n_roi
                for roi = 1:numel(roi_labels)
                    obj.rois(roi).name  = roi_labels{roi};
                end
            else
                error('You must set a label for each roi')
            end
        end

        function set.extracted_results(obj, extracted_results)
            %% Set the Motion indices
            % -------------------------------------------------------------
            % Syntax: 
            %   Video.extracted_results = extracted_results;
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   extracted_results (1 x N CELL ARRAY of T x 2 MATRIX)
            %   	For each N ROI, a CELL with a T x 2 Matrix (values, 
            %   	time).
            % -------------------------------------------------------------
            % Extra Notes:
            % * The number of cell in extracted_results must match
            %   Video.n_roi
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   21-05-2020
            
            if numel(extracted_results) == 1 && isempty(extracted_results)
                obj.clear_results();
            elseif numel(extracted_results) ~= obj.n_roi
                error('Number of results provided does not match the number of results available. Use ')        
            else
                for roi = 1:obj.n_roi
                    if isprop(obj.rois(roi).extracted_data, obj.rois(roi).current_varname)
                        obj.rois(roi).extracted_data.(obj.rois(roi).current_varname) = extracted_results{roi};
                    end
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
                ROI_location{roi} = obj.rois(roi).ROI_location;
                if ~isempty(ROI_location{roi})
                    ROI_location{roi}(1:2) = ROI_location{roi}(1:2) + obj.video_offset;
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

        function extracted_results = get.extracted_results(obj)
            %% Return result for each ROI
            % -------------------------------------------------------------
            % Syntax: 
            %   extracted_results = Video.extracted_results
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   extracted_results (1 x N CELL ARRAY of T x 2 MATRIX)
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
            
            extracted_results    = cell(1, obj.n_roi);
            for roi = 1:obj.n_roi
                if isprop(obj.rois(roi).extracted_data, obj.rois(roi).current_varname)
                    extracted_results{roi} = obj.rois(roi).extracted_data.(obj.rois(roi).current_varname);
                    if ~isempty(extracted_results{roi})
                        if size(extracted_results{roi}, 1) == size(obj.t,1) && size(extracted_results{roi}, 2) == 1
                            extracted_results{roi} = [extracted_results{roi}, obj.t];  
                        elseif size(extracted_results{roi}, 1) == size(obj.t,1) && size(extracted_results{roi}, 2) == 2
                            extracted_results{roi} = extracted_results{roi};                              
                        elseif size(extracted_results{roi}, 1) > size(obj.t,1)
                            fprintf(['there are more video frames than timestamp values in ',obj.path,' Timestamp export may have failed\n']);
                        elseif size(extracted_results{roi}, 1) < size(obj.t,1)
                            fprintf(['there are more timestamp values in ',obj.path,' than video frames.  Video recording or export may have failed\n']);
                        else
                            fprintf(['Problem interpreting data. Extracted data should return a single column of data\n']);
                        end
                    end
                else
                    extracted_results{roi} = [];
                end
            end
        end
        
        function reference_image = get.reference_image(obj)
            %% Return or generate video reference image
            % -------------------------------------------------------------
            % Syntax: 
            %   reference_image = Video.reference_image
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   reference_image (X x Y DOUBLE)
            %   	A reference image for the selected video
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   25-05-2020
            
            if isempty(obj.reference_image) && ~any(arrayfun(@(x) contains(x.name, 'uisave'), dbstack))               
                try
                    video = VideoReader(obj.path); 
                    video.CurrentTime = 0;
                    vidFrame = readFrame(video);
                    obj.reference_image = double(adapthisteq(rgb2gray(vidFrame))); 
                catch
                    out = dir(obj.path);
                    if out.bytes < 1000
                        obj.reference_image = [];
                        warning(['File ',obj.path,' looks empty and should probably be deleted'])
                    else
                        error('Video cannot be read. A common cause is a missing codc. Try installing the proper codec and restart MATLAB. A good test to know if it should work is if you can load the video in Windows Media Player')  
                    end
                end

            end
            reference_image = obj.reference_image;
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
        
        function t = get.t(obj)
            %% Set timing info if missing
            if isempty(obj.timestamps) 
                if any(arrayfun(@(x) contains(x.name, 'uisave'), dbstack))
                    t = NaN;
                    return
                end
                set_timestamps(obj);
            end
            
            %% Return t
            if isdatetime(obj.absolute_times(1))
                if obj.timestamps(1) > 0
                    set_timestamps(obj);
                end
                t = obj.timestamps + posixtime(obj.absolute_times(1)) + rem(second(obj.absolute_times(1)),1); % posixtime in seconds
            else
                t = obj.absolute_times(1);
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
        
        function current_varname = get.current_varname(obj)
            current_varname = obj.parent_h.parent_h.parent_h.current_varname;
        end
        
        function set.current_varname(obj, current_varname)
            obj.parent_h.parent_h.parent_h.current_varname = current_varname;
        end
    end
end

