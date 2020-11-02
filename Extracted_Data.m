%% Extracted_Data Class
% 	This the class containing info about Extracted_Data
%
%   Type doc Extracted_Data.function_name or Extracted_Data Class.function_name 
%   to get more details about the methods inputs and outputs.
% -------------------------------------------------------------------------
% Syntax: 
%   this = Extracted_Data();
% -------------------------------------------------------------------------
% Class Generation Inputs: 
% -------------------------------------------------------------------------
% Outputs: 
%   this (Extracted_Data object)
% -------------------------------------------------------------------------
% Class Methods (ignoring get()/set() methods):
% * 
% -------------------------------------------------------------------------
% Extra Notes:
% * Extracted_Data is a dynamicprops object. This means you cann add new
%   properties based on the data extraction process.
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
% 29-10-2020
%
% See also Analysis_Set, Experiment, Recordings, Video, ROI

classdef Extracted_Data < handle & dynamicprops
    properties
        parent_h                ; % handle to parent ROI object
        current_varname         ; % The metric currently used
        %function_used                   ; % a list of function used to extract the data
    end
    
    methods
        function obj = Extracted_Data(parent)
            %% ROI Object Constructor. 
            % -------------------------------------------------------------
            % Syntax: 
            %   this = Extracted_Data()
            % -------------------------------------------------------------
            % Inputs:
            % -------------------------------------------------------------
            % Outputs: 
            %   this (Extracted_Data)
            %   	The container for Extracted_Data in a given ROI
            % -------------------------------------------------------------
            % Extra Notes:
            % -------------------------------------------------------------
            % Examples:
            % -------------------------------------------------------------
            % Author(s):
            %   Antoine Valera. 
            %---------------------------------------------
            % Revision Date:
            %   29-10-2020
            %
            % See also:
            
            obj.parent_h            = parent;
        end
    end
end

