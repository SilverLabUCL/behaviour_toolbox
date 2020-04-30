





# Behaviour toolbox

This toolbox was created to streamline ROI selection for Video acquisition in the SilverLab. The general use case is the following one:

-   You recorded mouse behaviour using one or multiple camera.

-   You need to check all your many many videos, and select some ROI (for motion index, pupil tracking)
    
-   The location of these ROI is not exactly the same across days, so you need to do visual inspection

This toolbox will help go through all the video as fast as possible, easily manipulate/Select ROIs. The Results are stored in a database-like structure (see below). ROI location and other video info can be manipulated to do batch analysis. The only preparatory work required is to regroup the videos folders by day and experiments.

Setup and general information
=============================

Setup
-----

The current toolbox is in the private repository: <https://github.com/SilverLabUCL/behaviour_toolbox>

Please use the master branch, contact the Developers if you don't have access. 

Download the repository, and add the files to the matlab path. No other dependencies are required.

### Video Folder Pre-processing

The database uses the lab filename system to organize the results. Before starting, you must put all your video of interest together, in a same "top folder", and if possible, move all the video belonging to other experiments elsewhere, in another folder. The system uses the fact that videos taken during a same experiment point at the same location. Therefore, they must be regrouped by experiments.

The Video folders must be organized as follow:

```
/Top_folder/ (contains all the videos to monitor. Take irrelevant videos away)
├───/YYYY-MM-DD/
|   ├──/experiment_1/
|   |  ├─ /YYMMDD_HH_mm_ss VidRec/
|   |  ├─ /YYMMDD_HH_mm_ss VidRec/
|   |
|   ├──/experiment_2/
|   |  ├─ /YYMMDD_HH_mm_ss VidRec/
|
├───/yyyy-mm-dd/
       ├─ ...
```



