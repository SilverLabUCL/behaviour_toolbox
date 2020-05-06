classdef ROI
    %EXPERIMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        n_ROI
        ROI_location
        motion_index
        motion_index_norm
        name
    end
    
    methods
        function obj = ROI()
            obj.ROI_location    = [];
            obj.motion_index    = [];
            obj.name            = [];
        end
        
        function motion_index_norm = get.motion_index_norm(obj)
            if ~isempty(obj.motion_index)
                motion_index_norm = obj.motion_index;
                motion_index_norm(:,1) = obj.motion_index(:,1) - prctile(obj.motion_index(:,1), 1);
                motion_index_norm(:,1) = motion_index_norm(:,1) ./ nanmax(motion_index_norm(:,1));
            end
        end
        
        function f = plot_MI(obj, fig_number, use_norm) 
            %% Selet RAW or norm data
            if nargin < 3 || isempty(use_norm)
                MI = obj.motion_index(:,1);
                optimal_y_lim = [min(MI) - range(MI)/20, max(MI) + range(MI)/20];
            else
                MI = obj.motion_index_norm(:,1);
                optimal_y_lim = [-0.05,1.05];
            end
            
            %% Set correct figure handle
            if ~isempty(obj.motion_index)
                if nargin < 2 || isempty(fig_number)
                    %% New figure
                    f = figure();hold on;plot(MI);
                    type = 1;
                elseif isa(fig_number, 'matlab.graphics.axis.Axes')
                    %% Subplot
                    f = fig_number;hold on;plot(MI);
                    type = 2;
                else
                    %% Set figure
                    f = figure(fig_number);hold on;plot(MI);
                    type = 1;
                end  
                
                %% Add info
                if type == 1
                    n_plot = numel(f.Children(end).Children);
                    if n_plot == 1
                        ylabel('Motion Index (A.U.)')
                        xlabel('Frames');
                        legend(obj.name)
                    else
                        f.Children(1).String{n_plot} = obj.name;
                    end
                else
                    ylabel(obj.name);
                    f.XAxis.Visible = 'off';
                end
                ylim(optimal_y_lim);
            end
        end
    end
end

