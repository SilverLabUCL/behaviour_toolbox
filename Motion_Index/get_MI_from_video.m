%% Load Video and measure Motion index from selected ROIs
% -------------------------------------------------------------------------
% Model : 
%   [motion_indexes, video] = get_MI_from_video(file_path, ROI, 
%                               rendering, normalize, dump_data,
%                               video_offsets)
%
% -------------------------------------------------------------------------
% Inputs : 
%   file_path_or_data(STR path or analysis_params object or X * Y * T matrix)
%                         - an absolute or relative path pointing to a
%                         multipage image stack or a sequence of eye cam
%                         images. 
%                         - A video as a X * Y * T matrix. dump_data is
%                         automatically set to false in that case
%
%   ROI(1 * 4 INT or Cell array of {1 * 4} INT) - Optional - Default ''
%                       If specified, the video is cropped and this ROI is
%                       used to calculate the M.
%                       Format is similar to the outut of imrect, which is
%                       [Xstart, Y start, Xsize, Ysize]. You can pass a
%                       cell array of ROIs to get multuple measurment at
%                       once.
%                       If empty, the whole image is used (in case you
%                       cropped the video beforehand)
%
%   rendering(BOOL) - Optional - Default true
%                       If true, final result is shown
%
%   normalize(BOOL) - Optional - Default true
%                       If true, motion index is normalized
%
%   dump_data(BOOL) - Optional - Default false
%                       If true, data is stored temporrily on HD to save
%                       memory, but this slow down loading considerably
%
%   video_offsets([INT, INT]) - Optional - Default [0, 0]
%                       Apply an extra x-y offset to the ROI.
%
% -------------------------------------------------------------------------
% Outputs :
%   extracted_results ({1 * N} CELL ARRAY of [Txa] ARRAY)
%                       For each of N ROI input, we get one motion index
%                       measurment. For each cell :
%                       First column is motion index (between 0 and 1)..
%
%   video (X * Y * T)
%                       The video used for motion index. If you passed the
%                       video as an input, this is the same as
%                       file_path_or_data. If you passed a file path, this
%                       is the corresponding video (UINT8)
% -------------------------------------------------------------------------
% Extra Notes:
% Determine a motion index based on Jelitai et al., Nature communications,
%
% Adapted from Harsha's code. For a more complete version including loading
% from substack and gif, see
% https://github.com/SilverLabUCL/Harsha-old-code/tree/master/Behaviour_analysis
%
% If a ROI is set out of the video frame (because of it's initial
% coordinate, or because the offset put it there), MI values will be set to
% NaN
% -------------------------------------------------------------------------
% Author(s):
%   Harsha Gurnani, Frederic Lanore, Antoine Valera
%    
% -------------------------------------------------------------------------
% Revision Date:
%   10-05-2019
%
% See also load_stack
%

