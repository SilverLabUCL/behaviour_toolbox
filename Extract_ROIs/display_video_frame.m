%% TODO : replace video_type_idx by name matching

function [current_experiment, names] = display_video_frame(current_experiment, video_type, display_duration, fig_handle, preset_buttons)
    %% Display the frame, and add any existing ROI
    if nargin < 4 || isempty(fig_handle)
        fig_handle      = figure(123); clf();hold on;
    end
    if nargin < 5 || isempty(preset_buttons)
        preset_buttons  = '';
    end

    clear global current_offset current_pos roi_handles link current_video
    global link current_video current_pos busy
    link                = {};
    link.name           = {};
    link.id             = [];
    link.label          = {};
    link.preset_buttons_handles = {};
    current_video       = 0;
    current_pos         = {};
    busy                = false;

    [reference_frame, all_frames] = current_experiment.get_consensus_frame(video_type);

    %% QQ using video_type_idx instead of name. could cause issue with video failures
    video_paths         = cell(current_experiment.n_rec, 1);
    ROI_offsets         = cell(current_experiment.n_rec, 1);
    for rec = 1:numel(current_experiment.recordings) % cannot use video_paths     = arrayfun(@(x) x.videos(video_type_idx).path, [current_experiment.recordings], 'UniformOutput', false)'; if there are missing videos
        if current_experiment.recordings(rec).n_vid
            real_idx = find(cellfun(@(x) contains(x, video_type), {current_experiment.recordings(rec).videos.path}));
            if ~isempty(real_idx)
                idx_to_use = real_idx;
                video_paths{rec} = current_experiment.recordings(rec).videos(real_idx).path;
                ROI_offsets{rec} = current_experiment.recordings(rec).videos(real_idx).video_offset;
            else
                video_paths{rec} = '';
                ROI_offsets{rec} = [NaN, NaN];
            end
        end
    end
    
    last_valid_videorec = find(~strcmp(video_paths, ''), 1, 'last');
    video_path          = fileparts(fileparts(fileparts(video_paths{last_valid_videorec})));
    
    pre_existing_offset = current_experiment.recordings(last_valid_videorec).videos(idx_to_use).video_offset;
    ROI_window          = current_experiment.recordings(last_valid_videorec).videos(idx_to_use).ROI_location;
    if ~any(cellfun(@isempty, ROI_window))
        ROI_window          = cellfun(@(x) [x(1:2) - pre_existing_offset, x(3:end)], ROI_window, 'UniformOutput', false); % This is to cancel the correction from the get method of ROI_location, otherwise you would get a double correction
    end
    link.existing_result= current_experiment.recordings(last_valid_videorec).videos(idx_to_use).extracted_results;
    link.n_vid          = size(all_frames, 3);
    if ~all(all(isnan(cell2mat(ROI_offsets)))) && any(any(cell2mat(ROI_offsets))) % reload previous offsets if available
        link.auto_offsets = {cell2mat(ROI_offsets)};
    elseif current_experiment.parent_h.auto_estimate_offsets % otherwise, values are 0 or auto_estimates
        link.auto_offsets   = autoestimate_offsets('', '', all_frames);
    else
        link.auto_offsets = {cell2mat(ROI_offsets)};
    end

    %% Preview figure
    set(fig_handle, 'Units','normalized','Position',[0 0 1 1]);
    axis image; hold on;
    fig_handle.Color    = 'w';
    tit                 = title({'Close window or press Return key to validate'; fix_path(video_path, true)});
    set(gca,'YDir','reverse');hold on ;
    im_handle           = imagesc(reference_frame,'hittest','off'); hold on;

    %% Add callback to add more ROIs
    cmenu               = uicontextmenu;
    position            = [floor(size(reference_frame, 2)/2), floor(size(reference_frame, 1)/2), 20, 20]; %default pos
    bgmenu              = uimenu(cmenu,'label','Add ROI','Callback',@(src,eventdata) add_rect(src, eventdata, position));
    set(gca, 'uicontextmenu', cmenu)
    set(fig_handle,'KeyPressFcn',{@escape_btn ,fig_handle});
    
    %% If there are preexisting ROIs, display them
    global current_offset
    for roi_idx = find(~cellfun(@isempty, ROI_window))%1:size(ROI_window,2)
        roi_position    = ROI_window(1,:); %first video is enough
        roi_position    = roi_position{roi_idx};

        current_roi = current_experiment.recordings(last_valid_videorec).videos(idx_to_use).rois(roi_idx);
        if isempty(current_roi.name)     
            label       = ['Label # ',num2str(roi_idx)];
        else
            label       = current_roi.name;
        end
        if ~isprop(current_roi.extracted_data, current_roi.current_varname) || isempty(current_roi.extracted_data.(current_roi.current_varname))
            color       = 'y';
        else
            color       = 'g';
        end  
        add_rect('', '', roi_position, label, color, size(all_frames, 3));
        
        %% Update the per-video offsets (same offset for all ROIs for now)
        current_offset{roi_idx} = cell2mat(ROI_offsets);            
        %link.name(roi_idx)  = {label};
        %link.label(roi_idx) = {text(roi_position(1)-5,roi_position(2)-5, ['\bf ',label], 'Color', [1,0.2,0.2])};
    end 

    %% Add preset button
    offset = 0;
    for preset          = 1:numel(preset_buttons)
        offset          = offset + 50;
        position        = position(1:4); % no keeping id
        link.preset_buttons_handles{preset} = uicontrol('Style', 'pushbutton', 'String', preset_buttons{preset}, 'Position', [30 50+offset 100 40], 'Callback', @(event, src) add_rect(src, event, position,'', '', size(all_frames, 3)));
    end
    
    %% Add extra button
    uicontrol('Style', 'pushbutton', 'String', 'Clear offset', 'BackgroundColor', [1,0.5,0.5], 'Units','normalized','Position',[0.9 0.1 0.08 0.04], 'Callback', @(event, src) clear_offsets(src, event));
    uicontrol('Style', 'pushbutton', 'String', 'Measure', 'Units','normalized','Position',[0.9 0.2 0.08 0.04], 'Callback', @(event, src) result_preview(event, src, im_handle));
    uicontrol('Style', 'pushbutton', 'String', 'Auto-estimate offset', 'Units','normalized','Position',[0.9 0.3 0.08 0.04], 'Callback', @(event, src) autoestimate_offsets(src, event, all_frames));
    uicontrol('Style', 'checkbox', 'String', 'Move All ROIs', 'Units','normalized','Position',[0.9 0.4 0.08 0.04], 'BackgroundColor', [1,1,1]);

    uicontrol('Style', 'slider',...
              'Units', 'normalized',...
              'Position', [0.2,0.05,0.6,0.05],...
              'Value', 0,...
              'SliderStep',[1/(size(all_frames, 3)), 1/(size(all_frames, 3))],...
              'Callback', @(event, src) change_image(event, src, reference_frame, all_frames, im_handle, tit, video_paths),...
              'min', 0, 'max', size(all_frames, 3));

    %% Wait until closed     
    if ~display_duration
        uiwait(fig_handle);
    else
        pause(display_duration);
    end

    names           = link.name;
    close all
