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
        
        function clear(obj, video_type_idx, video_record)
            try
                obj.filenames{video_type_idx}(video_record) = [];
                obj.video_types{video_type_idx}(video_record) = [];
                obj.MI_windows{video_type_idx}(video_record,:) = [];
                obj.reference_image{video_type_idx} = []; % will force the regeneration of the thumbail
                % This part could fail if there was no export yet
                obj.motion_indexes{video_type_idx}(video_record) = [];
                obj.timestamps{video_type_idx}(video_record) = [];
                obj.absolute_time{video_type_idx}(video_record) = [];
            end
        end
    end
end

