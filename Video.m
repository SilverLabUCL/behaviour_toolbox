classdef Video
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
            obj.rois            = repmat(ROI, 1, n_roi);
        end
        
        
        function [obj, out] = analyze(obj, func)
            if nargin < 2 || isempty(func)
                default = true;
            else
                default = false;
            end
            
            %% Set timing info if missing
            if isempty(obj.timestamps)
                obj = set_timestamps(obj);
            end

            %% Get MI (or other function handle)
            if default
                obj.motion_indexes = get_MI_from_video(obj.path, obj.ROI_location, obj.absolute_times, false, false, '', obj.video_offset);
                out = obj.motion_indexes;
            else
                out = func();
            end
        end
        
        function obj = set_timestamps(obj)
            timepstamp_path     = strsplit(strrep(obj.path,'/','\'),'Cam');
            timepstamp_path     = [timepstamp_path{1},'Cam-relative times.txt'];

            %% To use the parent folder instead (because it has absolute timestamps)
            timepstamp_path     = strsplit(timepstamp_path,'\');
            timepstamp_path     = strjoin(timepstamp_path([1:end-2,end]),'\');

            if isfile(timepstamp_path)
                fileID = fopen(timepstamp_path,'r');
                timescale = textscan(fileID, '%f%f%s%[^\n\r]', 'Delimiter', '\t', 'TextType', 'string', 'EmptyValue', NaN,  'ReturnOnError', false);
                fclose(fileID);

                %% Get real time
                time                = cellfun(@(timepoint) strsplit(timepoint, ';'), timescale{3}, 'UniformOutput', false); % separate day from time
                time                = cellfun(@(timepoint) cellfun(@str2num, (strsplit(timepoint{2},':'))), time, 'UniformOutput', false); % separte hr, min, s
                obj.absolute_times  = cell2mat((cellfun(@(timepoint) sum(timepoint .* [3600000, 60000, 1000]), time, 'UniformOutput', false))); % convert all to ms

                %% Get camera timestamps
                obj.timestamps      = timescale{2}/1000;
                obj.sampling_rate   = 1/mean(diff(obj.absolute_times))*1000;
            else
                fprintf(['timestamps not found for video ',obj.path,' \n']);
            end
        end
        
        function plot_MIs(obj)
            temp = cell2mat(obj.motion_indexes);
            temp = temp - prctile(temp,1);
            temp = temp ./ max(temp);
            figure(123);clf();plot(temp(:,1:2:end)); drawnow
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

        function obj = set.motion_indexes(obj, motion_indexes)
            %% Return the number of ROI windows
            for roi = 1:obj.n_roi
                obj.rois(roi).motion_index = motion_indexes{roi};
            end
        end

        function motion_indexes = get.motion_indexes(obj)
            %% Return the number of ROI windows
            motion_indexes    = cell(1, obj.n_roi);
            for roi = 1:obj.n_roi
                motion_indexes{roi} = obj.rois(roi).motion_index;
            end
        end

        function roi_labels = get.roi_labels(obj)
            %% Return the number of ROI windows
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

