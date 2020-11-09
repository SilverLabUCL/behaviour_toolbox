%% ROI Class
% 	This the class containing info about ROI and ROI-extracted data
%
%   Type doc ROI.function_name or ROI Class.function_name 
%   to get more details about the methods inputs and outputs.
% -------------------------------------------------------------------------
% Syntax: 
%   this = ROI();
% -------------------------------------------------------------------------
% Class Generation Inputs: 
% -------------------------------------------------------------------------
% Outputs: 
%   this (ROI object)
% -------------------------------------------------------------------------
% Class Methods (ignoring get()/set() methods):
% * Plot Results for selected ROI using current variable
%   f = plot_result(obj, fig_number, use_norm) 
% -------------------------------------------------------------------------
% Extra Notes:
% * ROI is a handle. You can assign a set of ROIs to a variable
%   from a Video for conveniency and edit it. As a handle, modified 
%   variables will be updated in your original Video too
% -------------------------------------------------------------------------
% Examples:
% -------------------------------------------------------------------------
%                               Notice
%
% Author(s): Antoine Valera
%
% This function was initially released as part of a toolbox for 
% manipulating Videos acquired in the SIlverlab. The software was 
% developed in the laboratory of Prof Robin Angus Silver at University
% College London with funds from the NIH, ERC and Wellcome Trust.
%
% Copyright © 2015-2020 University College London
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%     http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License. 
% -------------------------------------------------------------------------
% Revision Date:
% 22-05-2020
%
% See also Analysis_Set, Experiment, Recordings, Video

classdef ROI < handle
    properties
        ROI_location            ; % [X Y width height id] coordinates of an roi
        extracted_data          ; % [N X 1] extracted roi info (data)
        function_used           ; % function used for extraction
        name                    ; % ROI name
        parent_h                ; % handle to parent Video object
        current_varname         ; % The metric currently used
    end
    
    methods
        function obj = ROI(parent)
            %% ROI Object Constructor. 
            % -------------------------------------------------------------
            % Syntax: 
            %   this = ROI()
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   this (ROI)
            %   	The container for a given ROI
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   20-05-2020
            %
            % See also:
            
            obj.ROI_location    = [];
            obj.name            = [];
            obj.parent_h        = parent;
            obj.extracted_data  = Extracted_Data(obj);
        end
        
        function [f, result] = plot_result(obj, fig_number, normalize) 
            %% Display and return results for current Recording
            % -------------------------------------------------------------
            % Syntax: 
            %   [fh, result] = Video.plot_results(fig_number, normalize)
            % -------------------------------------------------------------
            % Inputs:
            %   fig_number (INT or FIGURE HANDLE or AXIS HANDLE) - 
            %       Optional - default will use figure 1. If INT or figure
            %       handle, the corresponding figure is used. If you re
            %       buidling a subplot, then fig_number can be an AXIS
            %       HANDLE
            %
            %   normalize (BOOL) - Optional - default is false
            %   	If true, uses normalized result, otherwise used default result.
            % -------------------------------------------------------------
            % Outputs:            
            %   fh (Figure HANDLE) - 
            %   	current figure or axis handle (axis handle only if
            %   	fig_number was an axis handle itself
            %            
            %   result ([T x 2] MATRIX or [T x N] Matrix) - optional 
            %   	- By default, returns result and timescale for current ROI.
            %       Column 1 is the metric and column 2 is the timestamp 
            %       extracted when running the result extraction code.
            %       - If you run a custom function handle for extraction
            %       then all the data extracted is output.
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % * Plot result for current ROI
            %   ROI.plot_results()
            %
            % * Plot normalized result
            %   ROI.plot_results(true)
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   22-05-2020
            %
            % See also: Recording.plot_results         
            
            if nargin < 3 || isempty(normalize)
                normalize = false;
            end

            %% Get single or multiple extracted variable
            if numel(obj) == 1
                result = obj.extracted_data.(obj.current_varname)(:,1);
            else
                result = cell2mat(arrayfun(@(x) x.extracted_data.(obj.current_varname)(:,1), obj, 'UniformOutput', false));
            end
            
            %% Normalize variable if required
            if normalize
                result = result - prctile(result, 1);
                result = result ./ nanmax(result);
            end
            optimal_y_lim = [min(result(:)) - range(result(:))/20, max(result(:)) + range(result(:))/20];
            
            %% Set correct figure handle
            if ~all(arrayfun(@isempty ,obj))
                if nargin < 2 || isempty(fig_number)
                    %% New figure
                    f = figure();hold on;plot(result);
                    type = 1;
                elseif isa(fig_number, 'matlab.graphics.axis.Axes')
                    %% Subplot
                    f = fig_number;hold on;plot(result);
                    type = 2;
                else
                    %% Set figure
                    f = figure(fig_number);hold on;plot(result);
                    type = 1;
                end  
                
                %% Add info
                if type == 1
                    n_plot = numel(f.Children(end).Children);
                    if n_plot == numel(obj)
                        ylabel('Result (A.U.)')
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
            
            if nargout > 1
                result = [result, obj.parent_h.t];
            end
        end

        function extracted_data = get.extracted_data(obj)
            if ~isfield(obj.extracted_data, obj.current_varname) && ~isprop(obj.extracted_data, obj.current_varname)
                addprop(obj.extracted_data, obj.current_varname);
            end
            extracted_data = obj.extracted_data;
        end
        
        function current_varname = get.current_varname(obj)
            current_varname = obj.parent_h.parent_h.parent_h.parent_h.current_varname;
        end
        
        function set.current_varname(obj, current_varname)
            obj.parent_h.parent_h.parent_h.parent_h.current_varname = current_varname;
        end
    end
end

