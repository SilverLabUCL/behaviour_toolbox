%% For a given list of MIs, plot them, one per subplot

function plot_MIs(recordings, t_offset, manual_browsing, videotype_filter)
    if nargin < 2 || isempty(t_offset)
        t_offset = 0;
    end
    if nargin < 3 || isempty(manual_browsing)
        manual_browsing = false;
    end
    if nargin < 4 || isempty(videotype_filter)
        videotype_filter = '';
    end



    %% Regroup MIs
    %max_MI = max(cellfun(@numel, MIs));
    %keep = max_MI > 1;
    types = vertcat(recordings.videotypes);
    to_use = cellfun(@(x) contains(x, videotype_filter), types);
    if isempty(videotype_filter)
        %% Get tags
        types = recordings.videotypes;
        types = cellfun(@(x) strsplit(x,'/'), types, 'UniformOutput', false);
        types = cellfun(@(x) strrep(x{end},'.avi',''), types, 'UniformOutput', false);
    else
        types = {videotype_filter};
    end
%     tags = {};
%     for rec = 1:numel(recordings)
%         recording = recordings(rec);
%         for video = recordings.n_vid
%             video = recording.videos(video);
%             
%         end
%     end
%     
    all_MIs = vertcat(recordings.motion_indexes);
    labels = recordings.roi_labels;  % a list of all labels
    all_labels = {};
    for rec = 1:numel(recordings)
        for vid = 1:recordings(rec).n_vid
            all_labels = [all_labels, {recordings(rec).videos(vid).roi_labels}];
        end
    end
    original_shape = size(to_use);
    to_use = to_use(:);
    all_MIs = all_MIs(to_use);
    all_labels = all_labels(to_use);
    if all(to_use(:)) % not sure why we loose the shape when they are all 1's
        all_MIs = reshape(all_MIs, original_shape);
        all_labels = reshape(all_labels, fliplr(original_shape))';
    end
    keep = size(all_MIs, 2) > 1;
    
    for videotype_idx = 1:numel(types)
        current_MIs = all_MIs(:,videotype_idx);
        current_labels = all_labels(:,videotype_idx);
        if all(cellfun(@isempty, [current_MIs{:}]))
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
        if ~keep
            clf();
        end
        if size(screens, 1) > 1
            set(f, 'Position', screens(2,:));
        end

        %% Create subplot
        %nrois = (size(all_rois,2)/2);
        axes = [];
        n_rois = numel(labels);
        for roi = 0:n_rois-1
            rois = cell2mat(cellfun(@(x) find(strcmp(x, labels{roi+1})) , current_labels, 'UniformOutput', false));
            roi = unique(rois)-1;
            if numel(roi) > 1
                error_box('to fix, there is an issue with ROI indexing')
            elseif ~isempty(roi)
                ax = subplot(n_rois,1,roi+1);cla();hold on
                title(labels{roi+1});hold on
                v = all_rois(:,1 + (roi*2));
                v = (v - min(v)) / (max(v) - min(v));
                novid = diff(all_rois(:,2));
                [idx] = find(novid > (median(novid) * 2));
                taxis = (all_rois(:,2)- t_offset)/1000;
                plot(taxis, v); hold on;
                for p = 1:numel(idx)
                    x = [taxis(idx(p)), taxis(idx(p)+1), taxis(idx(p)+1), taxis(idx(p))];
                    y = [max(v), max(v), min(v), min(v)];
                    patch(x, y, [0.8,0.8,0.8], 'EdgeColor', 'none'); hold on;
                end
                axes = [axes, ax]; hold on;
            end
        end
        linkaxes(axes, 'x'); hold on;

        if manual_browsing
            uiwait(f);
        end
    end
end