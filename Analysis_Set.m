%% Analysis_Set Class
% 	This is the top level class for your analysis. 
%
%   Type doc Analysis_Set.function_name or Analysis_Set Class.function_name 
%   to get more details about the methods inputs and outputs.
% -------------------------------------------------------------------------
% Syntax: 
%   this = Analysis_Set();
% -------------------------------------------------------------------------
% Class Generation Inputs:
%   video_folder(STR) - Optional
%                               Path to you top video folder, that contains
%                               all the videos. If provided, the folder
%                               will be set to Analysis_Set.video_folder
%
% -------------------------------------------------------------------------
% Outputs: 
%   this (Analysis_Set object)    
% -------------------------------------------------------------------------
% Class Methods (ignoring get()/set() methods):
%
% * Remove a specific experiment / set of experiments
%   Analysis_Set = Analysis_Set.pop(expe_number) 
%
% * Add one / several empty experiment.
%   Analysis_Set = Analysis_Set.add_experiment(to_add)   
%
% * Update all paths (for example if you change the location of the videos)
%   Analysis_Set = Analysis_Set.update_path(old, new)
%
% * Remove empty experiments
%   Analysis_Set = Analysis_Set.cleanup()
%
% -------------------------------------------------------------------------
% Extra Notes:
%   For now, Analysis_Set is NOT a handle, which means you have to reassign
%   the ouput of the object to itself
%
% -------------------------------------------------------------------------
% Examples: 
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
%
% -------------------------------------------------------------------------
%                               Notice
%
% Author(s): Antoine Valera
%
% This function was initially released as part of a toolbox for 
% manipulating Videos acquired in the SIlverlab. The software was 
% developed in the laboratory of Prof Robin Angus Silver at University
% College London with funds from the NIH, ERC and Wellcome Trust.
%
% Copyright © 2015-2020 University College London
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%     http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License. 
% -------------------------------------------------------------------------
% Revision Date:
% 21-04-2020
%
% See also: Experiment

%% TODO : Convert to handle, but make sure the subset are handled properly

