classdef Experiment
    %EXPERIMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        recordings = Recording;
        expe_path
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
            n_rec = numel(obj.recordings);
        end        
    end
end

