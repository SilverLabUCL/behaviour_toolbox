%% For a given list of MIs, plot them, one per subplot

function plot_MIs(recordings, t_offset, manual_browsing, videotype_filter, filter_laser)
    if nargin < 2 || isempty(t_offset)
        t_offset = 0;
    end
    if nargin < 3 || isempty(manual_browsing)
        manual_browsing = false;
    end
    if nargin < 4 || isempty(videotype_filter)
        videotype_filter = '';
    end
    if nargin < 5 || isempty(filter_laser)
        filter_laser = false;
    end


    %% Regroup MIs
    %max_MI = max(cellfun(@numel, MIs));
    %keep = max_MI > 1;
    type_list = unique(horzcat(recordings.videotypes));
    all_types = cell(numel(recordings), numel(type_list));
    all_MIs   = cell(numel(recordings), numel(type_list));
    all_labels= cell(numel(recordings), numel(type_list));

    for rec = 1:numel(recordings)
        for vid = 1:numel(type_list)
            match = find(ismember(recordings(rec).videotypes, type_list(vid)));
            if ~isempty(match)
                all_types(rec, vid) = type_list(vid)                          ;
                all_MIs(rec, vid)   = recordings(rec).motion_indexes(match)   ;
                all_labels(rec, vid)= {recordings(rec).videos(vid).roi_labels};
            else
                all_types(rec, vid) = {NaN};
                all_MIs(rec, vid)   = {NaN};
                all_labels(rec, vid)= {NaN};
            end
        end
    end

    to_use = ~cellfun(@(x) all(isnan(x)), all_types);
    if ~isempty(videotype_filter)
        to_use = cellfun(@(x) strcmp(x, videotype_filter), all_types) & to_use;
    end

    labels          = recordings.roi_labels;  % a list of all labels
    original_shape  = size(to_use);
    all_MIs(~to_use)    = {{[]}}; % clear content for ignored MI's
    all_labels(~to_use) = {{[]}}; % clear content for ignored MI's 
    all_MIs         = reshape(all_MIs   , original_shape);
    all_labels      = reshape(all_labels, original_shape);

    for videotype_idx = 1:numel(type_list)
        current_MIs = all_MIs(:,videotype_idx);
        current_labels = all_labels(:,videotype_idx);
        if all(cellfun(@isempty, current_MIs))
            all_rois = [];
        elseif any(cellfun(@isempty, [current_MIs{:}]))
            all_rois = vertcat(current_MIs{:});
            to_fix = cellfun(@isempty, all_rois);
            template = all_rois(~to_fix);
            for missing_MI = 1:size(template, 1)
                all_rois(missing_MI, to_fix(missing_MI, :)) = {NaN(size(template{missing_MI, 1}))};
            end
            all_rois = cell2mat(all_rois);
        else
            all_rois = vertcat(current_MIs{:});
            all_rois = cell2mat(all_rois);
        end

        %% Set image to full screen onm screen 2 (if any)
        screens = get(0,'MonitorPositions');
        f = figure(122+videotype_idx); hold on;
%         if ~keep
%             clf();
%         end
        if size(screens, 1) > 1
            set(f, 'Position', screens(2,:)/1.1);
        end

        %% Create subplot
        %nrois = (size(all_rois,2)/2);
        axes = [];
        n_rois = numel(labels);
        for roi = 0:n_rois-1
            rois = cell2mat(cellfun(@(x) find(strcmp(x, labels{roi+1})) , current_labels, 'UniformOutput', false));
            real_roi = unique(rois)-1;
            if ~isempty(real_roi)
                %% Prepare subplot for the ROI
                ax = subplot(n_rois,1,roi+1);cla();hold on
                title(labels{roi+1});hold on
                
                %% Select the right column(s)
                v = all_rois(:,unique(rois)*2 - 1);
                
                %% Averages ROIs with the same name
                if size(v, 2) > 1
                    v = nanmean(v, 2);
                end
                
                %% Normalize v, get timescale
                v = (v - min(v)) / (max(v) - min(v));
                novid = diff(all_rois(:,2));
                [idx] = find(novid > (median(novid) * 2));
                taxis = (all_rois(:,2)- t_offset)/1000;
                if filter_laser
                    v = movmin(v, 3);
                end
                plot(taxis, v); hold on;
                for p = 1:numel(idx)
                    x = [taxis(idx(p)), taxis(idx(p)+1), taxis(idx(p)+1), taxis(idx(p))];
                    y = [max(v), max(v), min(v), min(v)];
                    patch(x, y, [0.8,0.8,0.8], 'EdgeColor', 'none'); hold on;
                end
                axes = [axes, ax]; hold on;
            end
        end
        
        if ~isempty(axes) % empty when no ROIs were selected in the Video
            linkaxes(axes, 'x'); hold on;
        end

        if manual_browsing
            uiwait(f);
        end
    end
end