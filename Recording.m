%% Recording Class
% 	This the class container for all the Video of an recording
%
%   Type doc Experiment.function_name or Experiment Class.function_name 
%   to get more details about the methods inputs and outputs.
% -------------------------------------------------------------------------
% Model: 
%   this = Recording();
% -------------------------------------------------------------------------
% Class Generation Inputs: 
% -------------------------------------------------------------------------
% Outputs: 
%   this (Recording object)
% -------------------------------------------------------------------------
% Methods Index (ignoring get()/set() methods):
%
% * Update video list if you chenged in in the recording
%   Recording.update()
%
% * Remove a specific video / set of videos
%   Recording.pop(vid_number)
% -------------------------------------------------------------------------
% Extra Notes:
%   For now, Recording is NOT a handle, which means you have to reassign
%   the ouput of the object to itself
% -------------------------------------------------------------------------
% Examples - How To
%
% * Refresh video list if you deleted a recording
%   s = Analysis_Set();
%   s.experiments(1) = s.experiments(1).populate(experiment_path);
%   s.experiments(1).recordings(1) = s.experiments(1).recordings(1).update
%
% * Remove one video in a specific recording
%   s.experiments(1).recordings(2) = s.experiments(1).recordings(2).pop(1)
% -------------------------------------------------------------------------
% Author(s):
%   Antoine Valera
% -------------------------------------------------------------------------
% Revision Date:
% 21-04-2020
%
% See also Experiment, Video


