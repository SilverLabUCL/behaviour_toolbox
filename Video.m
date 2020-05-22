classdef Video < handle
    %EXPERIMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rois
        roi_labels
        reference_image
        timestamps
        absolute_times
        path
        video_types
        n_roi
        sampling_rate
        position
        comment
        pixel_size
        quality = 5;
        ROI_location
        video_offset
        motion_indexes
        motion_index_norm
        name
    end
    
    methods
        function obj = Video(n_roi, file_path) 
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
                t = obj.timestamps + posixtime(obj.absolute_times(1)) + rem(second(obj.absolute_times(1)),1); % posixtime in seconds
                obj.motion_indexes = get_MI_from_video(obj.path, obj.ROI_location, t, false, false, '', obj.video_offset);
                metric = obj.motion_indexes;
            else
                metric = func();
            end
        end
        
        function set_timestamps(obj)
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
        
        function plot_MIs(obj, fig_number, use_subplots, use_norm)
            if nargin < 2 || isempty(fig_number)
                fig_number = cell(1,numel(obj));
            end
            if nargin < 3 || isempty(use_subplots)
                use_subplots = false;
            end
            if nargin < 4 || isempty(use_norm)
                use_norm = false;
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
                    fig_number{vid} = obj(vid).rois(el).plot_MI(fig_number{vid}, use_norm);
                end

                %% When using subplot, link x axes
                if use_subplots
                    fig_number{vid}.XAxis.Visible = 'on';
                    xlabel('Frames');
                    linkaxes(fig_number{vid}.Parent.Children, 'x');
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

        function n_roi = get.n_roi(obj)
            %% Return the number of ROI windows
            n_roi = numel(obj.rois);
        end

        function ROI_location = get.ROI_location(obj)
            %% Return the number of ROI windows
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
            if isempty(obj.video_offset)
                video_offset = [0, 0];
            else
                video_offset = obj.video_offset;
            end
        end

        function set.motion_indexes(obj, motion_indexes)
            %% Return the number of ROI windows
            if numel(motion_indexes) == 1 && isempty(motion_indexes)
                obj.clear_MIs();
            else
                for roi = 1:obj.n_roi
                    obj.rois(roi).motion_index = motion_indexes{roi};
                end
            end
        end
        
        function clear_MIs(obj)            
            for roi = 1:obj.n_roi
                obj.rois(roi).motion_index = {};
            end
        end
        
        function clear_ROIs(obj)
            obj.ROIs = {};
        end

        function motion_indexes = get.motion_indexes(obj)
            %% Return MI for each ROI
            motion_indexes    = cell(1, obj.n_roi);
            for roi = 1:obj.n_roi
                motion_indexes{roi} = obj.rois(roi).motion_index;
            end
        end
        
        function motion_index_norm = get.motion_index_norm(obj)
            %% Return normalized MI for each ROI
            motion_index_norm    = cell(1, obj.n_roi);
            for roi = 1:obj.n_roi
                motion_index_norm{roi} = obj.rois(roi).motion_index_norm;
            end
        end

        function roi_labels = get.roi_labels(obj)
            %% Return label for each ROI
            roi_labels    = cell(1, obj.n_roi);
            for roi = 1:obj.n_roi
                roi_labels{roi} = obj.rois(roi).name;
            end
        end
        

        function roi_label = get.video_types(obj)
            %% Return the number of ROI windows
            [~, roi_label] = fileparts(obj.path);
        end
    end
end

