classdef Experiment
    %EXPERIMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        recordings = Recording;
        path
        videotypes
        roi_labels
        n_rec = 0;
        global_reference_images
        t_start % experiment t_start
        comment
    end
    
    methods
        function obj = Experiment(n_recordings, expe_path)
            if nargin < 1
                n_recordings = 0; % Empty recording
            end
            if nargin < 2
                expe_path = '';   % Empty recording
            end
            obj.recordings    = repmat(Recording, 1, n_recordings);
            obj.path          = expe_path;
        end
        
        function n_rec = get.n_rec(obj)
            %% Return the number of recordings available (including empty)
            n_rec = numel(obj.recordings);
        end    
   
        function obj = pop(obj, recording_idx)
            %% Remove a specific recording objct based on the video index
            obj.recordings(recording_idx) = [];
        end

        function videotypes = get.videotypes(obj)
            %% List all video_types available in the Children
            filenames = {};
            for rec = 1:obj.n_rec
                filenames = [filenames, obj.recordings(rec).videotypes];
            end
            
            %% Create a helper to extract video name
            function second = Out2(varargin)
                [~,second] = fileparts(varargin{:}); % get only the second output of the function
            end
            filenames = cellfun(@(x) Out2(x),filenames,'UniformOutput',false);
            
            %% Regroup videos by video type (eyecam, bodycam etc...)
            videotypes = unique(filenames(cellfun('isclass', filenames, 'char')));
        end   

        function roi_labels = get.roi_labels(obj)
            %% List all video_types available in the Children
            roi_labels = {};
            for rec = 1:obj.n_rec
                roi_labels = [roi_labels, obj.recordings(rec).roi_labels];
            end

            %% Regroup videos by video type (eyecam, bodycam etc...)
            roi_labels = unique(roi_labels(cellfun('isclass', roi_labels, 'char')));
        end   

        function global_reference_images = get.global_reference_images(obj)
            %% List all video_types available in the Children
            global_reference_images = {};
            for rec = 1:obj.n_rec
                try
                    global_reference_images = [global_reference_images; obj.recordings(rec).reference_images];
                catch
                    %% Typically, there's a video missing for that record
                    % We find which one and fill the others with NaN
                    current_types = cellfun(@(x) erase(strsplit(x,'/'),'.avi'), obj.recordings(rec).videotypes,'UniformOutput',false);
                    current_types = current_types{1}{1,end};
                    
                    new = cell(1, size(global_reference_images, 2));
                    new{~ismember(obj.videotypes, current_types)} = NaN;
                    global_reference_images = [global_reference_images; new]; % when a video is missing, put en empty cell instead
                end
            end
            
            %% Do some operation here
        end 

        function t_start = get.t_start(obj)
            t_start = NaN;
            for rec = 1:obj.n_rec
                t_start = [t_start, nanmin(obj.recordings(rec).t_start)];
            end
            t_start = nanmin(t_start);
        end

        function find_missing_video(obj)
            %% TODO
       
            
            %% Do some operation here
        end 
    end
end