classdef Recording
   
    properties
        videos              ; % List of Video objects in this recording
        n_vid = 0           ; % Number of videos in the recording
        path                ; % Path of the recording
        videotypes          ; % List the types of videos in this recording
        roi_labels          ; % List of the ROI labels per Video
        reference_images 	; % Reference image per Video
        name                ; % User-defined recording name
        duration            ; % recording duration
        t_start             ; % recording t start
        t_stop              ; % recording t stop
        trial_number        ; % number of trials in the recording
        motion_indexes      ; % MI per video per ROI
        comment             ; % User comment
        default_video_types = {'EyeCam'           ,...
                               'BodyCam'          ,...
                               'WhiskerCam'}      ; % Default camera names
    end
    
    methods
        function obj = Recording(n_video, recording_path)
            if nargin < 1
                n_video         = 0; % Empty recording
            end
            if nargin < 2
                recording_path  = '';   % Empty recording
            end
            obj.videos          = repmat(Video, 1, n_video);
            obj.path            = recording_path;
        end

        
        function obj = update(obj)
            obj = update_recording(obj, dir([obj.path, '/**/*.avi']));
        end
        
        function obj = pop(obj, video_type_idx)
            %% Remove a specific video objct based on the video index
            obj.videos(video_type_idx) = [];
        end
        
           
        function plot_MIs(obj, fig_number, zero_t, manual_browsing, videotype_filter, filter)
            if nargin < 2 || isempty(fig_number)
                fig_number = '';
            end
            if nargin < 3 || isempty(zero_t)
                zero_t = true;
            end
            if nargin < 4 || isempty(manual_browsing)
                manual_browsing = false;
            end
            if nargin < 5 || isempty(videotype_filter)
                videotype_filter = unique([obj.videotypes]);
            end
            if nargin < 6 || isempty(filter)
                filter = false;
            end

            %% Regroup MIs in a matrix and fill missing cells
            type_list = unique(horzcat(obj.videotypes));
            all_types = cell(numel(obj), numel(type_list));
            all_MIs   = cell(numel(obj), numel(type_list));
            all_labels= cell(numel(obj), numel(type_list));
            for rec = 1:numel(obj)
                for vid = 1:numel(type_list)
                    match = find(ismember(obj(rec).videotypes, type_list(vid)));
                    if ~isempty(match)
                        all_types(rec, vid) = type_list(vid)                          ;
                        all_MIs(rec, vid)   = obj(rec).motion_indexes(match)   ;
                        all_labels(rec, vid)= {obj(rec).videos(match).roi_labels};
                    else
                        all_types(rec, vid) = {NaN};
                        all_MIs(rec, vid)   = {cell(1,0)};
                        all_labels(rec, vid)= {cell(1,0)};
                    end
                end
            end
            all_MIs(cellfun(@(x) isempty(x), all_MIs)) = {[]};

            %% Filter video types by name if required, and flag NaN type (missing videos)
            to_use              = cellfun(@(x) contains(x, videotype_filter), all_types) & ~cellfun(@(x) all(isnan(x)), all_types);
            all_MIs(~to_use)    = {[]}; % clear content for ignored MI's
            all_labels(~to_use) = {[]}; % clear content for ignored MI's 
            all_MIs             = reshape(all_MIs   , size(to_use));
            all_labels          = reshape(all_labels, size(to_use));
            
            %% Remove t 0
            if islogical(zero_t) && zero_t
                t_offset = min([obj.t_start]); % t start is expressed in posixtime, in seconds + decimals for ms
            else
                t_offset = double(zero_t); % if false or any other value, set it as offset
            end

            %% Now generate plot
            ROI_names           = obj.roi_labels;  % a list of all labels
            for videotype_idx = 1:numel(type_list)
                if contains(type_list(videotype_idx), videotype_filter) % ignore filters videos
                    current_MIs     = all_MIs(:,videotype_idx);
                    current_labels  = all_labels(:,videotype_idx);
                    if all(cellfun(@isempty, current_MIs)) %% If all MI are missing, we set all_rois to [];
                        all_rois    = [];
                    elseif any(cellfun(@isempty, [current_MIs{:}])) %% If some MI are missing, we set a NaN array of the same size instead
                        all_rois    = vertcat(current_MIs{:});
                        to_fix      = cellfun(@isempty, all_rois);
                        if any(to_fix(:))
                            [~, ref] = max(~to_fix, [], 2);
                            for rec = 1:size(all_rois, 1)
                                tp  = size(all_rois{rec, ref(rec)},1);
                                all_rois(rec, to_fix(rec,:)) = {NaN(tp, 2)};
                            end
                        end
                        all_rois = cell2mat(all_rois);
                    else %% Optimal case
                        all_rois = vertcat(current_MIs{:});
                        all_rois = cell2mat(all_rois);
                    end

                    %% Set image to full screen onm screen 2 (if any)
                    screens = get(0,'MonitorPositions');
                    f = figure(fig_number);clf(); hold on;                    
                    set(f,'Color','w');hold on;                    
                    if size(screens, 1) > 1
                        set(f, 'Position', screens(2,:)/1.1);
                    end

                    %% Create subplot
                    axes    = [];
                    n_rois  = numel(ROI_names);                    
                    sz = 0.9/(numel(unique([current_labels{:}])));
                    roi_count = 0;
                    for roi = 0:n_rois-1
                        rois = cell2mat(cellfun(@(x) find(strcmp(x, ROI_names{roi+1})) , current_labels, 'UniformOutput', false));
                        real_roi = unique(rois)-1;
                        if ~isempty(real_roi)
                            roi_count = roi_count + 1;
                            
                            %% Prepare subplot for the ROI
                            ax = subplot('Position',[0.1, 0.95 - sz*roi_count, 0.85, sz - 0.01]);
                            if roi_count == 1; title([type_list{videotype_idx},' ; ', strrep(fileparts(obj(1).path),'_','\_')]);hold on; end
                            ax.XAxis.Visible = 'off';
                            ylabel(ROI_names{roi+1});hold on

                            %% Select the right column(s)
                            mi_data = all_rois(:,unique(rois)*2 - 1);

                            %% Averages ROIs with the same name
                            if size(mi_data, 2) > 1
                                mi_data = nanmean(mi_data, 2);
                            end

                            %% Normalize v, get timescale
                            mi_data = (mi_data - min(mi_data)) / (max(mi_data) - min(mi_data));
                            novid = diff(all_rois(:,2));
                            [idx] = find(novid > (median(novid) * 2));
                            taxis = (all_rois(:,2)- t_offset);
                            if filter
                                mi_data = movmin(mi_data, 3);
                            end
                            plot(taxis, mi_data); hold on;
                            for p = 1:numel(idx)
                                x = [taxis(idx(p)), taxis(idx(p)+1), taxis(idx(p)+1), taxis(idx(p))];
                                y = [max(mi_data), max(mi_data), min(mi_data), min(mi_data)];
                                patch(x, y, [0.8,0.8,0.8], 'EdgeColor', 'none'); hold on;
                            end
                            axes = [axes, ax]; hold on;
                        end
                    end

                    if ~isempty(axes) % empty when no ROIs were selected in the Video
                        ax.XAxis.Visible = 'on';
                        linkaxes(axes, 'x'); hold on;
                    end

                    if manual_browsing
                        uiwait(f);
                    end
                end
            end
        end

        function n_vid = get.n_vid(obj)
            %% Return the number of video available
            n_vid = numel(obj.videos);
        end
        
        function videotypes = get.videotypes(obj)
            %% List all video_types available in the Children
            %videotypes = {obj.videos.path};
            videotypes = {obj.videos.video_types};
        end 

        function reference_images = get.reference_images(obj)
            %% Get reference image per Video
            reference_images = {obj.videos.reference_image};
        end 

        function motion_indexes = get.motion_indexes(obj)
            %% Get 
            motion_indexes = {};
            for vid = 1:obj.n_vid
                motion_indexes = [motion_indexes, {obj.videos(vid).motion_indexes}];
            end
        end

        function roi_labels = get.roi_labels(obj)
            %% Get 
            roi_labels = {};
            for vid = 1:obj.n_vid
                roi_labels = [roi_labels, {obj.videos(vid).roi_labels}];
            end
            roi_labels = [roi_labels{:}];
            roi_labels = unique(roi_labels(cellfun('isclass', roi_labels, 'char')));         
        end 
        
        function t_start = get.t_start(obj)
            t_start = [];
            for vid = 1:obj.n_vid
                t = posixtime(obj.videos(vid).absolute_times(1)) + rem(second(obj.videos(vid).absolute_times(1)),1); % similar to MI time column
                t_start = [t_start, t_start, t];
            end
            t_start = nanmin(t_start);
        end
    end
end

