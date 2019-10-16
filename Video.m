classdef Video
    %EXPERIMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        reference_image
        ROI_location
        motion_indexes
        timestamps
        filenames
        video_types
        absolute_times 
    end
    
    methods
        function obj = Video(n_roi)
            if nargin < 1
                n_roi = 0; % Empty recording
            end
            obj.ROI_location    = cell(1, n_roi);
            obj.motion_indexes  = cell(1, n_roi);
            obj.reference_image = cell(1, n_roi);
            obj.timestamps      = cell(1, n_roi);
            obj.filenames       = cell(1, n_roi);
            obj.video_types     = cell(1, n_roi);
            obj.absolute_times  = cell(1, n_roi);
        end
    end
end

