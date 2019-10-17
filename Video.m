classdef Video
    %EXPERIMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rois
        reference_image
        timestamps
        file_path
        video_types
        n_roi
        sampling_rate
        position
        comment
        pixel_size
        quality = 5;
        ROI_location
        motion_indexes
    end
    
    methods
        function obj = Video(n_roi, file_path)
            if nargin < 1
                n_roi = 0; % Empty recording
            end
            if nargin < 2
                file_path = ''; % Empty recording
            end
            obj.file_path       = file_path;
            obj.reference_image = [];
            obj.timestamps      = cell(1, n_roi);
            obj.video_types     = cell(1, n_roi);
            obj.rois            = repmat(ROI, 1, n_roi);
        end

        function n_roi = get.n_roi(obj)
            %% Return the number of ROI windows
            n_roi = numel(obj.rois);
        end

        function ROI_location = get.ROI_location(obj)
            %% Return the number of ROI windows
            ROI_location    = cell(1, obj.n_roi);
            for roi = 1:obj.n_roi
                ROI_location{roi} = obj.rois(roi).ROI_location;
            end
        end


        function motion_indexes = get.motion_indexes(obj)
            %% Return the number of ROI windows
            motion_indexes    = cell(1, obj.n_roi);
            for roi = 1:obj.n_roi
                motion_indexes{roi} = obj.rois(roi).motion_index;
            end
        end
    end
end

