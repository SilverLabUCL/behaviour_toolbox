# Recording

The Recording class contains all the Videos acquired at the same time. Each video should start at the same time (Hardware trigger), although stop time may differ between videos. If you did several trials in a recording, you may have to discard inter-trial data.

## Hierarchy

Analysis_Set < Experiment < Recording

## Add/Delete Video

This should be done automatically when you populate an experiment. However, if you remove a video in a folder for example, you can make sure that the listing is correct.

```matlab
%% Select a set of recordings in one experiment
my_set = my_analysis.experiments(1).recordings([2,6,9]);

%% Print recording paths for the recordings above
{my_set.path}'

%% Refresh video list if you deleted a recording
a_recording = my_analysis.experiments(1).recordings(1);
a_recording = a_recording.update;

% Remove one video in this specific recording
a_recording = a_recording.pop(1);
```

Get the properties of the recordings videos

Recordings have a few methods collecting properties from lower classes (Video and ROI).

```matlab
%% Print recording paths for a specific recording
my_analysis.experiments(1).recordings(2).path

%% Print path of all videos in the recording
{my_analysis.experiments(1).recordings(2).videos.path}'

%% Get recordings paths for a selected set of recordings
{my_analysis.experiments(1).recordings([2,6,8]).path}'

%% Get video #1 paths for a selected set of recordings
my_set = arrayfun(@(x) x.videos(1).path, [my_analysis.experiments(1).recordings([2,6,8])], 'UniformOutput', false)';

%% Get all video paths for a selected set of recordings
my_set = arrayfun(@(x) {x.videos.path}, [my_analysis.experiments(1).recordings([2,6,8])], 'UniformOutput', false)';

```

Similar to the `videos.path` property above, and once extracted you can collect

`recordings.motion_indexes`

`recordings.reference_images`

`recordings.videos.ROI_location`

For example, if wanted to collect the ROIs coordinates from video # 2 in recordings # [1,2,6,8] of experiment # 6 :

```
my_ROIs = arrayfun(@(x) x.videos(2).ROI_location, [my_analysis.experiments(6).recordings([1,2,6,8]])], 'UniformOutput', false)
```

