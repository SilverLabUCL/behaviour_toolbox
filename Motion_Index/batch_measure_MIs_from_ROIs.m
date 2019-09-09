%% Call batch_select_MI_rois() first to create ROIs, then pass the generated ouput
%
% to re-measure all MIs  
% [failed_analysis] = batch_measure_MIs_from_ROIs(all_experiments_output, true)
% 
% to measure only new y MIs , or display exisiting ones
% [failed_analysis] = batch_measure_MIs_from_ROIs(all_experiments_output, false)
% 



function [failed_analysis] = batch_measure_MIs_from_ROIs(existing_experiments, force, display, manual_browsing)
    
    %% Force specific MI to be updated
    % By default, only ROIs with no MI are analysed. You can pass a list of
    % indexes or 'all' to force the update of those indexes
    if nargin < 2 || isempty(force)
        force = -1;
    elseif isstr(force) && strcmp(force, 'all')
        force = 1:numel(existing_experiments);
    end
    if nargin < 3 || isempty(display)
        display = true;
    end
    if nargin < 4 || isempty(manual_browsing)
        manual_browsing = false;
    end
    
    %% Initialize variables
    % Globals are quite bad i know, but you don't want to loose info half 
    % way in the analysis. If you stop half
    % way, the cleanup function should send the current result in the base
    % workspace.
    global all_experiments 
    all_experiments = existing_experiments;
    all_experiments = all_experiments(~cellfun(@isempty, all_experiments));
    clear existing_experiments;

    %% This will send the current output to base workspace even if the
    % analysis is incomplete
    cleanupObj = onCleanup(@() cleanMeUp());

    %% Now that all Videos are ready, get the motion index if the MI section is empty
    failed_analysis = {};
    for exp_idx = 1:numel(all_experiments) 
        experiment = all_experiments{exp_idx};
%        try
            if isfield(all_experiments{exp_idx},  'fnames')
                for video_type_idx = 1:numel(experiment.windows)
                    if isempty(all_experiments{exp_idx}.MI{video_type_idx}) || ismember(exp_idx, force)
                        for video_record = 1:size(experiment.windows{video_type_idx}, 1)

                            fname = experiment.fnames{video_type_idx}{video_record};
                            
%                             if contains(fname, 'Whisk')
%                                 %pass
%                             else
                                path = strsplit(strrep(fname,'/','\'),'Cam');
                                path = [path{1},'Cam-relative times.txt'];

                                %% To use the parent folder instead (because it has absolute timestamps)
                                path = strsplit(path,'\');
                                path = strjoin(path([1:end-2,end]),'\');

                                fileID = fopen(path,'r');
                                timescale = textscan(fileID, '%f%f%s%[^\n\r]', 'Delimiter', '\t', 'TextType', 'string', 'EmptyValue', NaN,  'ReturnOnError', false);
                                fclose(fileID);

                                %% Get real time
                                absolute_time = cellfun(@(timepoint) strsplit(timepoint, ';'), timescale{3}, 'UniformOutput', false); % separate day from time
                                absolute_time = cellfun(@(timepoint) cellfun(@str2num, (strsplit(timepoint{2},':'))), absolute_time, 'UniformOutput', false); % separte hr, min, s
                                absolute_time = cell2mat((cellfun(@(timepoint) sum(timepoint .* [3600000, 60000, 1000]), absolute_time, 'UniformOutput', false))); % convert all to ms

                                %% Get camera timestamps
                                camera_timescale = timescale{2}/1000;

                                %% Get MI
                                motion_indexes = get_MI_from_video(fname, absolute_time, false, experiment.windows{video_type_idx}(1,:), false);
                                
                                %% Store results
                                if display
                                    temp = cell2mat(motion_indexes);
                                    temp = temp - prctile(temp,1);
                                    temp = temp ./ max(temp);
                                    figure(123);cla();plot(temp(:,1:2:end)); drawnow
                                end
                                
                                all_experiments{exp_idx}.MI{video_type_idx}{video_record} = motion_indexes;
                                all_experiments{exp_idx}.timestamps{video_type_idx}{video_record} = camera_timescale;
                                all_experiments{exp_idx}.absolute_time{video_type_idx}{video_record} = absolute_time;
%                             end
                        end
                    end 
                end
                
                
                if display
                    first_tp_of_exp = min(cellfun(@min, [all_experiments{exp_idx}.absolute_time{:}]));
                    for video_type_idx = 1:numel(experiment.windows)
                        all_experiments{exp_idx}.absolute_time{video_type_idx} = cellfun(@(x) x- first_tp_of_exp, all_experiments{exp_idx}.absolute_time{video_type_idx}, 'UniformOutput', false);
                        plot_MIs(all_experiments{exp_idx}.MI{video_type_idx}, '', video_type_idx > 1, first_tp_of_exp, manual_browsing);
                        pause(0.1)
                    end
                end
            end
    %    catch
      %     failed_analysis = [failed_analysis, {experiment}];
     %   end
    end
end


function cleanMeUp()
    %% if interrupted, send experiment to base workspace
    global all_experiments
    assignin('base', 'all_experiments_output', all_experiments);
    clear global all_experiments
end 