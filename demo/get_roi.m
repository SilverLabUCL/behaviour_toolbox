vid = my_analysis.experiments(6).recordings(2).videos(1); % for display purpose
[~, im] = vid.analyze(@(~,~) get_mean_proj(vid.path, vid.ROI_location{2}));

function im = get_mean_proj(file_path_or_data, ROI)
    [~, video] = get_MI_from_video(file_path_or_data, ROI);
    video = video{1};
    figure();
    im = imagesc(video(:,:,1));axis image
    for frame = 1:size(video, 3)
        im.CData = video(:,:,frame);pause(0.001)
    end
end