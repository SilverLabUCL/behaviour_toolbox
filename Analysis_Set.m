%% Analysis_Set Class
% 	This is the top level class for your analysis. 
%
%   Type doc Analysis_Set.function_name or Analysis_Set Class.function_name 
%   to get more details about the methods inputs and outputs.
% -------------------------------------------------------------------------
% Model: 
%   this = Analysis_Set();
% -------------------------------------------------------------------------
% Class Generation Inputs: 
% -------------------------------------------------------------------------
% Outputs: 
%   this (Analysis_Set object)
% -------------------------------------------------------------------------
% Methods Index (ignoring get()/set() methods):
%
% * Remove a specific experiment / set of experiments
%   Analysis_Set.pop(expe_number) 
%
% * Add one / several empty experiment.
%   Analysis_Set.add_experiment(to_add)   
%
% * Update all paths (for example if you change the location of the videos)
%   Analysis_Set.update_path(old, new)
%
% * Remove empty experiments
%   Analysis_Set.cleanup()
% -------------------------------------------------------------------------
% Extra Notes:
% -------------------------------------------------------------------------
% Examples - How To
%
% * Initialise a new Analysis_Set with an empty experiment.
%   my_analysis = Analysis_Set();
%
% * Change the default tags that will be displayed for video extraction
%   my_analysis.default_tags = [my_analysis.default_tags, {'New Preset'}];
%
% * Add 2 empty experiments
%   my_analysis.add_experiment(2);
%
% -------------------------------------------------------------------------
% Author(s):
%   Antoine Valera
% -------------------------------------------------------------------------
% Revision Date:
% 21-04-2020
%
% See also Experiment

classdef Analysis_Set
    properties
        experiments  = Experiment   ; % Contain individual experiments
        video_folder = ''           ; % Top video folder where experiments are located
        n_expe       = 0            ; % Return number of experiments
        default_tags = {'Whisker'   ,...
                        'Nose'      ,...
                        'Jaw'       ,...
                        'Breast'    ,...
                        'Wheel'     ,...
                        'Laser'     ,...
                        'Caudal Forelimb',...
                        'Trunk'     ,...
                        'Tail'      ,...
                        'Eye'}      ; % Default ROI names
    end

    methods
        function obj = Analysis_Set()
            
        end
        
        function n_expe = get.n_expe(obj)
            n_expe = numel(obj.experiments);
        end
        
        function obj = pop(obj, expe_number)
            obj.experiments(expe_number) = [];
        end
        
        function add_experiment(obj, to_add)
            if nargin < 2 || isempty(to_add)
                to_add = 1;
            end
            obj.experiments(end:end + to_add) = Experiment;
        end
        
        
        function cleanup(obj)
            to_remove = [];
            for exp = 1:obj.n_expe    
                if isempty(obj.experiments(exp).recordings)
                    to_remove = [to_remove, exp]; 
                end
            end 
            obj.pop(to_remove);
        end
        
        function update_path(obj, old, new)
            for exp = 1:obj.n_expe    
                obj.experiments(exp).path = strrep(obj.experiments(exp).path,old,new);
                for rec = 1:obj.experiments(exp).n_rec
                    obj.experiments(exp).recordings(rec).path = strrep(obj.experiments(exp).recordings(rec).path,old,new);
                    for vid = 1:obj.experiments(exp).recordings(rec).n_vid
                        obj.experiments(exp).recordings(rec).videos(vid).path = strrep(obj.experiments(exp).recordings(rec).videos(vid).path,old,new);
                        for roi = 1:obj.experiments(exp).recordings(rec).videos(vid).n_roi
                            obj.experiments(exp).recordings(rec).videos(vid).rois(roi);
                        end
                    end
                end
            end           
        end
    end
end

