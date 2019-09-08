function video = mmread(filename)

    trySeeking = true;
    matlabCommand = '';
    disableAudio = nargout < 2;
    disableVideo = false;
    frames = [];

    fmt = '';
    FFGrab('build',filename,fmt,double(disableVideo),double(disableAudio),double(trySeeking));
    FFGrab('setFrames',frames);
    FFGrab('setMatlabCommand',matlabCommand);
    FFGrab('doCapture');

    [nrVideoStreams, nrAudioStreams] = FFGrab('getCaptureInfo');
    
   
    % loop through getting all of the video data from each stream
    for i=1:nrVideoStreams
        [width, height, rate, nrFramesCaptured, nrFramesTotal, totalDuration] = FFGrab('getVideoInfo',i-1);
        if (nrFramesTotal > 0 && any(frames > nrFramesTotal))
            warning('mmread:general',['Frame(s) ' num2str(frames(frames>nrFramesTotal)) ' exceed the number of frames in the movie.']);
        end

        video = zeros(height * width * 3, nrFramesCaptured, 'uint8');
        for f = 1:nrFramesCaptured
            [video(:,f), ~] = FFGrab('getVideoFrame',i-1,f-1);
            % the data ordering is wrong for matlab images, so permute it
        end
        video = permute(reshape(video(1:3:end,:), width, height, nrFramesCaptured),[2 1 3]); % WARNING -- Disabled channel 2 and 3 here
    end
    FFGrab('cleanUp');    
end
