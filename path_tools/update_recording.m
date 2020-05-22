function current_recording = update_recording(current_recording, recordings_videos)
    %% Check if all videos are in place
    need_update = ~isfile(vertcat({current_recording.videos.path})) | isempty(vertcat({current_recording.videos.path}));

    %% (rear) If you added a video, Figure out which one
    if numel(recordings_videos) > numel(need_update)
        %L = {recordings_videos.name}; L = erase(L, '.avi'); % list of new suggested video
        %need_addition = ~ismember(L, current_recording.videotypes); % check which ones are not already there
        error_box('Re-addition of video not fully implemented. ask if needed. As a work around you can remove the recording, update the table and re-add the recording')
    end
    
    for vid = 1:numel(recordings_videos)
        if need_update(vid) % If you added videos in a recording, or if there is no information
            current_recording.videos(vid).path = fix_path([recordings_videos(vid).folder,'/',recordings_videos(vid).name]);
        end
    end
end

