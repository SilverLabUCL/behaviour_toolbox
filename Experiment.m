classdef Experiment
    %EXPERIMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        recordings = Recording;
        expe_path
        videotypes
        n_rec = 0;
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
    end
end

