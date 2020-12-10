%% Analysis_Set Class
% 	This is the top level class for your analysis. 
%
%   Type doc Analysis_Set.function_name or Analysis_Set Class.function_name 
%   to get more details about the methods inputs and outputs.
% -------------------------------------------------------------------------
% Syntax: 
%   this = Analysis_Set(video_folder);
% -------------------------------------------------------------------------
% Class Generation Inputs:
%   video_folder(STR) - Optional - default is ''
%                               Path to your top video folder, that contains
%                               all the videos. If provided, the folder
%                               will be set to Analysis_Set.video_folder
%
% -------------------------------------------------------------------------
% Outputs: 
%   this (Analysis_Set object)    
% -------------------------------------------------------------------------
% Class Methods (ignoring get()/set() methods):
%
% * List/Update video folder content and build experiments 
%   Analysis_Set.update(filter_list)
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
%
% * Check if an experiment is new, and return its location
%   [experiment_idx, expe_already_there] = 
%               Analysis_Set.check_if_new_expe(expe_path)
%
% * Select location of ROIs for all/some recordings
%   analysed_idx = Analysis_Set.select_ROIs(filter_list)
%
% -------------------------------------------------------------------------
% Extra Notes:
% * Analysis_Set and all of its children classes (Experiment, Recording,
%   Video, ROI) are handles. When you assign some of them to a variable.
%   they keep the memory link with the original variable.
% -------------------------------------------------------------------------
% Examples: 
%
% * Initialise a new Analysis_Set with an empty experiment.
%   Analysis_Set();
%
% * Change the default tags that will be displayed for video extraction
%   my_analysis.default_tags = [my_analysis.default_tags, {'New Preset'}];
%
% * Add 2 empty experiments
%   my_analysis.add_experiment(2);
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
% See also: Experiment, Recording, Video, ROI

