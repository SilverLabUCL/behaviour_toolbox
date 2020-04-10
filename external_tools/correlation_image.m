function Cn = correlation_image(Y,~,~,~)

% construct correlation image based on neighboing pixels
% Y: raw data
% sz: define the relative location of neighbours. it can be scalar, 2
%       element vector or a binary matrix
%       scalar: number of nearest neighbours, either 4 or 8, default 4
%       2 element vector: [rmin, rmax], the range of neighbours. the
%           distance between the neighbour and the pixel is d, dmin <= r <
%           dmax.
%       matrix: a squared matrix (2k+1)*(2k+1)indicating the location of neighbours
% d1,d2: spatial dimensions
% flag_norm: indicate whether Y has been normalized and centered ( 1 is
%   yes, 0 is no)
% K:  scalar, the rank of the random matrix for projection

% Author: Eftychios A. Pnevmatikakis, Simons Foundation, 2015
% with modifications from Pengcheng Zhou, Carnegie Mellon University, 2015.
% It uses convolution and random projection for speeding up the
% computation.

    %% preprocess the raw data
    sz = [0,1,0; 1,0,1; 0,1,0];

    % center data 
    Y = bsxfun(@minus, double(Y), nanmean(Y, ndims(Y))); 
    [d1, d2, ~] = size(Y);

    sY = sqrt(nanmean(Y.*Y, ndims(Y)));
    %sY(sY==0) = 1; % avoid nan values
    Y = bsxfun(@times, Y, 1./sY);

    %% construct a matrix indicating location of the matrix
%     sz = ceil(sz);
%     dmin = nanmin(sz); dmax = nanmax(sz);
%     rsub = (-dmax+1):(dmax-1);      % row subscript
%     csub = rsub;      % column subscript
%     [cind, rind] = meshgrid(csub, rsub);
%     R = sqrt(cind.^2+rind.^2);
%     sz = (R>=dmin) .* (R<dmax);

    %% compute the correlation
    Yconv = imfilter(Y, sz);        % sum over the neighbouring pixels
    MASK = imfilter(ones(d1,d2), sz);   % count the number of neighbouring pixels
    Cn = nanmean(Yconv.*Y, 3)./MASK;   % compute correlation and normalize
    
%     Cn(Cn == 0) = NaN;
%     fact = nanmean([nanmean(Cn(:,1)) / nanmean(Cn(:,2)), nanmean(Cn(:,end)) / nanmean(Cn(:,end-1))]);
%     Cn(:,1) = Cn(:,1) / fact;
%     Cn(:,end) = Cn(:,end) / fact;   
end
