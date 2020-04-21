function current_experiment = check_if_new_video(current_experiment, recording_idx, current_recording_path, n_videos_in_recording, recordings_videos)
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
    
    %% Check if all videos are in place
    update_existing = false;
    if recording_already_there
        existing = isfile(vertcat({current_experiment.recordings(recording_idx).videos.path})); % Find if a listed file is missing
        update_existing = ~all(existing) || numel(existing) ~= n_videos_in_recording;
    end


    %% If it is the first time we see this recording, we create the Recording object
    % If there a new video, we need to add it
    if ~recording_already_there || update_existing
        %% Add new recording or update exisitng one (when a new video is found)
        if ~update_existing
            recording_idx = current_experiment.n_rec + 1;
            current_experiment.recordings(recording_idx) = Recording(n_videos_in_recording, current_recording_path);
        end     
        
        %% Add any new video (or all new videos)
        for video = 1:n_videos_in_recording
            if ~ismember(vertcat({current_experiment.recordings(recording_idx).videos.path}), strrep([recordings_videos(video).folder,'/',recordings_videos(video).name],'\','/'))
                current_experiment.recordings(recording_idx).videos(video).path  = strrep([recordings_videos(video).folder,'/',recordings_videos(video).name],'\','/'); 
            end
        end
    end
end