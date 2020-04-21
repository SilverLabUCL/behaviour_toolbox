function [recording_idx, recording_already_there] = check_if_new_rec(current_experiment, current_recording_path)
    %% Check if the video recording is already present.
    % If yes, we carry on, if no, we add a new recording object  

    recording_already_there = false;

    %% If we find the recording somewhere, we update the index
    for el = 1:current_experiment.n_rec
        if any([current_experiment.recordings(:).n_vid])
            if ~isempty(current_experiment.recordings(el).path) && strcmp(current_experiment.recordings(el).path, current_recording_path)
                %% Update recording_idx
                recording_idx             = el;
                recording_already_there   = true;  
                break
            end
        end
    end
    
    if ~recording_already_there
        recording_idx = current_experiment.n_rec + 1;
        % current_experiment.recordings(recording_idx) = Recording(n_videos_in_recording, current_recording_path);
    end
end