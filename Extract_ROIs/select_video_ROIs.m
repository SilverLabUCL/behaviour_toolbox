function [current_experiment, failed_video_loading] = select_video_ROIs(current_experiment, select_ROIs, display_duration, fig_handle, subplot_tags)%, already_there, list_of_videotypes, recordings_paths, display_duration, subplot_tags, fig_handle, select_ROIs)
   
    if nargin < 4 || isempty(fig_handle)
        fig_handle = '';
    end
    if nargin < 5 || isempty(subplot_tags)
        subplot_tags = '';
    end
%     if nargin < 8 || isempty(select_ROIs)
%         select_ROIs = true;
%     end

    global current_pos

    failed_video_loading = {};
    list_of_videotypes = current_experiment.videotypes;

    for video_type_idx = 1:numel(list_of_videotypes)
        %% For each videotype, get a representative frame
        % This check if there is already an existing reference 
        % frame. If yes, reload it. If not, get one frame from each
        % video in the list and create a composite image. 
        % If some files were deleted on the source server, the
        % reference frame was deleted eralier on and will be
        % regenerated

        %% Reset position to center, with 1 ROI
        current_pos = {}; 

        existing_windows = false(1, current_experiment.n_rec);
        existing_motion_indexes = false(1, current_experiment.n_rec);
        for rec = 1:current_experiment.n_rec
            existing_windows(1, rec) = ~isempty(current_experiment.recordings(rec).videos(video_type_idx).ROI_location); % no nested indexing method available as far as i know
            existing_motion_indexes(1, rec) = ~all(cellfun(@isempty, current_experiment.recordings(rec).videos(video_type_idx).motion_indexes)); % no nested indexing method available as far as i know
        end
        %existing_motion_indexes = ~cellfun(@isempty ,arrayfun(@(x) x.videos(video_type_idx).motion_indexes ,current_experiment.recordings, 'UniformOutput', false));
        if all(existing_motion_indexes) && select_ROIs
            first_tp_of_exp = current_experiment.t_start; 
            manual_browsing = false;
            plot_MIs(current_experiment.recordings, subplot_tags, first_tp_of_exp, manual_browsing, list_of_videotypes{video_type_idx});
        end

        %% Print videos infos
        folderpaths = cellfun(@(x) x(video_type_idx).file_path, {current_experiment.recordings.videos}, 'UniformOutput', false);
        if all(~cellfun(@isempty ,folderpaths))
            fprintf([strjoin(folderpaths, '\n'),'\n']);
        end

        %% Plot the representative_frame for the current expe
        if select_ROIs
            current_experiment = display_video_frame(current_experiment, video_type_idx, display_duration, fig_handle);
        end

        %% Clear empty cells if you deleted some ROIs. get id of deleted cells
        to_keep = cellfun(@numel , current_pos) == 5;
        poped = find(cellfun(@numel , current_pos) == 1);
        if ~isempty(poped)
            poped = [current_pos{poped}];
        end
        current_pos = current_pos(to_keep);

        %% If there were some preexisitng values, check if we need an update
        roi_change_detected = false;

        %% Check if ethere was any change            
        for el = 1:numel(current_pos)
            window_location = current_pos{el};

            try
                roi_change_detected = isempty(window_location) || ~all(existing_windows) || numel(current_pos) ~= current_experiment.recordings(1).videos(video_type_idx).n_roi || roi_change_detected;
            catch
                error_box('Unable to store result for this video. This is usually due to a missing video');
                roi_change_detected = true;
            end

            %% If N ROI didn't obviously change, check location
            if ~roi_change_detected
                former_rois = current_experiment.recordings(1).videos(video_type_idx).ROI_location;
                roi_change_detected = ~any(sum(vertcat(former_rois{:}) == window_location,2) == 5);
            else
                break
            end
        end
      
        %% Add new windows and update motion indexes windows location  
        if roi_change_detected
            for rec = 1:current_experiment.n_rec
                n_rois = current_experiment.recordings(rec).videos(video_type_idx).n_roi;
                previous_ids = vertcat(current_experiment.recordings(rec).videos(video_type_idx).ROI_location{:});
                for roi = 1:numel(current_pos) 
                    %% Check if it is a new ROI
                    if isempty(previous_ids) || isempty(find(previous_ids(:,5) == current_pos{roi}(5)))                   
                        n_roi = current_experiment.recordings(rec).videos(video_type_idx).n_roi;
                        current_experiment.recordings(rec).videos(video_type_idx).rois(n_roi + 1).ROI_location = current_pos{roi}; % no nested indexing method available as far as i know
                    else    
                        %% List ROIs to delete
                        to_pop = [];
                        for pop = poped
                            to_pop = [to_pop, find(previous_ids(:,5) == pop)];
                        end

                        if isempty(to_pop)
                            %% Then it's an update (or the same location)
                            current_experiment.recordings(rec).videos(video_type_idx).motion_indexes{roi} = {}; % Clear any MI content
                            current_experiment.recordings(rec).videos(video_type_idx).rois(roi).ROI_location = current_pos{roi}; % update location
                        else
                            %% Then it's a deletion
                            current_experiment.recordings(rec).videos(video_type_idx).rois(to_pop) = [];
                            previous_ids = vertcat(current_experiment.recordings(rec).videos(video_type_idx).ROI_location{:});
                        end
                    end
                end
            end
        end
    end
end