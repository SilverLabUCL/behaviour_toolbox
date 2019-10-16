classdef Video
    %EXPERIMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        reference_image
        ROI_location
        motion_indexes
        timestamps
        file_path
        video_types
        absolute_times 
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
            obj.ROI_location    = cell(1, n_roi);
            obj.motion_indexes  = cell(1, n_roi);
            obj.reference_image = cell(1, n_roi);
            obj.timestamps      = cell(1, n_roi);
            obj.video_types     = cell(1, n_roi);
            obj.absolute_times  = cell(1, n_roi);
        end
    end
end