function [motion_indexes, video] = get_MI_from_video(file_path_or_data, ROI, rendering, normalize, dump_data, video_offsets)
    
    %% Open stack
    if isnumeric(file_path_or_data)
        %% If you pass data directly (must be in a X * Y * T format)
        dump_data = false;         
    elseif ~isnumeric(file_path_or_data) && exist(file_path_or_data, 'file')
        %% If you pass a file path and exist, load later
    else
        error('source not identified. Pass a .avi/.tif path, or a [X * Y * T] Matrix \n') 
    end
    if nargin < 2 || isempty(ROI)
        ROI       = [];
    end
    if nargin < 5 || isempty(rendering)
        rendering = false;
    end
    if nargin < 6 || isempty(normalize)
        normalize = true;
    end
    if nargin < 7 || isempty(dump_data)
        dump_data = false;
    end
    if nargin < 8 || isempty(video_offsets)
        video_offsets = [0, 0];
    end
    
    %% Load data if required
    if ~isnumeric(file_path_or_data) && exist(file_path_or_data, 'file')
        %% If you pass a file path 
        fprintf(['please wait... loading videofile ',file_path_or_data,'\n'])
        file_path_or_data = mmread_light(file_path_or_data, dump_data);
        fprintf('video loaded \n')
    end
        
    %% Preparation for ROI collection
    if ~isempty(ROI)
        if ~iscell(ROI)
            ROI = {ROI};
        end
        motion_indexes      = cell(1, numel(ROI));
        interbatch_holder   = cell(1, numel(ROI));
    else
        motion_indexes      = cell(1, 1);
        interbatch_holder   = cell(1, 1);
    end
    
    %% Set some useful variables
    if ~isempty(file_path_or_data)
        if ~dump_data
            %% When video data is available at once (fastest)
            nFrames             = size(file_path_or_data, 3);
            file_path_or_data   = {file_path_or_data};
            n_src = 1; % When not dumping data, batch size is 1;
        else
            %% When video data is available by batch (memory saving)
            [~, n_src]          = size(file_path_or_data,'video_full');
            nFrames             = [];
        end
    else
        n_src = 0;nFrames = 0;
    end
    
    %% Now collect data, batch by batch
    time_offset = 0;    
    for batch_idx = 1:n_src  
        %% Setup current batch
        if ~dump_data
            %% Whole video at once
            video = file_path_or_data{batch_idx};
            clear file_path_or_data;
        else
            %% Current batch
            video       = file_path_or_data.video_full(1, batch_idx);
            video       = video{1};
            nFrames     = size(video, 3);
            timestamp   = ((1:nFrames) + time_offset)';
            time_offset = max(timestamp);
        end
        
        %% Extract MI ROIs to measure, if any
        if nargin >= 1 && ~isempty(ROI)
            if iscell(ROI) % If you passed multiple ROIs as a cell array
                temp = {};
                for el = 1:numel(ROI)
                    roi                 = round(ROI{el}(1:4) + [video_offsets, 0, 0]);
                    max_allowed_start   = [size(video, 2), size(video, 1)];
                    
                    %% Make sure ROI is not completely out of frame
                    if roi(1) > max_allowed_start(1) || roi(2) > max_allowed_start(2)
                        roi = [];
                    elseif (roi(1)+roi(3)) < 0 || (roi(2)+roi(4)) < 0
                        roi = [];
                    end
                    
                    %% If partially out of frame, clip ROI size
                    if ~isempty(roi)
                        max_allowed_size = [0, 0, max_allowed_start - roi(1:2)];
                        for ax = 3:4
                            if (roi(ax) - max_allowed_size(ax)) > 0 % clip axis if too big
                                roi(ax) = max_allowed_size(ax); %stop at end of frame
                            elseif roi(ax-2) <= 0
                                roi(ax)   = roi(ax) - roi(ax-2); % reduce size to start at 1
                                roi(ax-2) = 1;                   % start at 1
                            end
                        end
                        temp{el}    = video(roi(2):roi(2)+roi(4), roi(1):roi(1)+roi(3), :);
                        %figure(el);cla();imagesc(max(temp{el},[],3));axis image
                    else
                        temp{el} = [];
                    end
                end
                video   = temp;
                clear temp
            else % If you passed a single ROI as a 1 * 4 DOUBLE
                roi             = round(ROI(1:4) + [video_offsets, 0, 0]);
                video           = {video(roi(2):roi(2)+roi(4), roi(1):roi(1)+roi(3), :)};
                
            end
        else % If you didn't pass any ROI, then the whole video is your ROI
            video = {video};
        end

        %% Now get MI for each ROI of the current batch
        for MI_idx = 1:numel(video)
            local_data = video{MI_idx};
            
            %% Preallocate output
            MI = nan(nFrames, 1);
            
            if ~isempty(local_data) % normal case

                %% Compute motion index for first point (for batch_idx > 1)
                if nFrames > 1 && dump_data && batch_idx > 1 
                    X  = interbatch_holder{MI_idx};
                    X1 = local_data(:,:,1);
                    FrameDiff = squeeze(X1(:,:,1)-X(:,:,1));
                    MI(1) = (sum(sum(FrameDiff.*FrameDiff)));
                end
                %% Compute motion index for the rest
                for i = 2:nFrames
                    X  = local_data(:,:,i-1);
                    X1 = local_data(:,:,i);
                    FrameDiff = squeeze(X1(:,:,1)-X(:,:,1));
                    MI(i) = (sum(sum(FrameDiff.*FrameDiff)));            
                    % FrameDiff = diff(local_data(:,:,i-1:i),1,3).^2;
                    % MI(i) = sum(FrameDiff(:));
                end
                interbatch_holder{MI_idx} = local_data(:,:,end);


                %% Normalize
                if normalize
                    m = prctile(MI,5);
                    M = max(MI);
                    MI = (MI-m) ./ (M-m); 
                end
            end

            %% Stitch to any previous batch. If ROI was invalid, we'll have NaNs
            motion_indexes{MI_idx} = cat(1, motion_indexes{MI_idx}, MI);
        end
    end
    
    %% Render MI's if required
    if rendering 
        figure();hold on
        for el = 1:numel(motion_indexes)
            plot(motion_indexes{el});hold on;
        end
        %plot(mean(cell2mat(cellfun(@(x) x, motion_indexes, 'UniformOutput', false)), 2), 'k')
    end
end