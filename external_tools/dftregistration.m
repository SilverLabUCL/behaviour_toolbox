%% Efficient subpixel image registration by crosscorrelation
% This code gives the same precision as the FFT upsampled cross correlation 
% in a small fraction of the computation time and with reduced memory 
% requirements. It obtains an initial estimate of the crosscorrelation peak
% by an FFT and then refines the shift estimation by upsampling the DFT
% only in a small neighborhood of that estimate by means of a 
% matrix-multiply DFT. With this procedure all the image points are used to
% compute the upsampled crosscorrelation.
% Manuel Guizar - Dec 13, 2007
%
% Rewrote all code not authored by either Manuel Guizar or Jim Fienup
% Manuel Guizar - May 13, 2016
%
% Citation for this algorithm:
% Manuel Guizar-Sicairos, Samuel T. Thurman, and James R. Fienup, 
% "Efficient subpixel image registration algorithms," Opt. Lett. 33, 
% 156-158 (2008).
%
% Added modifications from Eftychios A. Pnevmatikakis to include upper 
% bound on possible shifts - November 1, 2016 (see NoRMCorre)
%
% -------------------------------------------------------------------------
% Model : 
%   [output, Greg] = 
%       dftregistration(ref_FFT, target_FFT, upsamp_fact, extra_frame, 
%       phase_flag, min_shift, max_shift, corrections)
% -------------------------------------------------------------------------
% Inputs : 
%   ref_FFT(N * M INT OR N * M Complex) : 
%                                   Image or Fourier transform of reference 
%                                   image (use fft2(image)). 1 channel
%
%   target_FFT(N * M INT OR N * M Complex) : 
%                                   Image or Fourier transform of the image 
%                                   to correct (use fft2(image)). 1 channel
%
%   upsamp_fact(INT) - Optional - Default is 1:
%                                   Upsampling factor. Images will be 
%                                   registered to within 1/upsamp_fact of 
%                                   a pixel.For example upsamp_fact = 20 
%                                   means the images will be registered 
%                                   within 1/20 of a pixel.
%
%   extra_frame(N * M INT OR N * M Complex) - Optional - Default is '': 
%                                   Image or Fourier transform of the image 
%                                   to correct (use fft2(image)). 1 channel.
%                                   This can be another channel than the
%                                   one used for the ref, where we want to
%                                   apply the same correction
%
%   min_shift(INT or [INT, INT]) - Optional - Default is [-Inf, -Inf]:
%                                   Maximal autorized left/bottom offset 
%                                   (X and Y)
%
%   max_shift(INT or [INT, INT]) - Optional - Default is [Inf, Inf]:
%                                   Maximal autorized right/top offset 
%                                   (X and Y)
%
%   phase_flag(BOOL) - Optional - Default is false:
%                                   If true, phase shift is allowed.
%
%   corrections(1 * 5 FLOAT) - Optional - Default is []
%                                   If passed, the correction is applied
%                                   instead of measured. See output
%                                   
% -------------------------------------------------------------------------
% Outputs :
%
%   corrections([1 * 5] FLOAT)
%                                   - error
%                                           Translation invariant normalized
%                                           RMS error between f and g
%                                   - diffphase,
%                                           Global phase difference between 
%                                           the two images (should be
%                                           zero if images are non-negative).
%                                   - net_row_shift,
%                                           Pixel shifts between images
%                                   - net_col_shift
%                                           Pixel shifts between images
%                                   - CCmax
%                                           The CC Max value, used as a
%                                           score indication for the
%                                           quality of the correction
%
%   Greg (N * M * Ch INT) - Optional
%                                   Registered version of target_FFT, 
%                                   the global phase  difference is 
%                                   compensated for. Returns 2 channel if
%                                   extra_frame was passed.
%           
%
% -------------------------------------------------------------------------
% Extra Notes:
% Copyright (c) 2016, Manuel Guizar Sicairos, James R. Fienup, University of Rochester
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
%     * Neither the name of the University of Rochester nor the names
%       of its contributors may be used to endorse or promote products derived
%       from this software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
%
%
% Note for microscope_controller toolbox.
% Function was reformatted t match the rest of the toolbox style. Extra
% inputs were added to allow the correction of a second channel, and to
% allow the application of a precalculated correction
%
%
% Examples - How to: 
%
%  * Register an image with another, with 1/10th subpixel resolution 
%    [~, corrected_frame] = dftregistration(ref_frame, current_frame, 10);
%
%  * Register a 5D dataset with 1/100th subpixel resolution 
%    ref_frame = nanmax(params.data(:,:,:,:,1),[],4);
%    corrected = params.data;
%    for t = 1:size(params.data, 4)
%       current_frame = params.data(:,:,1,t,1);
%       other_frame = params.data(:,:,1,t,2);
%       [~,  corrected(:,:,1,t,:)] = dftregistration(ref_frame, ...
%                                    current_frame, 100, other_frame);
%    end
%    figure();subplot(1,2,1);new_ref = nanmax(corrected,[],4);imagesc(new_ref(:,:,1));hold on;axis image
%    subplot(1,2,2);imagesc(ref_frame);hold on;axis image
%
% -------------------------------------------------------------------------
% Author(s):
%   Manuel Guizar-Sicairos, James R. Fienup, Antoine Valera
%    
% -------------------------------------------------------------------------
% Revision Date:
%   03-12-2019
%
% See also register_ROI, do_mc_fastcorr, get_ROI_orientation_vectors,
%   measure_ROI 