Each LabVIEW video folder (*/YYMMDD_HH_mm_ss VidRec/* folder ) is expected to contain exported .avi videos. The LabVIEW export process will organised files as required, so do not move them around. In the following example, 3 camera were used.

```
.../YYMMDD_HH_mm_ss VidRec/
   ├───/YYMMDD_HH_mm_ss VidRec/
   |   | BodyCam-1.avi
   |   | BodyCam-relative times.txt 		% Unused
   |   | EyeCam-1.avi
   |   | EyeCam-relative times.txt 			% Unused
   |   | WhiskersCam-1
   |   | WhiskersCam-relative times.txt 	% Unused
   |   |
   | BodyCam-relative times.txt
   | EyeCam-relative times.txt
   | WhiskersCam-relative times.txt
```



> Note: an "experiment" is defined by a series of consecutive video recordings where ROIs will be identical. Some computation will be shared between videos of the same experiment, using the same ROI location across the recordings, which means the camera must not move. Camera offset can be corrected, however, if you changed the camera angle or zoom factor, you will have to split the experiments in 2.
>

General data structure
----------------------

The data is organized following a hierarchical structure. Each level is defined by a Class, with its own methods and dynamic properties. Click on the classes to see more details about properties and methods.

[`Analysis_Set`](Analysis_Set.md) 		: The container for all your experiments

[`Experiment`](Experiment.md) 			: Each Experiment contains multiple recordings

[`Recording`](Recording.md)               : Each Recording contains multiple videos

`Video`

`ROI`

Each parent structure can list its children properties. See Class documentation, or use cases at the end of the documentation for more details.

First run and database initialization
=====================================

Initialise the toolbox
----------------------

Start the GUI by typing

`Behaviour_analysis();`

This will open the GUI.

![](./media/image1.png)

Start a new analysis:
---------------------

Click on the [Start New Analysis] button. This would clear any existing dataset.

![](./media/image2.png)
Select the folder containing all your video ("Top\_folder"), as described before. All valid videos in this folder will be listed. This may take some time, in particular if the videos are on a remote server. After this step, a local copy of the folder path is stored, which speed up data manipulation. If you change the content of the video folder, you will need to refresh this list. See [Updating Source]().

Please keep an eye at the messages printed during this initial listing, as they could indicate problematic videos. The toolbox does not support split videos (yet).

Once finished, you should see an updated GUI.

> Note : As this step can be very long, it is recommended to save your database once the list was generated. See [backup analysis](#Backup-Analysis)
>

Backup Analysis
===============

Manual backup
-------------

As some steps can be extremely time consuming, it is recommended to do some regular backup of your analysis database. To do so, click on the [Save Analysis] Button.

![](./media/image3.png)
An automated filename with a timestamp is proposed, but you can edit it.

Manual Reload
-------------

If you resume a previous analysis, or if something went wrong and you want to return to a previous stage, you can use the [Load Existing Analysis] button and reload one of the '.mat' file used for backup.![](./media/image4.png)

Recover from interrupted analysis
---------------------------------

When extracting motion indices, you may interrupt your MI extraction. An error could also emerge from a server connection issue, or a corrupted recording. If this happens, you can restore to the last valid state by
clicking on the [Recover interrupted analysis] button:

 ![](./media/image5.png)

> Note : After doing this, you should immediately backup the database.

Auto saving
-----------

Temporarily disabled. See Recover from interrupted analysis.

Browse Data and Database
========================

Data selection
--------------

The experiment section lists the experiment available in the "top folder". You can select or multiple experiments at once.

![](./media/image6.png)

Any data extraction will be done on the current selection.

The recordings listed in the selected experiments are displayed on the left

![](./media/image7.png)

-   '*Eye*', '*Body*' and, '*Whisker*' columns indicated the availability of the videos. In the example above, the recording 17-27-01 only have a WhiskerCam recording, while other recordings have all video recordings.
    
-   The *selected MI* column indicates how many ROIs were selected for each video.
    
-   The *analysed* column indicates if the motion indices were all analysed or not.

Open Video/Open folder
----------------------

You can select a specific video, or open its containing folder by clicking on the [Open Video] or [Open Folder] buttons. For video, the selcted video is opened. For folders, the containing folder is opened.

![](./media/image8.png)


![](./media/image9.png)


Updating Database
-----------------

If you added or deleted folders, you can click on  the [Refresh File List] Button.
![](./media/image10.png)

Existing analysis will be kept, new files will be added (in alphabetical order) and deleted folders will be removed.

> Note : This process will take as long as the initial listing, which can last seconds to minutes depending on the location and number of the files.

In the rare case where you (re)-add videos in an experiment where ROIs were already selected, you need to regenerate Motion Indices for all recordings by clicking on the [Select/Browse ROIs] Button again. The Missing MIs will be calculated next tie you click on the [Show/Analyze] button. 

Select ROIs
===========

Now that the files were listed, you can select the location of the ROIs. The process is done for all the selected *experiments*. ROIs are the same for all videos of a given experiment (unless there is missing video), although an offset can be applied to all ROIs if the camera moved.
For example, if you select an experiment that has recordings with the *EyeCam* and the *BodyCam*, you will have to select the location of you ROIs for each one of this video, but only once for the full experiment.

To select ROIs : Click on the [Select/Browse ROIs] button.
![](./media/image11.png)

ROIs you already selected will be displayed. New ROIs can be added, and old ROIs can be removed.

Quick Selection
---------------

![](./media/image12.png)

Preset names are displayed on the left. The list is extracted from the propertiy `behaviour_GUI.Experiment_set.default_tags`. You can edit this list to add/remove quick tags.

Manual Addition
---------------

You can also do a right click on the image to add an ROI. Roi will be named in order of selection

![](./media/image13.png)

![](./media/image14.png)


Editing ROIs
------------

ROIs being added have they name in red. A right click on the ROI allow you to delete it.

![](./media/image15.png)

![](./media/image16.png)

Type the "return" key to validate and move to the net camera / next experiment. Once done on your selection, if you click on the [select/Browse ROIs] button again, the previously selected ROIs will be displayed in yellow.

![](./media/image17.png)

Once selected, the number of ROIs in the selection is displayed in the table.

![](./media/image18.png)

Analysis
========

Once defined, you can calculate motion index for each ROI. Select the experiment/Group of experiment to process in the "experiments" column, then click on the [Show/Analyze] button.![](./media/image19.png)


This will start the analysis process. Videos that had all their Motion Index calculated are skipped, but if
any new MI was added, we recalculate all MIs.

If required, you can force the recalculation of MIs for all videos at any time by ticking the [Recaluclate all] checkbox:

![](./media/image20.png)

For each video, the analysis progress is displayed in the command. 

![](./media/image21.png)

Note : Most of the time is taken by video loading. To speed up the analysis, it is recommended to have files on a local, fast drive (eg. SSD drive).

Once all MIs are calculated, checkboxes in the *analysed* column are ticked.

![](./media/image22.png)

Updating Motion Indexes
=======================

Update a set of MIs
-------------------

If you already analysed an experiment/Group of experiments but want to check the position of the existing ROIs, proceed as follow:

-   Highlight the experiment to check. You can select or or multiple experiments

![](./media/image23.png)

The individual recordings are displayed on the experiment window

-   Browse the experiments![](./media/image24.png)
    
-   ROIs that were analysed are displayed in green. These ROI were already extracted.

![](./media/image25.png)

If you move/resize a green ROI, the label will turn yellow, indicating that a new MI extraction will be necessary.

![](./media/image26.png)

After validating the change (i.e. after closing the window), the analysed checkbox will be unchecked, indicating that reanalysis is required.

> Note : If you move the Motion index on the consensus frame, the ROI is moved accordingly for all videos in that experiment

Correct for camera movement
---------------------------

During an experiment, you may have camera movement. You have the possibility to introduce and offset for all ROIs. ROIs will all have the same offset for a given video. ROI size cannot be changed during recordings

To correct for camera displacement, you must first specify ROI location in the consensus frame. When the camera moves, the consensus frame may be blurry or show multiple ghost images, due to a camera offset. The ROIs should be correct for the beginning of the experiment.

![](./media/image27-1587374845677.png)

You can use the slider at the bottom of the figure to move across the recordings. The first position of the slider corresponds to the consensus frame, while the following ones correspond to each video of the recording.

![](media/Documentation/image28-1587374845677.png)

For example, the ROIs were selected correctly for the first recording :

![](media/Documentation/image29-1587374845678.png)

However, a later video displays an offset:

![](media/Documentation/image30-1587374845678.png)

You can drag the ROIs (which will move together) to the correct location.

![](media/Documentation/image31-1587374845678.png)

Note: The offset is automatically applied to all the following recordings, although you can set a second different offset on a later video (which will, in turn, be applied to all the subsequent video. See example below. In **bold**, we indicate the only video that actually needed a manual intervention.

| video | Mean frame | rec1 | rec2 | rec3 | rec4 | rec5 | rec6 | … | rec_N |
|:------:|:---------------:|:-----:|:-----:|:-------:|:-------:|:-------:|:-------:|:-------:|:-------:|
| offset | **[0,0]** | [0,0] | [0,0] | **[10,20]** | [10,20] | [10,20] | **[40,15]** | [40,15] | [40,15] |

> Note : Offsets are applied relative to the first frame (Mean Frame). Similarly, ROI size are defined in the Mean Frame. DO NOT add/remove/resize ROIs in the other frames (here, in rec1 to rec_N). You should only adjust for offsets in those.

You can clear all offset (if you are on the reference frame), or all offsets starting from the current recording (if you are on any other frame than the reference one) by clicking on the [Clear Offsets] button

![image-20200430102810160](media/Documentation/image-20200430102810160.png)




Display MIs
---------------------

### For the current recording

When selecting the ROIs, you can have a preview of the signal obtained from the current ROIs by clicking on the [Measure MIs] button

![image-20200430102958106](media/Documentation/image-20200430102958106.png)

Note than Motion indexes are not saved to the database when using preview. They will be extracted only when clicking on the [Show/Analyze] button.

### For the whole experiment, after extraction

If you extracted all Motion indices, you should see a figure like this

![](media/image32.png)

For each MI, a plot of the whole experiment is displayed (time in seconds). Grey areas indicate gaps between recordings.

If you extracted multiple ROIs, you will see multiple subplot.

![](./media/image33.png)

> Note : if you want to pause the display between each Camera, tick the [Pause for each experiment] checkbox
>

![image-20200430101637948](media/Documentation/image-20200430101637948.png)

Videos that were not extracted will still be analysed, so it is recommended to use this option only when all MIs were extracted, otherwise you may have to wait a long time when hitting an non-extracted recording.



Scripted analysis
=================

## Setting up a database and extracting ROIs

> Perquisite : you must have arranged your data as explained [here](#Video-Folder-Pre-processing)

### Initial set up

```matlab
%% Create database
my_analysis = Analysis_Set('C:\Users\vanto\Desktop\Video for Toolbox testing\');
my_analysis = my_analysis.update(); % list all experiments

%% Look at a few properties of experiment # 6
my_analysis.experiments(6).videotypes
>> ans =
      1×2 cell array
        {'BodyCam-1'}    {'EyeCam-1'}
        
my_analysis.experiments(6).n_rec
>> ans =
      3

```

### Select some ROIs

```matlab
%% Select ROIs for experiment # 6
% There are 2 videos types in this experiment,
% - We set 2 ROIs around whiskers in video 1
% - We set 1 ROIs around whiskers in video 2
my_analysis.experiments(6) = select_video_ROIs(my_analysis.experiments(6));

%% Look at a few properties of the ROIs we just selected
expe = my_analysis.experiments(6); % for display

%% We can look at the ROIs of recording # 2;
% First video has 2 ROIs
% Second video has 1 ROI
ROIS = {expe.recordings(2).videos.rois}
>> ROIS =
  1×2 cell array
    {1×2 ROI}    {1×1 ROI}

%% We can look at the propeties of the first ROI of video 1
roi = expe.recordings(2).videos(1).rois(1)
>> roi = 
     ROI with properties:
               n_ROI: []
        ROI_location: [585.0909 174.5455 20 20 7513]
        motion_index: {}
                name: 'Label # 1'

% ROI_location  
round(roi.ROI_location)
>> ans =
         [585, 175, 20, 20, 7513]; % xstart, ystart, width, height, id
% The id is identifying an ROI in case it has the same name.
% for example  
	expe.recordings(1).videos(1).rois(2).ROI_location(5)
 == expe.recordings(3).videos(1).rois(2).ROI_location(5)
>> ans =
  logical
   		1

% but, although they have the same name in this case, we can distinguish ROIs across recordings
	expe.recordings(1).videos(1).rois(1).ROI_location(5)
 == expe.recordings(1).videos(2).rois(1).ROI_location(5)
>> ans =
  logical
   		0


% Look at selected motion indices (one per ROI) for recording 2:
% First video has 2 MIs (because there were 2 ROIs)
% Second video has 1 MI (because there was 1 ROIs)
expe.recordings(2).motion_indexes
>> ans =
     1×2 cell array
        {1×2 cell}    {1×1 cell} 
        
```

### Extract Motion index

```matlab
%% To extract MI for a specific video
vid = my_analysis.experiments(6).recordings(2).videos(1); % for display purpose
vid = vid.analyze();

%% Plot MI for ROI # 2
figure();plot(vid.motion_indexes{2}(:,2), vid.motion_indexes{2}(:,1));
xlabel('time (ms)')
```



## Other use case for ROIs

You can extract the content of ROIs for other purposes, such as pupil tracking, or DeepLabCut.

For this example, we are starting from the video defined in the [previous section](#Extract-Motion-index) :

```matlab
%% Script 1 # 
function im = get_mean_proj(file_path_or_data, ROI)
    [~, video] = get_MI_from_video(file_path_or_data, '', '', ROI);
    im = nanmean(video{1}, 3);
end

vid = my_analysis.experiments(6).recordings(2).videos(1); % for display purpose
[~, im] = vid.analyze(@(~,~) get_mean_proj(vid.path, vid.ROI_location{1}));
figure();imagesc(im);axis image
```