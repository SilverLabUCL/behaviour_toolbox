%% experiment is all_experiment{exp_idx}
% eg all_experiment{5} = clear_MI_idx(all_experiment{5}, 2, [1,4,8])

function experiment = clear_MI_idx(experiment, videotype, idx_to_clear)
    ok = 1:numel(experiment.fnames{1});
    ok = ~ismember(ok, idx_to_clear);
    
    %for videotype = 1:numel(experiment.fnames)
        experiment.windows{videotype} = experiment.windows{videotype}(ok,:);
        experiment.MI{videotype} = experiment.MI{videotype}(:,ok);
        experiment.timestamps{videotype} = experiment.timestamps{videotype}(:,ok);
        experiment.fnames{videotype} = experiment.fnames{videotype}(:,ok);
        experiment.types{videotype} = experiment.types{videotype}(:,ok);
        experiment.absolute_time{videotype} = experiment.absolute_time{videotype}(:,ok);
    %end
end

