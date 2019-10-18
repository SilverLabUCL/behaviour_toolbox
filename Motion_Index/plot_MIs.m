%% For a given list of MIs, plot them, one per subplot

function plot_MIs(recordings, tags, t_offset, manual_browsing, videotype_filter)
    if nargin < 3 || isempty(t_offset)
        t_offset = 0;
    end
    if nargin < 4 || isempty(manual_browsing)
        manual_browsing = false;
    end
    if nargin < 5 || isempty(videotype_filter)
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
    all_MIs = all_MIs(to_use);
    if all(to_use(:)) % not sure why we loose the shape when they are all 1's
        all_MIs = reshape(all_MIs, size(to_use));
    end
    if nargin < 2 || isempty(tags)
        tags = cell(1, numel([all_MIs{1,:}]));
    end
    keep = size(all_MIs, 2) > 1;
    
    for MI = 1:numel(types)
        current_MIs = all_MIs(:,MI);
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
        f = figure(122+MI); hold on;
        if ~keep
            clf();
        end
        if size(screens, 1) > 1
            set(f, 'Position', screens(2,:));
        end

        %% Create subplot
        nrois = (size(all_rois,2)/2);
        axes = [];
        for roi = 0:nrois-1
            ax = subplot(nrois,1,roi+1);hold on
            title(['ROI ',num2str(roi+1), ' ', tags{roi+1}]);hold on
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
        linkaxes(axes, 'x'); hold on;

        if manual_browsing
            uiwait(f);
        end
    end
end