%% TODO
% sort the issue when min_shift or max_shift are > Res / 2

function [corrections, Greg] = dftregistration(ref_FFT, target_FFT, upsamp_fact, extra_frame, phase_flag, min_shift, max_shift, corrections)

    if isreal(ref_FFT)
        ref_FFT = fft2(ref_FFT); % Make sure we use fft of the image
    end
    if isreal(target_FFT)
        target_FFT = fft2(target_FFT); % Make sure we use fft of the image
    end
    if nargin < 3 || isempty(upsamp_fact)
        upsamp_fact = 1;
    end
    if nargin < 4 || isempty(extra_frame)
        extra_frame = [];
    elseif isreal(extra_frame)
        extra_frame = fft2(extra_frame); % Make sure we use fft of the image
    end
    if nargin < 5 || isempty(phase_flag)
        phase_flag = false;
    end    
    if nargin < 6 || isempty(min_shift)
        min_shift = -Inf(1,2);
    elseif isscalar(min_shift)
        min_shift = min_shift * [1,1];        
    end
    if nargin < 7 || isempty(max_shift)
        max_shift = Inf(1,2);
    elseif isscalar(min_shift)
        max_shift = max_shift * [1,1];        
    end

    [nr,nc]=size(target_FFT);
    Nr = ifftshift(-fix(nr/2):ceil(nr/2)-1);
    Nc = ifftshift(-fix(nc/2):ceil(nc/2)-1);

    if nargin < 8 || isempty(corrections)
        if upsamp_fact == 0
            %% Simple computation of error and phase difference without registration
            CCmax = sum(ref_FFT(:).*conj(target_FFT(:)));
            row_shift = 0;
            col_shift = 0;
        elseif upsamp_fact == 1
            %% Single pixel registration
            buf_prod = ref_FFT.*conj(target_FFT);
            if phase_flag
                buf_prod = buf_prod./abs(buf_prod);
            end
            CC = ifft2(buf_prod);
            CCabs = sqrt(real(CC).^2 + imag(CC).^2);
            [row_shift, col_shift] = find(CCabs == max(CCabs(:)));
            if Nr(row_shift) > max_shift(1) || Nc(col_shift) > max_shift(2) || Nr(row_shift) < min_shift(1) || Nc(col_shift) < min_shift(2)
                CCabs2 = CCabs;
                CCabs2(Nr>max_shift(1),:) = 0;
                CCabs2(:,Nc>max_shift(2)) = 0;
                CCabs2(Nr<min_shift(1),:) = 0;
                CCabs2(:,Nc<min_shift(2)) = 0;
                [row_shift, col_shift] = find(CCabs == max(CCabs2(:)),1,'first');
            end    
            CCmax = CC(row_shift,col_shift)*nr*nc;
            
            %% Now change shifts so that they represent relative shifts and not indices
            row_shift = Nr(row_shift);
            col_shift = Nc(col_shift);
        elseif upsamp_fact > 1
            %% Start with upsamp_fact == 2
            buf_prod = ref_FFT.*conj(target_FFT);
            buf_pad = FTpad(buf_prod,[2*nr,2*nc]);
            if phase_flag
                buf_pad = buf_pad./(abs(buf_pad)+1e-10);
            end
            CC = ifft2(buf_pad);
            CCabs = abs(CC);%;sqrt(real(CC).^2 + imag(CC).^2);
            [row_shift, col_shift] = find(CCabs == max(CCabs(:)),1,'first');
            CCmax = CC(row_shift,col_shift)*nr*nc;
            
            %% Now change shifts so that they represent relative shifts and not indices
            Nr2 = ifftshift(-fix(nr):ceil(nr)-1);
            Nc2 = ifftshift(-fix(nc):ceil(nc)-1);
            if Nr2(row_shift)/2 > max_shift(1) || Nc2(col_shift)/2 > max_shift(2) || Nr2(row_shift)/2 < min_shift(1) || Nc2(col_shift)/2 < min_shift(2)
                CCabs2 = CCabs;
                if abs(max_shift(1)) < nr/2
                    CCabs2(Nr2/2>max_shift(1),:) = 0;
                end
                if abs(min_shift(1)) < nr/2
                    CCabs2(Nr2/2<min_shift(1),:) = 0;
                end
                if abs(max_shift(2)) < nc/2
                    CCabs2(:,Nc2/2>max_shift(2)) = 0;
                end
                if abs(min_shift(2)) < nc/2
                    CCabs2(:,Nc2/2<min_shift(2)) = 0;
                end
                [row_shift, col_shift] = find(CCabs == max(CCabs2(:)),1,'first');
            end

            row_shift = Nr2(row_shift)/2;
            col_shift = Nc2(col_shift)/2;
            
            %% If upsampling > 2, then refine estimate with matrix multiply DFT
            if upsamp_fact > 2
                %% DFT computation
                
                %% Initial shift estimate in upsampled grid
                row_shift = round(row_shift*upsamp_fact)/upsamp_fact; 
                col_shift = round(col_shift*upsamp_fact)/upsamp_fact;     
                dftshift = fix(ceil(upsamp_fact*1.5)/2); %% Center of output array at dftshift+1
                
                %% Matrix multiply DFT around the current shift estimate
                CC = conj(dftups(target_FFT.*conj(ref_FFT),ceil(upsamp_fact*1.5),ceil(upsamp_fact*1.5),upsamp_fact,...
                    dftshift-row_shift*upsamp_fact,dftshift-col_shift*upsamp_fact));
                
                %% Locate maximum and map back to original pixel grid 
                CCabs = abs(CC);%sqrt(real(CC).^2 + imag(CC).^2);
                [rloc, cloc] = find(CCabs == max(CCabs(:)),1,'first');
                CCmax = CC(rloc,cloc);
                rloc = rloc - dftshift - 1;
                cloc = cloc - dftshift - 1;
                row_shift = row_shift + rloc/upsamp_fact;
                col_shift = col_shift + cloc/upsamp_fact;    
            end

            %% If its only one row or column the shift along that dimension 
            %% has no effect. Set to zero.
            if nr == 1
                row_shift = 0;
            end
            if nc == 1
                col_shift = 0;
            end
        end  

        rg00 = sum(abs(ref_FFT(:)).^2);
        rf00 = sum(abs(target_FFT(:)).^2);
        error = 1.0 - abs(CCmax).^2/(rg00*rf00);
        error = sqrt(abs(error));
        diffphase = angle(CCmax);

        corrections = [error,diffphase,row_shift,col_shift,CCmax];
    else
        %% Just apply correction
        error       = corrections(1);
        diffphase   = corrections(2);
        row_shift   = corrections(3);
        col_shift   = corrections(4); 
        CCmax       = corrections(5); 
    end

    %% Compute registered version of target_FFT
    if (nargout > 1) && (upsamp_fact > 0)
        [Nc,Nr] = meshgrid(Nc,Nr);
        Greg = target_FFT.*exp(1i*2*pi*(-row_shift*Nr/nr-col_shift*Nc/nc));
        Greg = Greg*exp(1i*diffphase);
        Greg = abs(ifft2(Greg));
        
        if ~isempty(extra_frame)
            extra_frame = extra_frame.* exp(1i*2*pi*(-row_shift*Nr/nr-col_shift*Nc/nc));
            extra_frame = abs(ifft2(extra_frame * exp(1i*diffphase)));
            Greg = cat(3, Greg, extra_frame);
        end    
    elseif (nargout > 1) && (upsamp_fact == 0)
        Greg = target_FFT*exp(1i*diffphase);
    end

