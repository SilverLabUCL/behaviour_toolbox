# Video

The Video class contains information relative to a specific Video recording, such as the video path and the timestamps. It can contain one or several ROIs

## Hierarchy

[Analysis_Set](Analysis_Set.md)< [Experiment](Experiment.md) < [Recording](Recording.md) < Video

## Add/Delete Video object

If you use the complete pipeline, you usually don't have to manually update videos, as this is handled automatically when populating an experiment. If you had too, here are some basic commands.

```matlab
%% Add a recording with 5 empty Video objects to an existing experiment
my_analysis.experiments(1).recordings(end+1) = Recording(5)

%% Add a Video to a recording
my_analysis.experiments(1).recordings(1).videos(end+1) = Video('', 'some/video/path.avi')

% Remove one video in this specific recording
a_recording.video.pop(1);

%% Create a standalone video object manually
v = Video(0, "some_top_folder\expe_folder\yyMMdd_hh_mm_ss VidRec\yyMMdd_hh_mm_ss VidRec\BodyCam-1.avi")
```

Get the properties of the video

Recordings have a few methods collecting properties from lower classes (Video and ROI).

```matlab
%% Print recording paths for a specific recording
my_analysis.experiments(1).recordings(1).videos(1).path

%% Print video type
my_analysis.experiments(1).recordings(1).videos(1).video_types

%% Get Video sampling rate
my_analysis.experiments(1).recordings(1).videos(1).path.sampling_rate

%% Get t_stop of all videos in a recording
% Before printing it, make sure Video.set_timestamps() was called once for each video. This is usually done if you extracted some MIs. Otherwise, use Recording.update(true) method.
cellfun(@(x) x(end), {my_analysis.experiments(1).recordings(1).videos.timestamps})
```



## Plot MIs

You can get display the motion indexes for a given video

```matlab
vid = my_analysis.experiments(1).recordings(1).videos(1)

%% Simplest plot for a single recording
vid.plot_MIs()

%% Plot in defined figure
vid.plot_MIs(5)

%% Plot each ROI in a different subplot
vid.plot_MIs('', true)

%% Plot normalized MI
vid.plot_MIs('', '', true)

%% Capture the output (one cell per videotype)
[data, time] = vid.plot_MIs();
```

