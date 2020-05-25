%% Correct file or folder path for consitency
% -------------------------------------------------------------------------
% Syntax: 
%   corrected_path = parse_paths(input_path);
% -------------------------------------------------------------------------
% Inputs:
%   input_path (STR) 
%                                   A path to a file or folder to adjust
%
%   for_printing (BOOL) 
%                                   if true, fix underscores for proper
%                                   display as figure titles etc...
% -------------------------------------------------------------------------
% Outputs:
%   corrected_path (STR) :
%                                   Same path as the input, but with
%                                   corrections (see extra notes)
% -------------------------------------------------------------------------
% Extra Notes:
% -------------------------------------------------------------------------
% Examples: 
%
% * Fix an incorrect folder path
%   corrected_path = fix_path('/some\\funny/path');
%   corrected_path --> '/some/funny/path/'
%
% * Fix a path to be displayed as a tile
%   f = figure();
%   corrected_path = fix_path('/some\\funny/path_to_file.something', true);
%   f.Title = corrected_path
%   corrected_path --> '/some/funny/path/path\_to\_file.something'
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
%   18-05-2020
%
% See also: 


function corrected_path = fix_path(input_path, for_printing)
    if nargin < 2 || isempty(for_printing)
        for_printing = false;
    end
    
    %% Make sure we have a cha and not a string
    input_path = char(input_path);
    
    %% If no input, no output
    if isempty(input_path)
        corrected_path = input_path;
        return
    end

    %% Make sure to detect the folder, not a file
    [test, file_if_any, ext] = fileparts(input_path);
    if isempty(ext) % When passing a folder, make sure we have a terminal '/' to avoid mixing up folder and files and getting hierarchy wrong by 1 level
        test        = [fileparts([input_path,'/']),'/'];
    else
        test        = [test, '/'];
        test        = [test, file_if_any, ext];
    end

    corrected_path = strrep(test,'\','/'); % Correct folder name for mac compatibility
	corrected_path = strrep(corrected_path,'//','/');
    if for_printing
        corrected_path = strrep(corrected_path, '_','\_');
    end
end