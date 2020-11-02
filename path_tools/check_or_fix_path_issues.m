function [analysis, experiment_folders] = check_or_fix_path_issues(analysis, experiment_folders, filter_list)
    if nargin < 3 || isempty(filter_list)
        filter_list = {};
    end

    experiment_folders = arrayfun(@(x) fix_path(fullfile(x.folder, x.name)), experiment_folders, 'UniformOutput', false);   

    %% Remove filtered or absent files/folders
    for expe_idx = analysis.n_expe:-1:1     
        experiment = analysis.experiments(expe_idx);
        if ~isempty(experiment.recordings) && ~isempty(experiment.path) && isfolder(experiment.path)
            for recording_idx = experiment.n_rec:-1:1
                if isfolder(experiment.recordings(recording_idx).path)
                    for video_type_idx = experiment.recordings(recording_idx).n_vid:-1:1                
                        video = experiment.recordings(recording_idx).videos(video_type_idx);

                        %% Check if file has not been deleted
                        if ~isfile(video.path)
                            %% Remove the whole video object
                            fprintf(['Could no find ', experiment.recordings(recording_idx).videos(video_type_idx).path,'\n']);
                            if experiment.recordings(recording_idx).n_vid > 0
                                experiment.recordings(recording_idx).videos(video_type_idx) = [];  
                            else
                                experiment.recordings(recording_idx) = experiment.recordings.pop(recording_idx);  
                            end
                        end
                    end
                else
                    %% Remove the whole recording
                    experiment.pop(recording_idx);
                end
            end
            analysis.experiments(expe_idx) = experiment;  
        elseif ~isempty(filter_list) || (~isempty(experiment.path) && ~isfolder(experiment.path))
            %% Remove the whole experiment
            analysis = analysis.pop(expe_idx);
        end  
    end
    
    %% Filter video folders accordingly
	for el = numel(experiment_folders):-1:1
        if ~isempty(filter_list) && ~any(cellfun(@(x) contains(experiment_folders{el}, fix_path(x)), filter_list))
            experiment_folders(el) = [];
        end
    end    
end