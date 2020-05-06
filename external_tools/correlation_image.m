%% Compute Correlation image along 3rd Dimension
% -------------------------------------------------------------------------
% Model : 
%   corr_im = correlation_image(input_3D_data)
% -------------------------------------------------------------------------
% Inputs : 
%   input_3D_data([N x M x O]):
%                                   3D Input data. Correlation image
%                                   calculated along the 3rd dimension
% -------------------------------------------------------------------------
% Outputs :
%  corr_im([NxM]) single array 
%                                   Correlation image
% -------------------------------------------------------------------------
% Extra Notes:
%
% * Modified from Eftychios t al.:
%   Author: Eftychios A. Pnevmatikakis, Simons Foundation, 2015
%   with modifications from Pengcheng Zhou, Carnegie Mellon University, 2015.
%   It uses convolution and random projection for speeding up the
%   computation.
% -------------------------------------------------------------------------
% Author(s):
%   Eftychios A., Pengcheng Zhou
%    
% -------------------------------------------------------------------------
% Revision Date:
%   06-05-2020
%
% See also 

function corr_im = correlation_image(input_3D_data)
    %% Preprocess the raw data
    sz              = [0,1,0; 1,0,1; 0,1,0];

    %% Center data 
    input_3D_data   = bsxfun(@minus, double(input_3D_data), nanmean(input_3D_data, ndims(input_3D_data))); 
    [d1, d2, ~]     = size(input_3D_data);

    sY              = sqrt(nanmean(input_3D_data.*input_3D_data, ndims(input_3D_data)));
    input_3D_data   = bsxfun(@times, input_3D_data, 1./sY);

    %% Compute the correlation
    Yconv           = imfilter(input_3D_data, sz);              % sum over the neighbouring pixels
    MASK            = imfilter(ones(d1,d2), sz);                % count the number of neighbouring pixels
    corr_im         = nanmean(Yconv.*input_3D_data, 3)./MASK;   % compute correlation and normalize 
end
