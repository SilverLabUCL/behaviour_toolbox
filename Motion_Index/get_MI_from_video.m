%% Modified version of Fred and Harsha's motion index code for batch processing
% This version can load the avi and crop ROIs on the fly
% -------------------------------------------------------------------------
% Model : 
%   MI = get_MI_from_video(file_path, timestamp, rendering, ROI, normalize)
%
% -------------------------------------------------------------------------
% Inputs : 
%   file_path_or_data(STR path or analysis_params object or X * Y * T matrix)
%                         - an absolute or relative path pointing to a
%                         multipage image stack or a sequence of eye cam
%                         images. 
%                         - A video as a X * Y * T matrix.
%
%   timestamp(1 * T ARRAY) - Optional - Default 1:Npoints of loaded file
%
%   rendering(BOOL) - Optional - Default true
%                       If true, final result is shown
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
% -------------------------------------------------------------------------
% Outputs :
%   motion_indexes ({1 * N} CELL ARRAY of [2 * T] ARRAY)
%                       For each ROI input, we get one motion index
%                       measurment. For each cell :
%                       First column is motion index (between 0 and 1).
%                       Second column are timestamps copied from given 
%                       Timestamp vector.
% -------------------------------------------------------------------------
% Extra Notes:
% Determine a motion index based on Jelitai et al., Nature communications,
%
% Adapted from Harsha's code. For a more complete version including loading
% from substack and gif, see
% https://github.com/SilverLabUCL/Harsha-old-code/tree/master/Behaviour_analysis
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

function motion_indexes = get_MI_from_video(file_path_or_data, timestamp, rendering, ROI, normalize)
    
    %% Open stack
    if isnumeric(file_path_or_data)
        data = file_path_or_data;
    elseif ~isnumeric(file_path_or_data) && exist(file_path_or_data, 'file')
        data = single(squeeze(load_stack(file_path_or_data)));
    else
       error('source not identified. Pass a .avi/.tif path, or a [X * Y * T] Matrix \n') 
    end
    nFrames = size(data, 3);

    if nargin < 2 || isempty(timestamp)
        timestamp = (1:nFrames)';
    end
    if nargin < 3 || isempty(rendering)
        rendering = true;
    end
    if nargin >= 4 && ~isempty(ROI)
        if iscell(ROI) % If you passed multiple ROIs as a cell array
            temp = {};
            for el = 1:numel(ROI)
                roi = round(ROI{el});
                temp{el} = data(roi(2):roi(2)+roi(4), roi(1):roi(1)+roi(3), :);
            end
            data = temp; clear temp
        else % If you passed a single ROI as a 1 * 4 DOUBLE
            data = {data(ROI(2):ROI(2)+ROI(4), ROI(1):ROI(1)+ROI(3), :)};
        end
    else % If you didn't pass any ROI, then the whole video is your ROI
        data = {data};
    end
    if nargin < 5 || isempty(normalize)
        normalize = true;
    end
    
    motion_indexes = {};
    for video = 1:numel(data)
        local_data = data{video};
        
        %% Preallocate output
        MI = nan(nFrames, 2);  

        %% Compute motion index
        for i = 2:nFrames
            X  = local_data(:,:,i-1);
            X1 = local_data(:,:,i);
            FrameDiff = squeeze(X1(:,:,1)-X(:,:,1));
            MI(i,1) = (sum(sum(FrameDiff.*FrameDiff)));%^2;
        end

        %% Normalize
        if normalize
            m = prctile(MI(:,1),5);
            M = max(MI(:,1));
            MI(:,1) = (MI(:,1)-m) ./ (M-m); 
        end
        
        MI(:,2) = timestamp(1:nFrames,end);
        MI = MI(2:end,:);
        
        motion_indexes{video} = MI;
    end
    
    if rendering 
        figure();hold on
        for el = 1:numel(motion_indexes)
            plot(motion_indexes{el}(:,2),motion_indexes{el}(:,1));hold on;
        end
        %plot(mean(cell2mat(cellfun(@(x) x(:,1), motion_indexes, 'UniformOutput', false)), 2), 'k')
    end
end