end

function out = dftups(in, nor, noc, upsamp_fact, roff, coff)
    % function out=dftups(in,nor,noc,upsamp_fact,roff,coff);
    % Upsampled DFT by matrix multiplies, can compute an upsampled DFT in just
    % a small region.
    % upsamp_fact         Upsampling factor (default upsamp_fact = 1)
    % [nor,noc]     Number of pixels in the output upsampled DFT, in
    %               units of upsampled pixels (default = size(in))
    % roff, coff    Row and column offsets, allow to shift the output array to
    %               a region of interest on the DFT (default = 0)
    % Recieves DC in upper left corner, image center must be in (1,1) 
    % Manuel Guizar - Dec 13, 2007
    % Modified from dftus, by J.R. Fienup 7/31/06

    % This code is intended to provide the same result as if the following
    % operations were performed
    %   - Embed the array "in" in an array that is upsamp_fact times larger in each
    %     dimension. ifftshift to bring the center of the image to (1,1).
    %   - Take the FFT of the larger array
    %   - Extract an [nor, noc] region of the result. Starting with the 
    %     [roff+1 coff+1] element.

    % It achieves this result by computing the DFT in the output array without
    % the need to zeropad. Much faster and memory efficient than the
    % zero-padded FFT approach if [nor noc] are much smaller than [nr*upsamp_fact nc*upsamp_fact]

    [nr,nc]=size(in);
    % Set defaults
    if exist('roff', 'var')         ~=1, roff=0         ;  end
    if exist('coff', 'var')         ~=1, coff=0         ;  end
    if exist('upsamp_fact','var')   ~=1, upsamp_fact=1  ;  end
    if exist('noc',  'var')         ~=1, noc=nc         ;  end
    if exist('nor',  'var')         ~=1, nor=nr         ;  end
    % Compute kernels and obtain DFT by matrix products
    kernc=exp((-1i*2*pi/(nc*upsamp_fact))*( ifftshift(0:nc-1).' - floor(nc/2) )*( (0:noc-1) - coff ));
    kernr=exp((-1i*2*pi/(nr*upsamp_fact))*( (0:nor-1).' - roff )*( ifftshift([0:nr-1]) - floor(nr/2)  ));
    out=kernr*in*kernc;
end


function imFTout = FTpad(imFT, outsize)
    % imFTout = FTpad(imFT,outsize)
    % Pads or crops the Fourier transform to the desired ouput size. Taking 
    % care that the zero frequency is put in the correct place for the output
    % for subsequent FT or IFT. Can be used for Fourier transform based
    % interpolation, i.e. dirichlet kernel interpolation. 
    %
    %   Inputs
    % imFT      - Input complex array with DC in [1,1]
    % outsize   - Output size of array [ny nx] 
    %
    %   Outputs
    % imout   - Output complex image with DC in [1,1]
    % Manuel Guizar - 2014.06.02

    if ~ismatrix(imFT)
        error('Maximum number of array dimensions is 2')
    end
    Nout = outsize;
    Nin = size(imFT);
    imFT = fftshift(imFT);
    center = floor(size(imFT)/2)+1;

    imFTout = zeros(outsize);
    centerout = floor(size(imFTout)/2)+1;

    % imout(centerout(1)+[1:Nin(1)]-center(1),centerout(2)+[1:Nin(2)]-center(2)) ...
    %     = imFT;
    cenout_cen = centerout - center;
    imFTout(max(cenout_cen(1)+1,1):min(cenout_cen(1)+Nin(1),Nout(1)),max(cenout_cen(2)+1,1):min(cenout_cen(2)+Nin(2),Nout(2))) ...
        = imFT(max(-cenout_cen(1)+1,1):min(-cenout_cen(1)+Nout(1),Nin(1)),max(-cenout_cen(2)+1,1):min(-cenout_cen(2)+Nout(2),Nin(2)));

    imFTout = ifftshift(imFTout)*Nout(1)*Nout(2)/(Nin(1)*Nin(2));
end


