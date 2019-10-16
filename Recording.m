classdef Recording
    %EXPERIMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        n_vid = 0;
        recording_path
        videos
        videotypes
        reference_images
    end
    
    methods
        function obj = Recording(n_video, recording_path)
            if nargin < 1
                n_video = 0; % Empty recording
            end
            if nargin < 2
                recording_path = '';   % Empty recording
            end
            obj.videos          = repmat(Video, 1, n_video);
            obj.recording_path  = recording_path;
        end
        
        function n_vid = get.n_vid(obj)
            %% Return the number of video available
            n_vid = numel(obj.videos);
        end
        
        function pop(obj, video_type_idx)
            try
                obj.filenames(video.file_path)      = [];
                obj.video_types(video.file_path)    = [];
                obj.ROI_location(video.file_path)   = [];
                obj.reference_image{video_type_idx} = []; % will force the regeneration of the thumbail
                % This part could fail if there was no export yet
                obj.motion_indexes(video.file_path) = [];
                obj.timestamps(video.file_path)     = [];
                obj.absolute_times(video.file_path) = [];
            end
        end
        
        function videotypes = get.videotypes(obj)
            %% List all video_types available in the Children
            videotypes = {obj.videos.file_path};
        end 

        function reference_images = get.reference_images(obj)
            %% Get reference image per Video
            reference_images = {obj.videos.reference_image};
        end 
    end
end

