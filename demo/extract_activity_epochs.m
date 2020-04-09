%% Show how to get timepoints for a specific MI

%analysis = behaviour_GUI.Experiment_set;
smoothing = [3, 0];
method = 'movmean';
%video_fact = 0.445;
video_fact = 0.82; % to change x axis on plot so it matches the video display
thr_pct = 10; % prct of max response above baseline to be considered as response
min_length_s = 0.2; %responses shorter than this are ignored
min_gap_s = 1;% gap shorted tnan this are ignored


for exp = 9:numel(analysis.experiments)
    current_experiment = analysis.experiments(exp);

    Paths = {current_experiment.recordings.path};
    
    tf = true(size(Paths));
    T = table(tf', Paths');
    f = figure('Name', 'Select recordings of interest', 'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', 'CloseRequestFcn',@close_mini_gui);
    uit = uitable('Parent', f, 'Data', table2cell(T), ...
                  'ColumnWidth', {'auto',  500},...              
                  'RowName', '', 'ColumnName', {'Use?', 'Path'}, ...
                  'ColumnEditable', [true, false]);
%     jscroll = findjobj(uitable);
%     jTable = jscroll.getViewport.getView;
%     jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS)
    table_extent = get(uit,'Extent');
    set(uit,'Position',[1 1 table_extent(3) table_extent(4)])
    figure_size = get(f,'outerposition');
    desired_fig_size = [figure_size(1) figure_size(2) table_extent(3)+15 table_extent(4)+65];
    set(f,'outerposition', desired_fig_size);
    uiwait(f);
    selection = evalin('base','temp');
    
    %% Select recordings 7 to 11
    current_subselection = current_experiment.recordings(selection);
    
    %% First, identify thresholds for all videos
    temp_data = [];
    for idx = 1:numel(current_subselection)
        MIs = {};
        for vid_type = 1:numel(current_subselection(idx).motion_indexes)
            MIs{vid_type} = current_subselection(idx).motion_indexes{vid_type}{1};
        end
        highest_sr = max(cellfun(@(x) size(x, 1), MIs));
        for vid_type = 1:numel(current_subselection(idx).motion_indexes)
            MIs{vid_type} = interpolate_to(MIs{vid_type}, highest_sr)';
        end
        current_event = cat(3, MIs{:});
        current_event = nanmean(current_event, 3);
        dt = median(diff(current_event(:,2)))/1000; % in ms
        temp_data = [temp_data; smoothdata(current_event(:, 1), method, round(smoothing / dt))];
    end
    thr = prctile(temp_data, 5) + (prctile(temp_data, 99) - prctile(temp_data, 5) ) / (100/thr_pct);
    tax = 1:numel(temp_data);
    figure(111);cla();plot(tax,temp_data,'k');hold on;plot(tax(temp_data > thr), temp_data(temp_data > thr))

    %%Now go through videos and detect activity epochs
    for idx = 1:numel(current_subselection)
        MIs = {};
        for vid_type = 1:numel(current_subselection(idx).motion_indexes)
            MIs{vid_type} = current_subselection(idx).motion_indexes{vid_type}{1};
        end
        highest_sr = max(cellfun(@(x) size(x, 1), MIs));
        for vid_type = 1:numel(current_subselection(idx).motion_indexes)
            MIs{vid_type} = interpolate_to(MIs{vid_type}, highest_sr)';
        end
        current_event = cat(3, MIs{:});
        current_event = nanmean(current_event, 3);
        
        %% Get relative t per video, in seconds
        time = current_event(:, 2)/1000 - current_event(1, 2)/1000;

        %% Smooth MI signal
        dt = median(diff(current_event(:,2)))/1000; % in ms
        data = smoothdata(current_event(:, 1),method,round(smoothing / dt));
        data(1) = data(2);
        data(isnan(data)) = min(data(:));
        
        %% Show trace
        figure(123);cla();plot(time*video_fact, data, 'k'); hold on;

        %% Find period of time above thr
        data_thr = data > thr;
        starts = find(diff(data_thr) == 1);
        stops = find(diff(data_thr) == -1);
        if data(1) > thr
            starts = [1; starts];
        end
        if data(end) > thr
            stops = [stops; numel(data)];
        end

        %% identify gaps of less than 500ms and remove them
        dt = time(2)-time(1);
        gap_to_short = find([starts(2:end) - stops(1:end-1)]*dt < min_gap_s);
        starts(gap_to_short+1) = [];
        stops(gap_to_short) = [];

        trial_to_short = find([stops - starts]*dt < min_length_s);
        starts(trial_to_short) = [];
        stops(trial_to_short) = [];
        
        out = '';
        figure(123);xlim([0, numel(data)*dt*video_fact]);
        title(strrep(current_subselection(idx).videos(end).path,'_','-'))
        for el = 1:numel(starts)
            plot(time(starts(el):stops(el))*video_fact, data(starts(el):stops(el)), 'Color', 'r', 'LineWidth', 2); hold on
            out = [out, num2str(round(starts(el)*dt,1)), '-', num2str(round(stops(el)*dt, 1)),'; '];
        end
        
        current_subselection(idx).videos(end).path(32:end)
        out

        winopen(current_subselection(idx).videos(end).path);
        pause(1)
    end
end


function close_mini_gui(src, event)
    data = src.Children.Data;
    tmp = data(:, 1);  % Get the state of our checkboxes
    selection = [tmp{:}];  % Denest the logicals from the cell array
    assignin('base','temp',selection);
    closereq();
end

