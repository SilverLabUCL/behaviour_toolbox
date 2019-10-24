classdef Analysis_Set
    % This is the container for the analysis. 
    
    properties
        experiments = Experiment;
        video_folder = '';
        n_expe = 0;
        default_tags = {'Whisker', 'Nose', 'Jaw', 'Breast', 'Wheel', 'Laser', 'Caudal Forelimb', 'Trunk', 'Tail', 'Eye'};
    end
    
    
    
    methods
        function obj = Analysis_Set()
            obj.add_experiment();
        end
        
        function n_expe = get.n_expe(obj)
            n_expe = numel(obj.experiments);
        end
        
        function obj = pop(obj, expe_number)
            obj.experiments(expe_number) = [];
        end
        
        function add_experiment(obj, to_add)
            if nargin < 2
                to_add = 1;
            end
            if ~isempty(obj.experiments.recordings)
                obj.experiments(end + to_add) = Experiment;
            else
                obj.experiments = Experiment; % first object
            end
        end
        
    end
end

