%% For a given list of MIs, plot them, one per subplot

function plot_MIs(recordings, tags, t_offset, manual_browsing)
    if nargin < 3 || isempty(t_offset)
        t_offset = 0;
    end
    if nargin < 4 || isempty(manual_browsing)
        manual_browsing = false;
    end

    %% Regroup MIs
    %max_MI = max(cellfun(@numel, MIs));
    %keep = max_MI > 1;
    
    all_MIs = vertcat(recordings.motion_indexes);
    if nargin < 2 || isempty(tags)
        tags = cell(1, numel([all_MIs{1,:}]));
    end
    keep = size(all_MIs, 2) > 1;
    types = recordings.videotypes;
    for MI = 1:numel(types)
        current_MIs = all_MIs(:,MI);
        all_rois = cell2mat(vertcat(current_MIs{:}));

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