end

function escape_btn(varargin)
    if any(strcmp(varargin{1,2}.Key,{'escape','return'}))
        close(varargin{1});
    %     elseif strcmp(varargin{1,2}.Key, 'add')
    %         add_rect('', '', current_pos);
    %     elseif strcmp(varargin{1,2}.Key, 'subtract')
    %         delete_rect(src, eventdata,obj);
    end
end

function change_image(event, src, reference_frame, all_frames, im_handle, tit, video_paths)
    event.Value = round(event.Value);
    global current_video
    current_video = event.Value; 
    enable_disable_buttons(current_video == 0);
    if event.Value == 0
        im = reference_frame;
        tit.String{2} = fix_path(fileparts(fileparts(fileparts(video_paths{1}))),true);
    else
        im = all_frames(:,:,event.Value);
        tit.String{2} = fix_path(video_paths{event.Value},true);
    end
    im_handle.CData = im; 
    
    refresh_rois();
end

function enable_disable_buttons(status)
    global link roi_handles
    
    %% Allow deletion only from first video
    for roi = 1:numel(roi_handles)
        if isvalid(roi_handles(roi))
            roi_handles(roi).Deletable = status;            
            roi_handles(roi).setResizable(status);            
        end
    end
    
    %% Convert status to string
    if status
        status = 'on';
    else
        status = 'off';
    end
    
    %% Prevent addition of new preset ROIs
    for but = 1:numel(link.preset_buttons_handles)
        link.preset_buttons_handles{but}.Enable = status;
    end
end

