%% experiment is all_experiment{exp_idx}
% eg all_experiment{5} = clear_MI_idx(all_experiment{5}, 2, [1,4,8])

function experiment = clear_MI_idx(experiment, videotype, idx_to_clear)
    ok = 1:numel(experiment.filenames{1});
    ok = ~ismember(ok, idx_to_clear);
    
    %for videotype = 1:numel(experiment.filenames)
        experiment.MI_windows{videotype} = experiment.MI_windows{videotype}(ok,:);
        experiment.motion_indexes{videotype} = experiment.motion_indexes{videotype}(:,ok);
        experiment.timestamps{videotype} = experiment.timestamps{videotype}(:,ok);
        experiment.filenames{videotype} = experiment.filenames{videotype}(:,ok);
        experiment.video_types{videotype} = experiment.video_types{videotype}(:,ok);
        experiment.absolute_time{videotype} = experiment.absolute_time{videotype}(:,ok);
    %end
end

