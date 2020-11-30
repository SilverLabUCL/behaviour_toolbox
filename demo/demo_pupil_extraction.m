my_analysis = behaviour_GUI.analysis;
usable = find(cellfun(@(x) any(strcmp(x, 'Eye')), {my_analysis.experiments.roi_labels}));
force = true;
exp = 1; % 26

rendering = true;
thresh_factor = 1.1;
dark_prctile = 1;

%% Method 1, direct function call, in a loop, not using the analyse function.
for exp_idx = usable
    for rec_idx = 1:my_analysis.experiments(exp_idx).n_rec
        rec = my_analysis.experiments(exp_idx).recordings(rec_idx);
        for vid_idx = 1:rec.n_vid
            vid = rec.videos(vid_idx);
            EyeROI = find(cellfun(@(x) contains(x, 'Eye'), vid.roi_labels));
            if ~isempty(EyeROI)
                eye = vid.ROI_location{EyeROI};
                pupilFit = pupil_analysis(vid.path, rendering, thresh_factor, dark_prctile, eye);
            end
        end
    end
end

%% Method 2, using analyse() method and function callback, and storing data in the database

%% Set a new variable name. This is key to avoid overwriting the motion_index data 
behaviour_GUI.analysis.current_varname = 'pupil';

for exp_idx = exp%usable
    for rec_idx = 1:my_analysis.experiments(exp_idx).n_rec
        rec = my_analysis.experiments(exp_idx).recordings(rec_idx);
        for vid_idx = 1:rec.n_vid
            vid = rec.videos(vid_idx);
            fh = @(~,~) pupil_analysis(vid.path, rendering, thresh_factor, dark_prctile, vid.ROI_location{cellfun(@(x) contains(x, 'Eye'), vid.roi_labels)});
            data = vid.analyse(fh, force, '', 'pupil @format_pupil_output','Eye');
        end
    end
end

%% Now plot extracted results
behaviour_GUI.analysis.experiments(exp).plot_results