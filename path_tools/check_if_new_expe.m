function [experiment_idx, expe_already_there] = check_if_new_expe(analysis, current_expe_path)
    %% Check if this experiment has already be listed somewhere.
    % If yes we adjust the index to update the video. 
    % If not, we create a new experiment at current index.
    
    expe_already_there      = false;
    
    %% If we find the experiment somewhere, we update the index
    for el = 1:analysis.n_expe
        if ~isempty(analysis.experiments(el).path) && strcmp(analysis.experiments(el).path, current_expe_path)
            %% Adjust exp_idx
            experiment_idx       = el;
            expe_already_there   = true;  
            break
        end
    end

    %% If it is the first time we see this experiment, we create the Experiment object
    if ~expe_already_there
        %% Add new experiment
        experiment_idx = analysis.n_expe + 1;
        analysis.experiments(experiment_idx) = Experiment('', current_expe_path);
    end
end