classdef Analysis_Set
    properties
        experiments  = []           ; % Contain individual experiments
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
        folder_exclusion = {' unidentified'} ; % path containing elements in this list are ignored
        videotypes = {}             ; % List all existing videos types
    end

    methods
        function obj = Analysis_Set(video_folder)  
            %% Analysis_Set Object Constructor. 
            % -------------------------------------------------------------
            % Syntax: 
            %   this = Analysis_Set(video_folder)
            % -------------------------------------------------------------
            % Inputs:
            %   video_folder (STR)
            %       path to the top folder containing all videos
            % -------------------------------------------------------------
            % Outputs: 
            %   this (Analysis_Set)
            %   	The container for all the analyzed data
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            %   * Create a new analysis object
            %     my_analysis = Analysis_Set();
            %
            %   * Create a new analysis object and assign a video_folder
            %     my_analysis = Analysis_Set('/Top/Folder/path');
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            
            if nargin == 1
                obj.video_folder = video_folder;
                fprintf('video_folder added. call Analysis_Set.update() to add all containing experiments.\n')
            end
        end
 
        function obj = update(obj, filter_list)
            %% Update all videos. add new folder, remove old ones.
            % -------------------------------------------------------------
            % Syntax: 
            %   Analysis_Set = Analysis_Set.update(filter_list)
            % -------------------------------------------------------------
            % Inputs:
            %   filter_list(Cell of STR) - Optional - default is '';
            %       if non empty, only path that contains elements in the
            %       filter list will be updated
            % -------------------------------------------------------------
            % Outputs: 
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            %
            % * Update all videos in video_folder
            %   my_analysis = my_analysis.update();
            %
            % * Update a specific folder only
            %   my_analysis = my_analysis.update({'2018-12-04'});
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            
            if nargin < 2 || isempty(filter_list)
                filter_list = {};
            end
            
            %% Get all experiments in the video folder
            experiment_folders = dir([obj.video_folder, '/*-*-*/experiment_*']); 
            if isempty(obj.video_folder) || ~isdir(obj.video_folder) || isempty(experiment_folders)
                error('You must set a valid video_folder path in your Experiment Set. If you changed computer or moved your files, adjust Analysis_set.video_folder')
            end
            
            %% Print selected folders. Filter excluded sets.
            for el = numel(experiment_folders):-1:1
                current_expe_path = [strrep(experiment_folders(el).folder,'\', '/'),'/',experiment_folders(el).name, '/'];
                if contains(current_expe_path, obj.folder_exclusion) || ~isdir(current_expe_path)
                    experiment_folders(el) = [];
                else
                    fprintf([current_expe_path, '\n'])
                end
            end

            %% Use this function to edit the fname field or check for modified files
            [obj, experiment_folders] = check_or_fix_path_issues(obj, experiment_folders, filter_list);

            %% Go through all experiment folder. Add experiments if missing
            splitvideo              = {}; % that will indicates problematic split videos
            %subset                  = []; 
            for experiment_idx = 1:numel(experiment_folders)
                current_expe_path                   = experiment_folders{experiment_idx};
                [obj, experiment_idx]               = obj.add_experiment(current_expe_path); %% add or update experiment
                splitvideo                          = [splitvideo, obj.experiments(experiment_idx).splitvideos]; % if any
                %subset                              = [subset, experiment_idx]; % store correct indexes

                %% Sort alphabetically and remove empty experiments
                obj.experiments(experiment_idx)     = obj.experiments(experiment_idx).cleanup();
            end
            %obj.experiments         = obj.experiments(subset); % in case you filtered the input, we filter the ouput

            %% final adjustements
            obj = obj.cleanup();
        end 

        function [obj, experiment_idx, is_split] = add_experiment(obj, to_add)
            %% Add a specific experiment
            % -------------------------------------------------------------
            % Syntax: 
            %   [Analysis_Set, experiment_idx, is_split] = 
            %               Analysis_Set.add_experiment(to_add)
            % -------------------------------------------------------------
            % Inputs:
            %   to_add(INT or STR PATH or Cell ARRAY of STR PATH)
            %   	- If int, create N empty experiments
            %       - if STR or CELL ARRAY, add the indicated path(s).
            % -------------------------------------------------------------
            % Outputs: 
            %   Analysis_Set (Analysis_Set object)
            %   	Updated Analysis_Set
            %
            %   experiment_idx (1 x N INT)
            %   	Index(es) of the added experiments
            %
            %   is_split (?)
            %   	Indicate problematic split-videos
            % -------------------------------------------------------------
            % Extra Notes:
            % * When adding path, it must be an experiment_folder, not a
            %   day_folder
            %
            % * If you add an experiment that is already here, this will
            %   force the update of the existing one.
            % -------------------------------------------------------------
            % Examples:
            %   
            % * Add 4 empty experiments
            %   my_analysis = my_analysis.add_experiment(4);
            %
            % * Add an experiment with a known path
            %   fold = 'D:\topfolder\2018-12-03\experiment_1';
            %   my_analysis = my_analysis.add_experiment(fold);
            %
            % * Add 2 experiments with known paths
            %   folds = {'D:\topfolder\2018-12-03\experiment_1',...
            %            'D:\topfolder\2018-12-03\experiment_2'};
            %   my_analysis = my_analysis.add_experiment(folds);
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            %
            % See also: Analysis_Set.update

            if nargin < 2 || isempty(to_add)
                to_add = 1;
            end
            
            is_split = NaN;
            if isnumeric(to_add)  
                %% Add one/several empty experiments
                if isempty(obj.experiments)
                    experiment_idx  = 1:to_add;
                    obj.experiments = repmat(Experiment,1,to_add);
                else
                    experiment_idx  = (numel(obj.experiments) + 1):(numel(obj.experiments)+ to_add);
                    obj.experiments(end + 1:end + to_add) = Experiment;
                end
            elseif ischar(to_add)
                %% Add/Update experiments using path 
                [experiment_idx, expe_already_there]        = obj.check_if_new_expe(to_add);
                if isempty(obj.experiments)
                    obj.experiments                         = Experiment;
                    experiment_idx                          = 1         ;
                elseif ~expe_already_there
                    obj.experiments(experiment_idx)         = Experiment;
                else
                    %% Then it's an update
                end
                obj.experiments(experiment_idx)             = obj.experiments(experiment_idx).populate(to_add);
            elseif iscell(to_add)
                experiment_idx = [];
                is_split       = {};
                for el = 1:numel(to_add)
                    [obj, experiment_idx(el), is_split{el}] = add_experiment(obj, to_add{el});
                end  
            else
                error('must pass INT or STR path or CELL ARRAY of STR PATH')
            end
        end

        function obj = pop(obj, to_remove)
            %% Delete experiment at index(es) expe_number
            % -------------------------------------------------------------
            % Syntax: 
            %   Analysis_Set = Analysis_Set.pop(to_remove)             
            % -------------------------------------------------------------
            % Inputs:
            %   to_remove(1 x N INT or STR PATH or Cell ARRAY of STR PATH)
            %   	- If 1 x N INT, remove experiments at specified
            %   	index(es)
            %       - if STR or CELL ARRAY, remove all the experiment whose
            %       path match the input 
            % -------------------------------------------------------------
            % Outputs: 
            %   Analysis_Set (Analysis_Set object)
            %   	Updated Analysis_Set
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            %   
            % * Remove experiment 5 and 6
            %   my_analysis = my_analysis.pop([5, 6]);
            %   
            % * Remove all experiments the '2018-12-04' and an experiment
            %   called 'experiment_12'
            %   my_analysis = my_analysis.pop({'2018-12-04','experiment_2'}); 
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            
            if ischar(to_remove) || iscell(to_remove)
                to_remove = find(contains({obj.experiments.path}, to_remove));
            end
            obj.experiments(to_remove) = [];
        end
        
        function obj = cleanup(obj)
            %% Remove experiments with no recordings, 
            %   Function also sort experiments alphabetically
            % -------------------------------------------------------------
            % Syntax: 
            %   Analysis_Set = Analysis_Set.cleanup()             
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   Analysis_Set (Analysis_Set object)
            %   	Updated Analysis_Set
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020

            to_remove = [];
            for exp = 1:obj.n_expe    
                if isempty(obj.experiments(exp).recordings)
                    to_remove = [to_remove, exp]; 
                end
            end 
            obj = obj.pop(to_remove);
            
            %% Sort alphabetically
            [~, idx] = sort({obj.experiments.path});
            obj.experiments = obj.experiments(idx); 
            
            %% Empty experiments can be detected here 
            %invalid = arrayfun(@(x) isempty(x.path), obj.experiments);
        end

        function obj = update_children_paths(obj, old, new)
            %% Set a new video_folder. If possible, update path in Childrens
            % -------------------------------------------------------------
            % Syntax: 
            %   Analysis_Set = Analysis_Set.update_children_paths(old, new)
            % -------------------------------------------------------------
            % Inputs:
            %   old (STR PATH)
            %   	The part of the path to replace
            %   new (STR PATH)
            %   	The new adjusted path
            % -------------------------------------------------------------
            % Outputs: 
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            %
            % * Changed HD where video are located
            %   my_analysis = my_analysis.update_children_paths('C:/','D:/')
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            %
            % See also: Analysis_Set.update_children_paths
            
            for exp = 1:obj.n_expe    
                obj.experiments(exp).path = strrep(obj.experiments(exp).path, old, new);
                for rec = 1:obj.experiments(exp).n_rec
                    obj.experiments(exp).recordings(rec).path = strrep(obj.experiments(exp).recordings(rec).path,old,new);
                    for vid = 1:obj.experiments(exp).recordings(rec).n_vid
                        obj.experiments(exp).recordings(rec).videos(vid).path = strrep(obj.experiments(exp).recordings(rec).videos(vid).path, old, new);
                        for roi = 1:obj.experiments(exp).recordings(rec).videos(vid).n_roi
                            obj.experiments(exp).recordings(rec).videos(vid).rois(roi);
                        end
                    end
                end
            end           
        end
        
        function [experiment_idx, expe_already_there] = check_if_new_expe(obj, expe_path)
            %% Check if this experiment has already be listed somewhere.
            % If yes, return the correct index
            % If not, return a new, unused index
            % -------------------------------------------------------------
            % Syntax: 
            %   [experiment_idx, expe_already_there] = 
            %               Analysis_Set.check_if_new_expe(expe_path)
            % -------------------------------------------------------------
            % Inputs:
            %   expe_path (STR PATH)
            %   	The experiment to check
            % -------------------------------------------------------------
            % Outputs: 
            %   experiment_idx (INT)
            %   	The new experiment location index
            %   expe_already_there (BOOL)
            %   	True if the experiment was already there
            % -------------------------------------------------------------
            % Extra Notes:
            % * If you changed hard drive, run update_children_paths()
            %   first before testing location or adding new experiments, or
            %   you may end with duplicates
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            %
            % See also: Analysis_Set.add_experiment
            
            expe_path = strrep([expe_path,'/'], '\', '/'); expe_path = strrep(expe_path, '//', '/');
            expe_already_there      = false;

            %% If we find the experiment somewhere, we update the index
            for el = 1:obj.n_expe
                if ~isempty(obj.experiments(el).path) && strcmp(obj.experiments(el).path, expe_path)
                    %% Adjust exp_idx
                    experiment_idx       = el;
                    expe_already_there   = true;  
                    break
                end
            end

            %% If it is the first time we see this experiment, we'll have to create a new one, so we return a undused index
            if ~expe_already_there
                %% Add new experiment
                experiment_idx = obj.n_expe + 1;
            end
        end
        
        function obj = set.video_folder(obj, new_video_folder)
            %% Set a new video_folder. If possible, update path in Childrens
            % -------------------------------------------------------------
            % Syntax: 
            %   Analysis_Set.video_folder = new_video_folder
            % -------------------------------------------------------------
            % Inputs:
            %   new_video_folder (STR PATH)
            %   	The top folder containing all the videos
            % -------------------------------------------------------------
            % Outputs: 
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            %
            % See also: Analysis_Set.update_children_paths
            
            if ~isempty(obj.video_folder) && ~isempty(new_video_folder)
                obj = update_children_paths(obj, obj.video_folder, new_video_folder);
            end
            obj.video_folder = new_video_folder;
        end
        
        
        function n_expe = get.n_expe(obj)
            %% Return the number of experiment in the database
            % -------------------------------------------------------------
            % Syntax: 
            %   n_expe = Analysis_Set.n_expe
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   n_expe (INT)
            %   	The number of experiments in the database
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            
            n_expe = numel(obj.experiments);
        end

        function video_folder = get.video_folder(obj)
            %% Return the number of experiment in the database
            % -------------------------------------------------------------
            % Syntax: 
            %   video_folder = Analysis_Set.video_folder
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   video_folder (STR)
            %   	Return the path to the top folder that contains all the
            %   	videos
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            
            video_folder = strrep([obj.video_folder, '/'],'\','/');
            video_folder = strrep(video_folder,'//','/');
        end
        
        function videotypes = get.videotypes(obj)
            %% Return all the video types available in all recordings
            % -------------------------------------------------------------
            % Syntax: 
            %   videotypes = Analysis_Set.videotypes
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   videotypes (Cell ARRAY of STR)
            %   	Return the name of each detected video type in a
            %   	different cell, without the extension.
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            
            videotypes = unique([obj.experiments.videotypes]);
        end
    end
end