classdef Analysis_Set < handle
    properties
        experiments     = []            ; % Contain individual experiments
        video_folder    = ''            ; % Top video folder where experiments are located
        n_expe          = 0             ; % Return number of experiments
        auto_estimate_offsets   = true  ; % If true, video offsets are estimated by default when positioning ROIs
        auto_register_ref_image   = false; % If true, the consensus frame is registrerd automatically for better sharpness
        default_tags    = {'Whisker'   ,...
                            'Nose'     ,...
                            'Jaw'      ,...
                            'Breast'   ,...
                            'Wheel'    ,...
                            'Laser'    ,...
                            'Caudal Forelimb',...
                            'Trunk'    ,...
                            'Tail'     ,...
                            'Eye'}     ; % Default ROI names
        folder_exclusion= {' unidentified'} ; % path containing elements in this list are ignored
        videotypes      = {}             ; % List all existing videos types
        current_varname = 'motion_index' ; % The metric currently used
        folder_structure = '/*-*-*/experiment_*'; % defines how experiments containing video folders can be found %% '/HG */exp *'
        expdate         = ''; %in YYMMDD format - prefix of experiment folders
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
            %   	The container for all the analysed data
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
            
            if isempty(ver('images'))
                error_box('Image Processing Toolbox is not installed but required to run the toolbox', 0)
            end
        end
 
        function update(obj, filter_list)
            %% Update all videos. add new folder, remove old ones.
            % -------------------------------------------------------------
            % Syntax: 
            %   Analysis_Set.update(filter_list)
            % -------------------------------------------------------------
            % Inputs:
            %   filter_list(STR or Cell of STR) - Optional - default is '';
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
            %   my_analysis.update();
            %
            % * Update a specific folder only
            %   my_analysis.update({'2018-12-04'});
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            
            if nargin < 2 || isempty(filter_list)
                filter_list = {};
            elseif ischar(filter_list)
                filter_list = {filter_list};
            end
            
            %% Get all experiments in the video folder
            experiment_folders = dir([obj.video_folder, obj.folder_structure]); 
            if isempty(obj.video_folder) || ~isdir(obj.video_folder) || isempty(experiment_folders)
                error('You must set a valid video_folder path in your Experiment Set. If you changed computer or moved your files, adjust Analysis_set.video_folder')
            end
            
            %% Print selected folders. Filter excluded sets.
            for el = numel(experiment_folders):-1:1
                current_expe_path = fix_path([experiment_folders(el).folder,'/',experiment_folders(el).name]);
                if contains(current_expe_path, obj.folder_exclusion) || ~isdir(current_expe_path)
                    experiment_folders(el) = [];
                else
                    fprintf([current_expe_path, '\n'])
                end
            end

            %% Use this function to edit the fname field or check for modified files
            [obj, experiment_folders] = check_or_fix_path_issues(obj, experiment_folders, filter_list);

            %% Go through all experiment folder. Add experiments if missing
            fprintf('Please wait while updating all experiments in the folder...\n')
            for experiment_idx = 1:numel(experiment_folders)
                current_expe_path                   = experiment_folders{experiment_idx};
                experiment_idx                      = obj.add_experiment(current_expe_path); %% add or update experiment

                %% Sort alphabetically and remove empty experiments
                obj.experiments(experiment_idx).cleanup();
            end
            fprintf('Update complete...\n')

            %% final adjustements
            obj.cleanup();
        end 

        function experiment_idx = add_experiment(obj, to_add)
            %% Add a specific experiment
            % -------------------------------------------------------------
            % Syntax: 
            %   experiment_idx = Analysis_Set.add_experiment(to_add)
            % -------------------------------------------------------------
            % Inputs:
            %   to_add(INT or STR PATH or Cell ARRAY of STR PATH)
            %   	- If int, create N empty experiments
            %       - if STR or CELL ARRAY, add the indicated path(s).
            % -------------------------------------------------------------
            % Outputs: 
            %   experiment_idx (1 x N INT)
            %   	Index(es) of the added experiments
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
            %   my_analysis.add_experiment(4);
            %
            % * Add an experiment with a known path
            %   fold = 'D:\topfolder\2018-12-03\experiment_1';
            %   my_analysis.add_experiment(fold);
            %
            % * Add 2 experiments with known paths
            %   folds = {'D:\topfolder\2018-12-03\experiment_1',...
            %            'D:\topfolder\2018-12-03\experiment_2'};
            %   my_analysis.add_experiment(folds);
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
            
            if isnumeric(to_add)  
                %% Add one/several empty experiments
                if isempty(obj.experiments)
                    experiment_idx  = 1:to_add;
                    obj.experiments = repmat(Experiment(obj),1,to_add);
                else
                    experiment_idx  = (numel(obj.experiments) + 1):(numel(obj.experiments)+ to_add);
                    obj.experiments(end + 1:end + to_add) = Experiment(obj);
                end
            elseif ischar(to_add)
                %% Add/Update experiments using path 
                [experiment_idx, expe_already_there]        = obj.check_if_new_expe(to_add);
                if isempty(obj.experiments)
                    obj.experiments                         = Experiment(obj);
                    experiment_idx                          = 1         ;
                elseif ~expe_already_there
                    obj.experiments(experiment_idx)         = Experiment(obj);
                else
                    %% Then it's an update
                end
                obj.experiments(experiment_idx).populate(to_add, obj);
            elseif iscell(to_add)
                experiment_idx = [];
                for el = 1:numel(to_add)
                    experiment_idx(el) = obj.add_experiment(to_add{el});
                end  
            else
                error('must pass INT or STR path or CELL ARRAY of STR PATH')
            end
        end
        
        function idx = identify(obj, filter)    
            idx = find(contains({obj.experiments.path}, filter));
        end

        function obj = pop(obj, to_remove)
            %% Delete experiment at index(es) expe_number
            % -------------------------------------------------------------
            % Syntax: 
            %   Analysis_Set.pop(to_remove)             
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
            %   my_analysis.pop([5, 6]);
            %   
            % * Remove all experiments the '2018-12-04' and an experiment
            %   called 'experiment_12'
            %   my_analysis.pop({'2018-12-04','experiment_2'}); 
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
        
        function cleanup(obj)
            %% Remove experiments with no recordings, 
            %   Function also sort experiments alphabetically
            % -------------------------------------------------------------
            % Syntax: 
            %   Analysis_Set.cleanup()             
            % -------------------------------------------------------------
            % Inputs:
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

            fprintf('Cleaning up experiment list... ')
            to_remove = [];
            for exp = 1:obj.n_expe    
                if isempty(obj.experiments(exp).recordings)
                    to_remove = [to_remove, exp]; 
                end
            end 
            obj.pop(to_remove);
            
            %% Sort alphabetically
            [~, idx] = sort({obj.experiments.path});
            obj.experiments = obj.experiments(idx); 
            
            %% Empty experiments can be detected here 
            %invalid = arrayfun(@(x) isempty(x.path), obj.experiments);
            fprintf('Done\n')
        end

        function update_all_paths(obj, old, new)
            %% Set a new video_folder. If possible, update path in Childrens
            % -------------------------------------------------------------
            % Syntax: 
            %   Analysis_Set.update_all_paths(old, new)
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
            %   my_analysis.update_all_paths('C:/','D:/')
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            %
            % See also: Analysis_Set.update_all_paths
            
            old = old;
            new = fix_path(new);
            
            for exp = 1:obj.n_expe                 
                obj.experiments(exp).path = strrep(fix_path(obj.experiments(exp).path), old, new);
                for rec = 1:obj.experiments(exp).n_rec
                    obj.experiments(exp).recordings(rec).path = strrep(fix_path(obj.experiments(exp).recordings(rec).path),old,new);
                    for vid = 1:obj.experiments(exp).recordings(rec).n_vid
                        obj.experiments(exp).recordings(rec).videos(vid).path = strrep(fix_path(obj.experiments(exp).recordings(rec).videos(vid).path), old, new);
                    end
                end                
            end 
            obj.video_folder = strrep(obj.video_folder, old, new);
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
            % * If you changed hard drive, run update_all_paths()
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
            
            expe_path               = fix_path(expe_path);
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
        
        function [analysed_idx, modified] = select_ROIs(obj, filter_list)
            %% Browse experiment folder and add all possible valid videos
            % -------------------------------------------------------------
            % Syntax: 
            %   analysed_idx = Experiment.select_ROIs(filter_list)  
            % -------------------------------------------------------------
            % Inputs:
            %   filter_list (STR) - Optional - Default is ''
            %   	Filter the experiments that will be analysed
            % -------------------------------------------------------------
            % Outputs: 
            %   analysed_idx
            %       List of experiments that were analyzed
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % * Setup all ROIs
            %   my_analysis.select_ROIs()
            %
            % * Setup ROIs for a specific experiment
            %   my_analysis.select_ROIs('2018-12-05')
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            %
            % See also: Experiment.select_ROIs
            
            if nargin < 2 || isempty(filter_list)
                filter_list = '';
            end

            %% Update required fields
            obj.update(filter_list);
            if ~isempty(filter_list)
                analysed_idx   	= find(contains({obj.experiments.path}, filter_list));
            else
                analysed_idx   	= 1:obj.n_expe;
            end

            %% Now extract ROIs
            modified = {};
            for experiment_idx = analysed_idx
                %% Now that all recordings were added, we can select ROIs
                [~, modified{end+1}] = obj.experiments(experiment_idx).select_ROIs('', obj.default_tags);
            end
        end

        function new_data_available = analyse(obj, filter_list, force, display)
            %% Extract results for all experiments
            % -------------------------------------------------------------
            % Syntax: 
            %   Analysis_Set.analyse(filter_list, force, display)
            % -------------------------------------------------------------
            % Inputs:
            %   filter_list (STR or CELL ARRAY of STR) - Optional - default
            %           is ''
            %   	If non-empty, only video path that match the filter
            %   	will be updated and displayed
            %
            %   force (BOOL) - Optional - default is false
            %   	If true, reanalyse previous results. If false, only analyse
            %   	missing ones
            %
            %   display (BOOL or STR) - Optional - default is false
            %   	- If true or 'auto', results are displayed for each 
            %   	recording (after extraction). If extraction was already
            %   	done, results are also shown.
            %       - If 'pause' results display will pause until the figure
            %   	 is closed
            % -------------------------------------------------------------
            % Outputs:
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % * Analyse all ROIs where an un-analysed ROI is set
            %   my_analysis.analyse()
            %
            % * Analyse all ROIs. Reanalyse old ones.
            %   my_analysis.analyse('',true)
            %
            % * Analyse/Re-analyse all ROIs in a specific experiment
            %   my_analysis.select_ROIs('2018-12-05', true)
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also: Experiment.analyse

            if nargin < 2 || isempty(filter_list)
                filter_list = {''};
            end
            if nargin < 3 || isempty(force)
                force = false;
            end
            if nargin < 4 || isempty(display)
                display = false;
            end
            
            %% Update required fields
            obj.update(filter_list);
            if ~isempty(filter_list)
                analysed_idx   	= find(contains({obj.experiments.path}, filter_list));
            else
                analysed_idx   	= 1:obj.n_expe;
            end

            %% Now that all Videos are ready, extract results if the section is empty
            new_data_available = false;
            for experiment_idx = analysed_idx
                is_new =  obj.experiments(experiment_idx).analyse(force, display);
                new_data_available = new_data_available || is_new;
            end    
        end
        
        function path = save(obj, path)
            my_analysis        = obj;
            if nargin < 2 || isempty(path)
            	path = ['saved_analysis ',strrep(datestr(datetime('now')),':','_')];
                uisave({'my_analysis'},path);
            else
                save(path,'my_analysis','-v7.3');
            end
            
        end

        function set.video_folder(obj, new_video_folder)
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
            %   22-05-2020
            %
            % See also: Analysis_Set.update_all_paths
            
            %             if ~isempty(obj.video_folder) && ~isempty(new_video_folder) && ~contains(struct2array(dbstack(1)), 'update_all_paths')
            %                 obj = update_all_paths(obj, obj.video_folder, new_video_folder);
            %             end
            obj.video_folder = fix_path(new_video_folder);
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

