my_analysis = behaviour_GUI.Experiment_set;
usable = find(cellfun(@(x) any(strcmp(x, 'Eye')), {my_analysis.experiments.roi_labels}));

rendering = true;
thresh_factor = 1.5;
dark_prctile = 1;

% Method 1
% for exp_idx = usable
%     for rec_idx = 1:my_analysis.experiments(idx).n_rec
%         rec = my_analysis.experiments(exp_idx).recordings(rec_idx);
%         for vid_idx = 1:rec.n_vid
%             vid = rec.videos(vid_idx);
%             EyeROI = find(cellfun(@(x) contains(x, 'Eye'), vid.roi_labels));
%             if ~isempty(EyeROI)
%                 eye = vid.ROI_location{EyeROI};
%                 pupilFit = pupil_analysis(vid.path, rendering, thresh_factor, dark_prctile, eye);
%             end
%         end
%     end
% end

for exp_idx = usable
    for rec_idx = 1:my_analysis.experiments(idx).n_rec
        rec = my_analysis.experiments(exp_idx).recordings(rec_idx);
        for vid_idx = 1:rec.n_vid
            vid = rec.videos(vid_idx);
            fh = @(~,~) pupil_analysis(vid.path, rendering, thresh_factor, dark_prctile, vid.ROI_location{cellfun(@(x) contains(x, 'Eye'), vid.roi_labels)});
            data = vid.analyze(fh, true, '', 'pupil');
        end
    end
end




is_pupil_field = cellfun(@(x) cellfun(@(y) isprop(y,'pupil'), {x.videos}, 'uni', false) , {my_analysis.experiments.recordings}, 'uni', false);
is_pupil_field = cellfun(@(x) cellfun(@(y) cellfun(@(z) isprop(z,'pupil'),...
                                                     {y}, 'uni', false),...
                                       {x.videos}, 'uni', false),...
                        {my_analysis.experiments.recordings}, 'uni', false);

cellfun(@(x) any([x{:}]), is_pupil_field)