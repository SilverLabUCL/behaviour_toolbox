%% Call batch_select_MI_rois() first to create ROIs, then pass the generated ouput
%
% to re-measure all MIs  
% [all_experiments, failed_analysis] = batch_measure_MIs_from_ROIs(all_experiments_output, true)
% 
% to measure only new y MIs , or display exisiting ones
% [all_experiments, failed_analysis] = batch_measure_MIs_from_ROIs(all_experiments_output, false)
% 

function [analysis, failed_analysis] = batch_measure_MIs_from_ROIs(analysis, force, display, manual_browsing)
    
    %% Force specific MI to be updated
    % By default, only ROIs with no MI are analysed. You can pass a list of
    % indexes or 'all' to force the update of those indexes
    if nargin < 2 || isempty(force)
        force = -1;
    elseif isstr(force) && strcmp(force, 'all')
        force = 1:numel(analysis);
    end
    if nargin < 3 || isempty(display)
        display = true;
    end
    if nargin < 4 || isempty(manual_browsing)
        manual_browsing = false;
    end
    
    %% Setup a safety backup
    analysis.experiments = analysis.experiments(~arrayfun(@isempty, analysis.experiments));
    assignin('base', 'analysis_temp_backup', analysis);
%     global analysis_complete
%     analysis_complete = false;
%     cleanupObj = onCleanup(@() cleanMeUp());

    %% Now that all Videos are ready, get the motion index if the MI section is empty
    failed_analysis = {};
    for exp_idx = 1:analysis.n_expe 
        for rec = 1:analysis.experiments(exp_idx).n_rec
            for vid = 1:analysis.experiments(exp_idx).recordings(rec).n_vid
                current_video = analysis.experiments(exp_idx).recordings(rec).videos(vid);
                if any(cellfun(@isempty, current_video.motion_indexes)) || ismember(exp_idx, force)
                    path = strsplit(strrep(current_video.path,'/','\'),'Cam');
                    path = [path{1},'Cam-relative times.txt'];

                    %% To use the parent folder instead (because it has absolute timestamps)
                    path = strsplit(path,'\');
                    path = strjoin(path([1:end-2,end]),'\');

                    fileID = fopen(path,'r');
                    timescale = textscan(fileID, '%f%f%s%[^\n\r]', 'Delimiter', '\t', 'TextType', 'string', 'EmptyValue', NaN,  'ReturnOnError', false);
                    fclose(fileID);

                    %% Get real time
                    absolute_times = cellfun(@(timepoint) strsplit(timepoint, ';'), timescale{3}, 'UniformOutput', false); % separate day from time
                    absolute_times = cellfun(@(timepoint) cellfun(@str2num, (strsplit(timepoint{2},':'))), absolute_times, 'UniformOutput', false); % separte hr, min, s
                    current_video.absolute_times = cell2mat((cellfun(@(timepoint) sum(timepoint .* [3600000, 60000, 1000]), absolute_times, 'UniformOutput', false))); % convert all to ms

                    %% Get camera timestamps
                    current_video.timestamps = timescale{2}/1000;
                    current_video.sampling_rate = 1/mean(diff(current_video.absolute_times))*1000;

                    %% Get MI
                    current_video.motion_indexes = get_MI_from_video(current_video.path, current_video.absolute_times, false, current_video.ROI_location, false, '', current_video.video_offset);

                    %% Update analysis object
                    analysis.experiments(exp_idx).recordings(rec).videos(vid) = current_video;

                    %% Store results
                    if display
                        temp = cell2mat(current_video.motion_indexes);
                        temp = temp - prctile(temp,1);
                        temp = temp ./ max(temp);
                        figure(123);cla();plot(temp(:,1:2:end)); drawnow
                    end

                    %% Safety backup after each video export
                    assignin('base', 'analysis_temp_backup', analysis);
                end
            end 
        end
               
        if display
            first_tp_of_exp = analysis.experiments(exp_idx).t_start; 
            %try
                plot_MIs(analysis.experiments(exp_idx).recordings, first_tp_of_exp, manual_browsing, '', true);
            %end
        end
    end
    
end
% 
% function cleanMeUp()
%     %% prevent crash in case of interrupt
%     global analysis_complete
%     if ~analysis_complete
%         error('ctrl-C captured')
%     end
% end 