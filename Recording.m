%% Recording Class
% 	This the class container for all the Video of an recording
%
%   Type doc Experiment.function_name or Experiment Class.function_name 
%   to get more details about the methods inputs and outputs.
% -------------------------------------------------------------------------
% Model: 
%   this = Recording();
% -------------------------------------------------------------------------
% Class Generation Inputs: 
% -------------------------------------------------------------------------
% Outputs: 
%   this (Recording object)
% -------------------------------------------------------------------------
% Methods Index (ignoring get()/set() methods):
%
% * Update video list if you chenged in in the recording
%   Recording.update()
%
% * Remove a specific video / set of videos
%   Recording.pop(vid_number)
% -------------------------------------------------------------------------
% Extra Notes:
%   For now, Recording is NOT a handle, which means you have to reassign
%   the ouput of the object to itself
% -------------------------------------------------------------------------
% Examples - How To
%
% * Refresh video list if you deleted a recording
%   s = Analysis_Set();
%   s.experiments(1) = s.experiments(1).populate(experiment_path);
%   s.experiments(1).recordings(1) = s.experiments(1).recordings(1).update
%
% * Remove one video in a specific recording
%   s.experiments(1).recordings(2) = s.experiments(1).recordings(2).pop(1)
% -------------------------------------------------------------------------
% Author(s):
%   Antoine Valera
% -------------------------------------------------------------------------
% Revision Date:
% 21-04-2020
%
% See also Experiment, Video


classdef Recording
   
    properties
        videos              ; % List of Video objects in this recording
        n_vid = 0           ; % Number of videos in the recording
        path                ; % Path of the recording
        videotypes          ; % List the types of videos in this recording
        roi_labels          ; % List of the ROI labels per Video
        reference_images 	; % Reference image per Video
        name                ; % User-defined recording name
        duration            ; % recording duration
        t_start             ; % recording t start
        t_stop              ; % recording t stop
        trial_number        ; % number of trials in the recording
        motion_indexes      ; % MI per video per ROI
        comment             ; % User comment
        default_video_types = {'EyeCam'           ,...
                               'BodyCam'          ,...
                               'WhiskerCam'}      ; % Default camera names
    end
    
    methods
        function obj = Recording(n_video, recording_path)
            if nargin < 1
                n_video         = 0; % Empty recording
            end
            if nargin < 2
                recording_path  = '';   % Empty recording
            end
            obj.videos          = repmat(Video, 1, n_video);
            obj.path            = recording_path;
        end
        
        function n_vid = get.n_vid(obj)
            %% Return the number of video available
            n_vid = numel(obj.videos);
        end
        
        function obj = update(obj)
            obj = update_recording(obj, dir([obj.path, '/**/*.avi']));
        end
        
        function obj = pop(obj, video_type_idx)
            %% Remove a specific video objct based on the video index
            obj.videos(video_type_idx) = [];
        end
        
        function videotypes = get.videotypes(obj)
            %% List all video_types available in the Children
            %videotypes = {obj.videos.path};
            videotypes = {obj.videos.video_types};
        end 

        function reference_images = get.reference_images(obj)
            %% Get reference image per Video
            reference_images = {obj.videos.reference_image};
        end 

        function motion_indexes = get.motion_indexes(obj)
            %% Get 
            motion_indexes = {};
            for vid = 1:obj.n_vid
                motion_indexes = [motion_indexes, {obj.videos(vid).motion_indexes}];
            end
        end

        function roi_labels = get.roi_labels(obj)
            %% Get 
            roi_labels = {};
            for vid = 1:obj.n_vid
                roi_labels = [roi_labels, {obj.videos(vid).roi_labels}];
            end
            roi_labels = [roi_labels{:}];
            try
                roi_labels = unique(roi_labels(cellfun('isclass', roi_labels, 'char')));
            catch
                1
            end            
        end 

        function t_start = get.t_start(obj)
            t_start = [];
            for vid = 1:obj.n_vid
                t_start = [t_start, t_start, nanmin(obj.videos(vid).absolute_times)];
            end
            t_start = nanmin(t_start);
        end
    end
end