function refresh_rois()
    %% Reposition ROIs for current video
    global current_video current_pos current_offset roi_handles
    for roi = 1:numel(current_pos)
        if ~isempty(current_offset{roi}) % empty when deleted
            if current_video
                all_offsets = current_offset(~cellfun(@isempty, current_offset));
                offset = mean(cell2mat(cellfun(@(x) x(current_video,:), all_offsets, 'UniformOutput', false)'),1); % force mean offset
            else
                offset = [0,0];
            end  
            roi_handles(roi).setPosition(current_pos{roi}(1:4) + [offset, 0, 0]);
        end
    end
end

function clear_offsets(~, ~)
    global current_video current_offset roi_handles
    vid_idx = current_video;
    
    % Could be used for ROI by ROI precision
    %to_clear = listdlg('PromptString', {'Select the ROIs where you want the offsets to be cleared','This will be applied to this recording and the following ones'},'ListString',link.name);
    
    if vid_idx == 0
        answer = questdlg('Clear offset of all recordings?');
        vid_idx = 1;
    else
        answer = questdlg('Clear offset of all following recordings?');
    end
    
    if strcmp(answer, 'Yes')
        %% Clear offsets
        for roi = 1:numel(roi_handles) %to_clear
            current_offset{roi}(vid_idx:end,:) = 0;
        end 
        
        %% Update ROI position
        refresh_rois();
    end
end

function offsets = autoestimate_offsets(~, ~, all_frames)
    %% Get some info to help choosing ROIs
    
    %% QQ SEE autoestimate_offsets method    
    ref_nb = find(~isnan(all_frames(1,1,:)),1,'first');
    offsets = {[0, 0]};
    for frame = 2:size(all_frames, 3)
        if ~isnan(mean2(all_frames(:,:,frame)))
            offsets{frame} = dftregistration(all_frames(1:100,:,ref_nb), all_frames(1:100,:,frame), 100);
            offsets{frame} = offsets{frame}([4,3])*-1;
        else
            offsets{frame} = [NaN, NaN];
        end
    end

    %% Update ROI position, or return values
    global current_offset
    if ~nargout
        not_deleted = ~cellfun(@isempty, current_offset);
        current_offset(not_deleted) = repmat({cell2mat(offsets')},1 , sum(not_deleted));
        refresh_rois();
    else
        offsets = {cell2mat(offsets')};
    end
end

function add_rect(~, src, position, label, color, n_vid)
    if nargin < 4 || isempty(label)
        label = '';
    end
    if nargin < 5  || isempty(color)
        color = 'r';
    end
    
    label = strrep(label, '_', '\_');
    
    %% Add a new ROI
    global current_pos current_offset link roi_handles current_video
    if nargin < 6  || isempty(n_vid)
        n_vid = link.n_vid;
    end
    
    if current_video
        error_box('New ROIs must be added from the reference image',1)
        return
    end

    if numel(position) == 4
        id = round(unifrnd(1,10000)); % use this to identify rectangles
        position = [position, id];
    else
        id = position(5);
    end
    current_pos     = [current_pos, {position}];
    
    if (~iscell(current_offset) && isempty(current_offset))
        %% Initial ROI get auto-estimate values
        current_offset  = link.auto_offsets; %% Add initial auto offset estimate
    elseif iscell(current_offset) && all(cellfun(@isempty, current_offset))
        %% When all ROIs were deleted, everything is empty, but you need to keep empty cells
        current_offset  = [current_offset, link.auto_offset];
    else
        %% In most cases, you add a new ROI, so you just replicate last valid offset
        current_offset  = [current_offset, current_offset{find(~cellfun(@isempty, current_offset),1,'last')}];%{repmat([0,0],n_vid,1)}];
    end
    hrect           = imrect(gca, current_pos{end}(1:end-1));hold on;
    roi_handles     = [roi_handles, hrect];
  
    if ~isempty(label)
        %% then use label
    elseif ~isempty(src) && isprop(src, 'String')
        label = src.String;
    else
        label = ['Label # ',num2str(numel(current_pos))];
    end
    set(hrect,'userdata',num2str(id));
    link.id(numel(current_pos))     = id;
    link.name(numel(current_pos))   = {label};
    link.label(numel(current_pos))  = {text(position(1)-5,position(2)-5, ['\bf ',label], 'Color', color)};
    set(hrect,'DeleteFcn', @(src,eventdata) delete_rect(src,eventdata,hrect));
    hrectchild = get(hrect, 'Children');
    hcmenu = get(hrectchild(2),'UIContextMenu');
    %itemnew = uimenu(hcmenu, 'Label', '[Add rectangle here]', 'Callback', @new_rectangle); 
    hrect.addNewPositionCallback(@(p) read(hrect,p));hold on;
    
    %% Force ROI as square 
    %     fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));hold on;
    %     setPositionConstraintFcn(hrect,fcn); hold on;
    %     setFixedAspectRatioMode(hrect,1);hold on;
end

function read(obj, p)
    stackcall = dbstack;
    
    %% Prevent multiple read calls to stcak
    if sum(contains({stackcall.name},'imrectAPI/setPosition')) <= 2

        %% Read current ROI location and size
        global current_pos current_offset link current_video roi_handles

        f = get(obj);
        id = str2num(f.UserData);
        idx = find(cellfun(@(x) x(end), current_pos) == id);


        if current_video == 0    
            displacement = p(1:2) - current_pos{idx}(1:2);
            current_pos{idx} = [p, id(1)];
            link.label{idx}.Position(1:2) = current_pos{idx}(1:2)-5;            
            force_move_all = findobj(f.Parent.Parent.Children, '-depth',1, 'String','Move All ROIs');
            force_move_all = force_move_all.Value; % if check box ticked, then move all ROI's at once
            if force_move_all
                all_idx = 1:numel(current_pos);
                all_idx = all_idx(all_idx ~= idx);
                for roi = all_idx
                    p = current_pos{roi}(1:2) + displacement;
                    current_pos{roi}(1:2) = p;
                    link.label{roi}.Position(1:2) = current_pos{roi}(1:2)-5;
                    if ~isempty(current_pos{roi}) % empty when deleted
                        roi_handles(roi).setPosition(current_pos{roi}(1:4));
                    end
                end
            end
           
            if any(displacement) && all(link.label{idx}.Color == [0 1 0])
                link.label{idx}.Color = [1 1 0];
            end
        elseif ~contains([stackcall.name],'change_image')
            if ~all(current_pos{idx}(3:4) == p(3:4)) % don't reshape ROIs if you are not on the ref
                return
            end

            current_offset{idx}(current_video:end,:) = repmat(p(1:2) - current_pos{idx}(1:2), size(current_offset{idx}(current_video:end,:), 1), 1);
            link.label{idx}.Position(1:2) = current_pos{idx}(1:2)+current_offset{idx}(current_video,:)-5;
            for roi = 1:numel(current_pos)
                if ~isempty(current_offset{roi}) % empty when deleted
                    roi_handles(roi).setPosition(current_pos{roi}(1:4) + [current_offset{idx}(current_video,:), 0, 0]);
                end
            end
            if all(link.label{idx}.Color == [0 1 0])
                link.label{idx}.Color = [1 1 0];
            end
        else
            current_offset{idx}(current_video,:) = current_offset{idx}(current_video,:);
            link.label{idx}.Position(1:2) = current_pos{idx}(1:2)+current_offset{idx}(current_video,:)-5;
        end
    end
end

function delete_rect(src, eventdata, obj)
    %% Overload the normal delete function.
    % This delete the ROI lines ( what the normal delete function does) but
    % also clear the corresponding fiel in current_pos
    try % fails when you close the wind
        global current_pos current_offset link roi_handles;
        id = str2num(get(obj,'userdata'));
        idx = find(cellfun(@(x) x(end), current_pos) == id);
        current_pos{idx} = id;
        link.id(idx)     = NaN;
        link.name(idx)   = {''};
        roi_handles(idx).delete();
        current_offset(idx) = {''};
        delete(link.label{idx});
        childrens = get(obj,'Children');
        for el = 1:numel(childrens)
            delete(childrens(el));
        end
    end
end

function result_preview(~, ~, im_handle)
    %% For a given frame, display a quick preview of the current ROIs
    global current_pos current_offsets current_video link
    if current_video
        video_path = get(im_handle.Parent, 'title');
        video_path = video_path.String{2};
        video_path = fix_path(video_path, true);
        results = get_MI_from_video(video_path, current_pos, true, true, '', current_offsets) ;
        t = results{1}(:, 2);
        results = cell2mat(cellfun(@(x) x(:, 1), results, 'UniformOutput', false));
        figure();plot(t, results + ones(size(results)).*(1:numel(link.name)).*-1 + numel(link.name)); hold on;
        legend(link.name)
    else
        error_box('result preview only works for individual recordings',1)
    end
    %     data = single(squeeze(load_stack(video_path, '', '', 20))); % one every 20 frames
    %     multiple_extracted_results(data, '', true, current_pos);
end
