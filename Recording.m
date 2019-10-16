classdef Recording
    %EXPERIMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        reference_image
        MI_windows
        motion_indexes
        timestamps
        filenames
        video_types
        absolute_time
    end
    
    methods
        function obj = Recording(n_video_types)
            if nargin < 1
                n_video_types = 0; % Empty recording
            end
            obj.MI_windows      = cell(1, n_video_types);
            obj.motion_indexes  = cell(1, n_video_types);
            obj.reference_image = cell(1, n_video_types);
            obj.timestamps      = cell(1, n_video_types);
            obj.filenames       = cell(1, n_video_types);
            obj.video_types     = cell(1, n_video_types);
            obj.absolute_time   = cell(1, n_video_types);
        end
        
        function outputArg = method1(obj,inputArg)
            
        end
    end
end

