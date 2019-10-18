function [current_experiment, names] = display_video_frame(current_experiment, video_type_idx, display_duration, fig_handle, preset_buttons)
    %% Display the frame, and add any existing ROI
    if nargin < 4 || isempty(fig_handle)
        fig_handle = figure(123); clf();hold on;
    end
    if nargin < 5 || isempty(preset_buttons)
        preset_buttons = {'Whisker', 'Nose', 'Jaw', 'Breast', 'Wheel', 'Laser', 'Caudal Forelimb', 'Trunk', 'Tail'};
    end

    global link
    link = {};
    link.name = {};
    link.id   = [];
    link.label   = {};

    list_of_videotypes = current_experiment.videotypes;
    type = list_of_videotypes{video_type_idx};
    [reference_frame, ~, ~, ~] = get_representative_frame(current_experiment, video_type_idx, type, true);

    %% QQ ONLY VIDEO 1 USED
    video_path = current_experiment.recordings(1).videos(video_type_idx).file_path;
    ROI_window = current_experiment.recordings(1).videos(video_type_idx).ROI_location;
    
    
    %% Preview figure
    set(fig_handle, 'Units','normalized','Position',[0 0 1 1]);
    axis equal; hold on;
    title({'Close window to validate'; strrep(strrep(video_path,'\','/'),'_','-')})
    set(gca,'YDir','reverse');hold on ;
    im = imagesc(reference_frame,'hittest','off'); hold on;

    %% Add callback to add more ROIs
    cmenu = uicontextmenu;
    position = [floor(size(reference_frame, 2)/2), floor(size(reference_frame, 1)/2), 20, 20]; %default pos
    bgmenu = uimenu(cmenu,'label','Add ROI','Callback',@(src,eventdata) add_rect(src, eventdata, position));
    set(gca, 'uicontextmenu', cmenu)

    set(fig_handle,'KeyPressFcn',{@escape_btn ,fig_handle});
    
    %% Add ROIs
    if isempty(ROI_window)
        %% If it is the first call, add a first ROI in the middle
        id = round(unifrnd(1,10000)); % use this to identify rectangles
        position = [position, id];
        add_rect('', '', position);
    else
        %% If there are preexisting ROIs, display them
        for roi_idx = 1:size(ROI_window,2)
            roi_position = ROI_window(1,:); %first video is enough
            roi_position = roi_position{roi_idx};
            
            if isempty(current_experiment.recordings(1).videos(video_type_idx).rois(roi_idx).name)     
                label = ['Label # ',num2str(roi_idx)];
            else
                label = current_experiment.recordings(1).videos(video_type_idx).rois(roi_idx).name;
            end
            add_rect('', '', roi_position, label);
            %link.name(roi_idx)  = {label};
            %link.label(roi_idx) = {text(roi_position(1)-5,roi_position(2)-5, ['\bf ',label], 'Color', [1,0.2,0.2])};
        end                
    end
    
    %% Add preview button
    MI_test = uicontrol('Style', 'pushbutton', 'String', 'Test', 'Position', [50 50 100 40], 'Callback', @(event, src) MI_preview(event, src, video_path));
    offset = 0;
    for preset = 1:numel(preset_buttons)
        offset = offset + 50;
        uicontrol('Style', 'pushbutton', 'String', preset_buttons{preset}, 'Position', [30 50+offset 100 40], 'Callback', @(event, src) add_rect(src, event, position));
    end
    
    %% Wait until closed     
    if ~display_duration
        uiwait(fig_handle);
    else
        pause(display_duration);
    end

    names = link.name;
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

function add_rect(~, src, position, label)
    if nargin < 4 
        label = '';
    end
    %% Add a new ROI
    global current_pos link
    if numel(position) == 4
        id = round(unifrnd(1,10000)); % use this to identify rectangles
        position = [position, id];
    else
        id = position(5);
    end
    current_pos = [current_pos, {position}]; 
    hrect = imrect(gca, current_pos{end}(1:end-1));hold on;
    if ~isempty(label)
        %% then use label
    elseif ~isempty(src)
        label = src.String;
    else
        label = ['Label # ',num2str(numel(current_pos))];
    end
    set(hrect,'userdata',num2str(id));
    link.id(numel(current_pos))     = id;
    link.name(numel(current_pos))   = {label};
    link.label(numel(current_pos))  = {text(position(1)-5,position(2)-5, ['\bf ',label], 'Color', [1,0.2,0.2])};
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
    %% Read current ROI location and size
    global current_pos link;
    id = str2num(get(obj,'userdata'));
    idx = find(cellfun(@(x) x(end), current_pos) == id);
    current_pos{idx} = [p, id];
    link.label{idx}.Position(1:2) = p(1:2)-5;
end



function delete_rect(src, eventdata,obj)
    %% Overload the normal delete function.
    % This delete the ROI lines ( what the normal delete function does) but
    % also clear the corresponding fiel in current_pos
    try % fails when you close the wind
        global current_pos link;
        id = str2num(get(obj,'userdata'));
        idx = find(cellfun(@(x) x(end), current_pos) == id);
        current_pos{idx} = id;
        link.id(idx)     = NaN;
        link.name(idx)   = {''};
        delete(link.label{idx});
        childrens = get(obj,'Children');
        for el = 1:numel(childrens)
            delete(childrens(el));
        end
    end
end

function MI_preview(~, ~, video_path)
    %% For a given frame, display a quick preview of the current ROIs
    global current_pos;
    data = single(squeeze(load_stack(video_path, '', '', 20))); % one every 20 frames
    multiple_motion_indexes(data, '', true, current_pos);
end
