function video_full = mmread_light(filename)

    trySeeking = true;
    matlabCommand = '';
    video_full = [];
    
    vidObj = VideoReader(filename);
    numFrames = ceil(vidObj.FrameRate*vidObj.Duration);
    batches = [1:1000:numFrames,numFrames+1]; %% FFGrab('doCapture') uses a lot of memory so we do batches of 1000 points

    for idx = 1:numel(batches(1:end-1))
        frames = batches(idx):(batches(idx+1)-1);
        fmt = '';
        FFGrab('build',filename,fmt,double(false),double(true),double(trySeeking));
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
        video_full = cat(3, video_full, video);
    end
end
