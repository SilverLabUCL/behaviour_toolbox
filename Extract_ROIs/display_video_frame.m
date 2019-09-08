function display_video_frame(reference_frame, ROI_window, video_path, display_duration, fig_handle)
    if nargin < 5 || isempty(fig_handle)
        fig_handle = figure(123); clf();hold on;
    end

    %% Display the frame, and add any existing ROI
    
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
        add_rect('', '', position);
    else
        %% If there are preexisting ROIs, display them
        for roi_idx = 1:size(ROI_window,2)
            roi_position = ROI_window(1,:); %first video is enough
            roi_position = roi_position{roi_idx};
            add_rect('', '', roi_position);
            text(roi_position(1)-5,roi_position(2)-5, ['\bf ',num2str(roi_idx)], 'Color', [1,0.2,0.2]);
        end                
    end
    
    %% Add preview button
    MI_test = uicontrol('Style', 'pushbutton', 'String', 'Test', 'Position', [50 50 100 40], 'Callback', @(event, src) MI_preview(event, src, video_path));
    
    %% Wait until closed     
    if ~display_duration
        uiwait(fig_handle);
    else
        pause(display_duration);
    end
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

function add_rect(~, ~, position)
    %% Add a new ROI
    global current_pos
    current_pos = [current_pos, {position}]; 
    hrect = imrect(gca, current_pos{end});hold on;
    set(hrect,'userdata',num2str(numel(current_pos)));
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
    global current_pos;
    idx = str2num(get(obj,'userdata'));
    current_pos{idx} = p;
end

function delete_rect(src, eventdata,obj)
    %% Overload the normal delete function.
    % This delete the ROI lines ( what the normal delete function does) but
    % also clear the corresponding fiel in current_pos
    try % fails when you close the wind
        global current_pos;
        idx = str2num(get(obj,'userdata'));
        current_pos{idx} = {};
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
