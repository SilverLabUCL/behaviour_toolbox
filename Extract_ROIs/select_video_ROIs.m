function [current_experiment, failed_video_loading] = select_video_ROIs(current_experiment, select_ROIs)%, already_there, list_of_videotypes, recordings_paths, display_duration, subplot_tags, fig_handle, select_ROIs)
   
%     if nargin < 7 || isempty(fig_handle)
%         fig_handle = '';
%     end
%     if nargin < 8 || isempty(select_ROIs)
%         select_ROIs = true;
%     end

    global current_pos
    failed_video_loading = {};
    
    
    list_of_videotypes = current_experiment.videotypes;
    for video_type_idx = 1:numel(list_of_videotypes)
        type = list_of_videotypes{video_type_idx};
        [reference_frame, video_type, video_paths, failed_video_loading] = get_representative_frame(current_experiment, video_type_idx, type, select_ROIs);
%                                                                                                     recordings_paths,...
%                                                                                                     video_type_idx,...
%                                                                                                     valid_indexes,...
%                                                                                                     failed_video_loading,...
%                                                                                                     select_ROIs);

    end




    %% QQ TEMP FIX
    if~select_ROIs
        return
    end
    
    for video_type_idx = 1:numel(unique(list_of_videotypes))'

        %% For each videotype, get a representative frame
        % This check if there is already an existing reference 
        % frame. If yes, reload it. If not, get one frame from each
        % video in the list and create a composite image. 
        % If some files were deleted on the source server, the
        % reference frame was deleted eralier on and will be
        % regenerated
        valid_indexes = find(list_of_videotypes' == video_type_idx);
        
        [reference_frame, video_type, video_paths, failed_video_loading] = get_representative_frame(current_experiment,...
                                                                                                    recordings_paths,...
                                                                                                    video_type_idx,...
                                                                                                    valid_indexes,...
                                                                                                    failed_video_loading,...
                                                                                                    select_ROIs);

        %% If any video was found, get the ROIs to use for motion index
        if ~isempty(video_paths)

            %% Reset position to center, with 1 ROI
            current_pos = {}; 

            if any(~cellfun(@isempty, current_experiment.motion_indexes)) && select_ROIs
                plot_MIs(current_experiment.motion_indexes{video_type_idx}, subplot_tags, video_type_idx > 1);
            end

            %% Print videos infos
            if ~isempty(current_experiment.filenames{video_type_idx})
                folderpath = strsplit(current_experiment.filenames{video_type_idx}{1},'/');
                fpath = dir([strjoin(folderpath(1:end-3), '/'),'/*_*_*_*']);
                vertcat(fpath.name)
                fprintf([strjoin(folderpath(1:end-3), '/'), '/\n']);
                fprintf([folderpath{end}, '\n']);
            end
            
            %% Plot the representative_frame for the current expe
            if select_ROIs
                display_video_frame(reference_frame, current_experiment.ROI_location{video_type_idx}, video_paths{1}, display_duration, fig_handle);
            end
            
            %% Clear empty cells if you deleted some ROIs
            to_keep = ~cellfun(@isempty , current_pos);
            current_pos = current_pos(to_keep);

            %% Save ROI locations, filepaths and reference image
            if already_there
                roi_change_detected = false;
                for el = 1:numel(current_pos)
                    window_location = current_pos{el};
                    
                    try
                        roi_change_detected = isempty(window_location) || isempty(current_experiment.ROI_location{video_type_idx}) || numel(current_pos) ~= numel(current_experiment.ROI_location{video_type_idx}(1,:)) || roi_change_detected;
                    catch
                        error_box('Unable to store result for this video. This is usually due to a missing video');
                        roi_change_detected = true;
                    end
                    if ~roi_change_detected
                        for r = 1:numel(current_experiment.ROI_location{video_type_idx}(1,:)) 
                            rois = current_experiment.ROI_location{video_type_idx}(1,:);
                            roi_change_detected = roi_change_detected || any(rois{r} ~= window_location);
                        end
                    end
                end
            end

            if isempty(current_experiment.reference_image{video_type_idx})
                current_experiment.reference_image{video_type_idx} = reference_frame;
            end

            %% Now push data into the right cell
            if ~already_there
                current_experiment.filenames{video_type_idx}            = video_paths;
                current_experiment.reference_image{video_type_idx}      = reference_frame;            
                current_experiment.ROI_location{video_type_idx}         = repmat(current_pos, numel(video_paths), 1); 
                current_experiment.video_types{video_type_idx}          = video_type; 
            elseif roi_change_detected
                current_experiment.ROI_location{video_type_idx}         = repmat(current_pos, numel(video_paths), 1); 
            end
        end
    end
end