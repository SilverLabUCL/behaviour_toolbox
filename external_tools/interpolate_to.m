%% Interpolate data along the longest axis to new size
%
% -------------------------------------------------------------------------
% Model : 
%   source = interpolate_to(source, n_points)
% -------------------------------------------------------------------------
% Inputs : 
%   source([N x M] matrix or Cell array of {[NxM]} matrices):
%                                   Input data
%
%   n_points(INT):
%                                   Final number of points required after
%                                   interpolation
% -------------------------------------------------------------------------
% Outputs :
%  source([N x M] matrix or Cell array of {[N x M]} matrices) 
%                                   Interpolated data. Interpolation is
%                                   done along the longest axis.
% -------------------------------------------------------------------------
% Extra Notes:
%
% -------------------------------------------------------------------------
% Author(s):
%   Antoine Valera   
% -------------------------------------------------------------------------
% Revision Date:
%   06-05-2020
%
% See also 


function source = interpolate_to(source, n_points)
    if n_points && ~isempty(source)
        
        %% Check if matrix or cell array
        was_mat = false;
        if ~iscell(source)
            %% Code uses cell arrays
            source = {source};
            was_mat = true;
        end
        
        %% Process
        for el = 1:numel(source)
            %% Flip input if necessary
            if size(source{el}, 2) < size(source{el}, 1)
                source{el} = source{el}';
            end
            if size(source{el}, 1) == 1
                source{el} = interp1(1:size(source{el}, 2),   source{el}',   linspace(1,size(source{el},2),n_points));
            else
                source{el} = interp1(1:size(source{el}, 2),   source{el}',   linspace(1,size(source{el},2),n_points))';
            end
        end 
        
        %% Restore matrix
        if was_mat
            source = cell2mat(source);
        end
    end
end