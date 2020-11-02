%% Script 1 # 
vid = my_analysis.experiments(6).recordings(2).videos(1); % for display purpose
im = vid.analyse(@(~,~) get_mean_proj(vid.path, vid.ROI_location{1}));
figure();imagesc(im);axis image

function im = get_mean_proj(file_path_or_data, ROI)
    [~, video] = get_MI_from_video(file_path_or_data, '', ROI);
    im = nanmean(video{1}, 3);
end
