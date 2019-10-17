classdef Experiment
    %EXPERIMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        recordings = Recording;
        expe_path
        videotypes
        n_rec = 0;
        global_reference_images
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
            obj.expe_path     = expe_path;
        end
        
        function n_rec = get.n_rec(obj)
            %% Return the number of recordings available (including empty)
            n_rec = numel(obj.recordings);
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

        function global_reference_images = get.global_reference_images(obj)
            %% List all video_types available in the Children
            global_reference_images = {};
            for rec = 1:obj.n_rec
                global_reference_images = [global_reference_images; obj.recordings(rec).reference_images];
            end
            
            %% Do some operation here
        end 

        function find_missing_video(obj)
            %% TODO
       
            
            %% Do some operation here
        end 
    end
end

