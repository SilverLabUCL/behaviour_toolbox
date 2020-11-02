# Analysis_Set

Analysis_Set Class is the container for all your experiments. It contains information about the location of your data, as well as some default properties.

Analysis_Set and all its children are handles. You can index them to simplify the code syntax. See [handle section](#About-handles).

### Start a new analysis and add experiments

```matlab
%% Create the Analysis Set
my_analysis = Analysis_Set();

%% Create the Analysis Set with Top folder path, and auto detect all experiments
my_analysis = Analysis_Set('/Top/Folder/path');
my_analysis.update(); % can take some time

%% Add a new preset name for ROIs to the default one
my_analysis.default_tags = [my_analysis.default_tags, {'New Preset'}];

%% Add 4 empty experiments (you can populate them later, see Experiment())
my_analysis.add_experiment(4);

%% Add/Update an experiments and populate with recordings
% idx returns the experiment number.
% If the experiment already exists, it is updated
% If the experiment is new, we create a new one at index end+1
idx = my_analysis.add_experiment('/Some/experiment/path/');

%% Delete experiments 1 and 3
my_analysis.pop([1,3]);

%% Delete all experiments done the 4th of december 2018
my_analysis.pop({'2018-12-04'});

%% Update a specific folder
my_analysis.update({'2018-12-04'});

%% Remove empty experiments and experiment with wrong path
% Note : Be careful if you moved the data on another drive/computer, as it may be detected as an incorrect path and removed. If you change computer see update_all_paths()
my_analysis.cleanup();
```

### Control general settings

#### Video_folder

Extraction of MI's rely on a correct path. If you move your files, you need to update video_folder, and the corresponding part in all its children.  An automated updated is attempted if you change the value, but may fail. If this is the case, you can manually fix it

```

```

#### Adjust tag list

When adding ROIs, a list of ROIs are automatically suggested. You can change this list at any time by changing the `default_tags` field

```matlab
%% Add a new Tag 'mouth'
my_analysis.default_tags = [my_analysis.default_tags, {'Mouth'}];
```

#### Ignore some folder when detecting videos

If you want to ignore some experiment folders, you can edit the exclusion list. 

```matlab
%% Ignore experiment from a specific day
my_analysis.folder_exclusion = [my_analysis.folder_exclusion, {'2018-12-04'}];
```

### About handles

All classes are handles, which means you can index them. 

```matlab
%% Start from a existing analysis
my_analysis.experiments(1).recordings(1).videos(1).rois(1).plot_result();

% Is equivalent to
my_expe = my_analysis.experiments(1);
my_expe.recordings(1).videos(1).rois(1).plot_result();

% Or to
my_roi = my_analysis.experiments(1).recordings(1).videos(1).rois(1);
my_roi.plot_result();
```

In the example above, any operation happening on `my_expe.recordings(1).videos(1).rois(1)` or on `my_roi`

actually happens to `my_analysis.experiments(1).recordings(1).videos(1).rois(1)`.

### Set ROIs

If you want to position / update ROIs for part or all experiments.

```matlab
%% Setup all ROIs
my_analysis.select_ROIs()

%% Setup ROIs for a specific experiment
my_analysis.select_ROIs('2018-12-05')
```

### Extract MIs

You can extract all the motion indexes at once once the ROI location was defined

```matlab
%% Analyse all un-analysed ROIs for all experiments
my_analysis.analyse()

%% Analyse all un-analysed ROIs for a subset of experiment using a filter
my_analysis.analyse('2018-12-05')

%% Analyse all ROIs, reanalyse the ones that were already extracted
my_analysis.analyse('', true)

%% Display result for each experiment
my_analysis.analyse('', '', true)

%% Display result for each experiment, but pause until window is closed
my_analysis.analyse('', '', 'auto')
```