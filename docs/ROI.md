# ROI

The ROI class contains information relative to a specific ROI, and any data extracted from this ROI, such as Motion indexes. 

## Hierarchy

[Analysis_Set](Analysis_Set.md)< [Experiment](Experiment.md) < [Recording](Recording.md) < [Video](Video.md) < ROI

## Add/Delete ROI object

```matlab
%% Create a Video with 5 ROIs
my_analysis.experiments(1).recordings(1).videos(1) = Video(5);

%% Add an extra empty ROI
my_analysis.experiments(1).recordings(1).videos(1).add_roi(1)

%% Delete ROI 2 and 4
my_analysis.experiments(1).recordings(1).videos(1).pop([2, 4])

%% Delete ROI names 'Whisker'
my_analysis.experiments(1).recordings(1).videos(1).clear_MIs('Whisker', true)
```

### Position ROI

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
roi = my_analysis.experiments(1).recordings(1).videos(1).rois(1)

%% Simplest plot for a single roi
roi.plot_MI()

%% Capture the output
[~, MI] = roi.plot_MI()

%% Plot MI in figure 10
[~, MI] = roi.plot_MI(10)

%% Plot normalized MI
[~, MI] = roi.plot_MI('', true)
```

