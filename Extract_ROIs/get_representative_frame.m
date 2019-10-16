function [reference_frame, video_type, video_paths, failed_video_loading] = get_representative_frame(experiment, type)%paths, video_type_idx, video_types_location, failed_video_loading, get_preview)
	if nargin < 6 || isempty(get_preview)
        get_preview = true;
    end

    %% For the current videotype, get one frame from each video and generate a representative frame
    % red for the normalized sum
    % green for the normalized variance
    % blue for the normalized max
    % Saturated regions are NaNd
    
    % If you empty the reference frame, it will force the code to
    % regenerate the file list and reference frame
    
    reference_frame = [];
    
    %% Reload previous frame or create new one
    if ~isempty(experiment.reference_image) && ~isempty(experiment.reference_image{video_type_idx})
        %% If the frame existed, we just get a new one
        reference_frame = experiment.reference_image{video_type_idx};
        video_paths = experiment.filenames{video_type_idx};
        video_type = experiment.video_types{video_type_idx};
        mask = ones(size(reference_frame, 1), size(reference_frame, 2));
    else
        %% If experiment.reference_image is empty, create new frame
        video_type = [];
        video_paths = [];
        for video_idx = video_types_location

            %% We're going to try to get an "average video" for that experiment
            % --> if it is not sharp, you may have moved the camera during
            % the experiment
            current_path = strrep([paths(video_idx).folder,'/', paths(video_idx).name],'\','/'); 
            try
                if get_preview
                    video = VideoReader(current_path);                
                    video.CurrentTime = 1;
                    vidFrame = readFrame(video);
                    reference_frame = cat(3, reference_frame, adapthisteq(rgb2gray(vidFrame)));
                end
                video_type = [video_type, video_idx];
                video_paths = [video_paths, {current_path}];
            catch % empty videos etc...
                winopen(paths(video_idx).folder)
                failed_video_loading = [failed_video_loading, {current_path}];
                fprintf([current_path, ' has an issue\n'])
            end
        end
        if get_preview
            corrimage = correlation_image(double(reference_frame));
            mask = repmat(isnan(corrimage),1,1,3); % No DATA
        end
    end
    
    %% Get some info to help choosing ROIs
    if get_preview
        sumimage = mean(double(reference_frame), 3);
        varimage = var(double(reference_frame), 1, 3);
        maximage = max(double(reference_frame), [], 3);
        reference_frame = cat(3,...
                              (sumimage - min(sumimage(:))) / (max(sumimage(:)) - min(sumimage(:))),...
                              (varimage - min(varimage(:))) / (max(varimage(:)) - min(varimage(:))),...
                              (maximage - min(maximage(:))) / (max(maximage(:)) - min(maximage(:))));
        reference_frame(mask) = 0; % blank saturated regions  
    end
end