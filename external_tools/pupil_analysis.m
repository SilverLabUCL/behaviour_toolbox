%% Simplified verssion of Harsha's Pupil tracking.
% To detect pupil: threshold, find boundary and fit ellipse. Returns
% structure with pupil's boundary points, centroid and axis lengths of 
% fitted ellipse.
%
% A threshold is used to find all dark pixels, the largest connected dark
% component is kept (as the pupil), all holes are filled (for example to
% remove reflections inside the pupil, the edge of this object detected,
% and the edge points passed to fit_ellipse.m. The length of the short/long
% axis of the fitted ellipse, and the original centroid of the detected
% dark component are used as pupil size and location.
%
% -------------------------------------------------------------------------
% Model : 
%   pupilFit = pupil_analysis(file_path, rendering, thresh_factor, dark_prctile)
%
% -------------------------------------------------------------------------
% Inputs : 
%   file_path(STR path or analysis_params object)
%                         - an absolute or relative path pointing to a
%                         multipage image stack or a sequence of eye cam
%                         images. 
%
%   rendering(BOOL) - Optional - Default true
%                       If true, final result is shown
%
%   thresh_factor(FLOAT) - Optional - Default is 1.4:  
%                       Threshold for dark pixels
%
%   dark_prctile(FLOAT) - Optional - Default is 10
%                       ....
%
% -------------------------------------------------------------------------
% Outputs :
%   pupilFit (STRUCT ARRAY) with fields:
%       - Boundary   [Cell array]   (x,y) coordinates of the points forming
%                                   the boundary of the detected pupil -
%                                   used as input to fit_ellipse.m
%       - CentroidX  [NUM]          x coordinate of detected pupil object
%       - CentroidY  [NUM]          y coordinate of detected pupil object
%       - Threshold  [Scalar unit8] Threshold value used to detect pixels
%                                   darker than this as corresponding to
%                                   the pupil
%       - LongAxis   [NUM]          Length of long axis at each frame/image
%       - ShortAxis  [NUM]          Length of short axis at each frame/image
% -------------------------------------------------------------------------
% Extra Notes:
%
% Adapted from Harsha's code. For a more complete version, see
% https://github.com/SilverLabUCL/Harsha-old-code/tree/master/Behaviour_analysis
%
% uses fit_ellipse from 
% https://www.mathworks.com/matlabcentral/fileexchange/3215-fit-ellipse
% Conic Ellipse representation = a*x^2+b*x*y+c*y^2+d*x+e*y+f=0
% (Tilt/orientation for the ellipse occurs when the term x*y exists 
% (i.e. b ~= 0))
% -------------------------------------------------------------------------
% Author(s):
%   Harsha Gurnani, Antoine Valera
%    
% -------------------------------------------------------------------------
% Revision Date:
%   10-05-2019
%
% See also fit_ellipse, load_stack, save_stack
%

function pupilFit = pupil_analysis(file_path, rendering, thresh_factor, dark_prctile, ROI)
    %% Set Default inputs
    if nargin < 2 || isempty(rendering)
        rendering = false;
    end
    if nargin < 3 || isempty(thresh_factor)
        thresh_factor = 2;
    end
    if nargin < 4 || isempty(dark_prctile)
        dark_prctile  = 10;
    end

    %% Open stack
    if exist(file_path, 'file')
        data = mmread_light(file_path);
        nFrames = size(data, 3);
    end
    
    data = smoothdata(data, 3, 'movmedian', [20, 0]);
    
    if nargin >= 5 && ~isempty(ROI)
        ROI = round(ROI); ROI(ROI < 1) = 1;
        
        %% QQ ADD CHECK TO MAKE SURE ROI DOESNT SPAN FURTHER THAN VIDEO LIMIT
        
        data = data(ROI(2):ROI(2)+ROI(4),ROI(1):ROI(1)+ROI(3),:);
    end

    %% Initialisation
    [LongAxis, ShortAxis, EllipseAngle, A, B, X0, Y0] = deal(nan( nFrames, 1));
    PupilCentroid   = nan(nFrames, 2);
    PupilBoundary   = cell( nFrames,1);
    Threshold       = nan(nFrames, 1);
    

    if ischar(thresh_factor)
        template = nanmedian(data, 3);
        x = floor(size(template, 1)/4);
        y = floor(size(template, 2)/4);
        template = template(x:end-x,y:end-y);
        Threshold(:) = prctile(template(:), 5);
        %figure();imagesc(template);
        thresh_factor = 1.4;
    end
        
    
%     dark_prctile = 1;
%     thresh_factor = 1.5;
%     
%     figure(123);cla();
%     s1 = subplot(1,2,1); hold on;
%     im1 = imagesc(data(:,:,1)); axis image;
%     set(gca, 'YDir','reverse')
%     s2 = subplot(1,2,2); hold on;
%     im2 = imagesc(data(:,:,1)); axis image;
%     set(gca, 'YDir','reverse')
%     for frame = 1:nFrames
%         curr_image = data(:,:,frame);
%         Threshold( frame )  = thresh_factor * prctile(curr_image(:), dark_prctile);
%         pupil               = curr_image < Threshold(frame);
%         pupil               = bwareafilt(pupil, 1);       % keep largest connected dark component
%         pupil               = imfill( pupil, 'holes' );
%         
%         im1.CData =  pupil;
%         im2.CData =  data(:,:,frame);
%         pause(0.001);
%     end

    %% Run parallel on all frames
    parfor frame = 1:nFrames
        %% For each frame
        curr_image = data(:,:,frame);

        %% Identify pupil
        if isnan(Threshold( frame ))
            Threshold( frame )  = thresh_factor * prctile(curr_image(:), dark_prctile);
        end
        pupil               = curr_image < Threshold(frame);
        pupil               = bwareafilt(pupil, 1);       % keep largest connected dark component
        pupil               = imdilate( pupil, strel('disk', 3));
        pupil               = imerode( pupil, strel('disk', 3));
        pupil               = imfill( pupil, 'holes' );

        [ally, allx] = find(pupil);  
        PupilCentroid(frame,:) = [mean( allx ), mean(ally)]; 

        tmp = edge(pupil);
        [ PupilBoundary{ frame }(:,2), PupilBoundary{ frame }(:,1)] =find( tmp ); 
        pupil_ellipse = fit_ellipse( PupilBoundary{frame}( :,1), PupilBoundary{frame}( :,2) );
        LongAxis( frame) = pupil_ellipse.long_axis;    ShortAxis(frame) = pupil_ellipse.short_axis;
        A(frame)         = pupil_ellipse.a;            B(frame)         = pupil_ellipse.b;
        X0(frame)        = pupil_ellipse.X0;           Y0(frame)        = pupil_ellipse.Y0;
        EllipseAngle(frame) = pupil_ellipse.phi;
    end

    pupilFit = struct(  'LongAxis',     mat2cell(LongAxis, nFrames), ...
                        'ShortAxis',    mat2cell(ShortAxis, nFrames), ...
                        'CentroidX',    mat2cell(PupilCentroid(:,1), nFrames), ...
                        'CentroidY',    mat2cell(PupilCentroid(:,2), nFrames), ...
                        'Boundary',     mat2cell(PupilBoundary, nFrames), ...
                        'Threshold',    mat2cell(Threshold, nFrames), ...
                        'EllipseAngle', mat2cell(EllipseAngle, nFrames),...
                        'X_A',          mat2cell(A, nFrames), ...
                        'Y_B',          mat2cell(B, nFrames), ...
                        'X0',           mat2cell(X0, nFrames), ...
                        'Y0',           mat2cell(Y0, nFrames));

    %% Plotting
    if rendering
        nPlot           = min( 16, nFrames);
        Frames_to_plot  = sort(randperm(nFrames, nPlot-2));
        [~, m] = nanmin(LongAxis .* ShortAxis * pi);
        [~, M] = nanmax(LongAxis .* ShortAxis * pi);
        Frames_to_plot = [Frames_to_plot, m, M];

        figure(666);clf();
        colormap(gray)
        nr  = ceil(sqrt(nPlot) );
        for seq = 1:nPlot
            subplot(nr, nr, seq)
            frame = Frames_to_plot(seq);
            curr_image = data(:,:,frame);
            imagesc( curr_image ); hold on; axis image; hold on;
            scatter( PupilBoundary{ frame }(:,1), PupilBoundary{ frame }(:,2), 6, 'MarkerFaceColor','r', 'MarkerEdgeColor', 'r'); hold on;
            scatter( PupilCentroid( frame,1 ), PupilCentroid( frame,2 ), 'w', 'filled' );hold on;
            
            
%             a=A(frame); % horizontal radius
%             b=B(frame); % vertical radius
%             x0=X0(frame); % x0,y0 ellipse centre coordinates
%             y0=Y0(frame);
%             t=-pi:0.01:pi;
%             x=x0+a*cos(t);
%             y=y0+b*sin(t);
%             plot(x,y, 'g-');hold on;
            
            %ellipse( A(frame),B(frame),EllipseAngle(frame),X0(frame),Y0(frame),'b');
            title(['Frame ', num2str(frame)])
        end


        figure(667); cla(); hold on
        %plot( LongAxis , 'r-' ); hold on
        %plot( ShortAxis, 'b--' ); hold on
        plot( LongAxis .* ShortAxis * pi, 'r' );
    end
end