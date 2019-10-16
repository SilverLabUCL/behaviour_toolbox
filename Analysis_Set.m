classdef Analysis_Set
    % This is the container for the analysis. 
    
    properties
        recordings = Recording;
        video_folder = '';
        n_expe = 0;
    end
    
    
    
    methods
        function obj = Analysis_Set()
            obj.add_experiment();
        end
        
        function n_expe = get.n_expe(obj)
            n_expe = numel(obj.recordings);
        end
        
        function pop(obj, expe_number)
            obj.recordings(expe_number) = [];
        end
        
        function add_experiment(obj, to_add)
            if nargin < 2
                to_add = 1;
            end
            if ~isempty(obj.recordings.filenames)
                obj.recordings(end + to_add) = Recording;
            else
                obj.recordings = Recording; % first object
            end
        end
        
    end
end

