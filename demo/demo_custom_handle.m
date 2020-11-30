%% To test this, draw an Eye ROI on at least a video, and adjust indexes here to point at the correct video
vid = my_analysis.experiments(1).recordings(2).videos(1); % for display purpose

%% Demo Script : to extract mean image for a set of recordings, for the Eye ROI
roi_idx = find(contains(vid.roi_labels, 'Eye'));
im = vid.analyse(@(~,~) get_mean_proj(vid.path, vid.ROI_location{roi_idx}), '', '', 'none');
figure();imagesc(im);axis image

function im = get_mean_proj(file_path_or_data, ROI)
    [~, video] = get_MI_from_video(file_path_or_data, ROI);
    im = nanmean(video{1}, 3);
end