function [reference_frame, video_type, video_paths, failed_video_loading, all_frames] = get_representative_frame(experiment, video_type_idx, type, get_preview)%paths, video_type_idx, video_types_location, failed_video_loading, get_preview)
% 	if nargin < 6 || isempty(get_preview)
%         get_preview = true;
%     end

    %% For the current videotype, get one frame from each video and generate a representative frame
    % red for the normalized sum
    % green for the normalized variance
    % blue for the normalized max
    % Saturated regions are NaNd
    
    % If you empty the reference frame, it will force the code to
    % regenerate the file list and reference frame
    
    reference_frame = [];
    video_type = [];
    video_paths = [];
    failed_video_loading = false;


    %% Reload previous frame or create new one (all empty when never generated. NaN when video not available)
    if ~any(isempty([experiment.global_reference_images{:,video_type_idx}])) && ~all(isnan([experiment.global_reference_images{:,video_type_idx}]))% && ~isempty(experiment.reference_images{video_type_idx})
        %% If the frame existed, we just get a new one
        reference_frame = experiment.reference_image{video_type_idx};
%         video_paths = experiment.filenames{video_type_idx};
%         video_type = experiment.video_types{video_type_idx};
        mask = ones(size(reference_frame, 1), size(reference_frame, 2));
    else
        %% If experiment.reference_image is empty, create new frame

%         video_type = [];
%         video_paths = [];
        for rec = 1:experiment.n_rec

            target = experiment.videotypes{video_type_idx};
            local_video_type_idx = find(contains(experiment.recordings(rec).videotypes, target));
            
            %% We're going to try to get an "average video" for that experiment
            % --> if it is not sharp, you may have moved the camera during
            % the experiment
            if ~isempty(local_video_type_idx)
                current_path = experiment.recordings(rec).videos(local_video_type_idx).path;
                current_path = strrep(current_path,'\','/'); 
                try
                    if get_preview
                        video = VideoReader(current_path);                
                        video.CurrentTime = 1;
                        vidFrame = readFrame(video);
                        reference_frame = cat(3, reference_frame, adapthisteq(rgb2gray(vidFrame)));
                    end
    %                 video_type = [video_type, video_idx];
    %                 video_paths = [video_paths, {current_path}];
                catch % empty videos etc...
                    %winopen(current_path)
                    failed_video_loading = [failed_video_loading, {current_path}];
                    fprintf([current_path, ' has an issue\n'])
                end
            else
                reference_frame = cat(3, reference_frame, zeros(size(reference_frame, 1),size(reference_frame, 2)));
            end
        end

        if get_preview
            corrimage = correlation_image(double(reference_frame));
            mask = repmat(isnan(corrimage),1,1,3); % No DATA
        end
    end
    
    %% Get some info to help choosing ROIs
    all_frames = reference_frame;
    if get_preview
        meanimage = mean(double(reference_frame), 3);        
        varimage = var(double(reference_frame), 1, 3);
        maximage = max(double(reference_frame), [], 3);
        maximage = (maximage-meanimage);
        reference_frame = cat(3,...
                              (meanimage - min(meanimage(:))) / (max(meanimage(:)) - min(meanimage(:))),...
                              (3*varimage - min(varimage(:))) / (max(varimage(:)) - min(varimage(:))),...
                              (3*maximage - min(maximage(:))) / (max(maximage(:)) - min(maximage(:))));
        reference_frame(imerode(mask, strel('disk',3))) = 0; % blank saturated regions  
    end
    
    
end