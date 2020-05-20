# Analysis_Set

Analysis_Set Class is the container for all your experiments. It contains information about the location of your data, as well as some default properties.

For now, the class is NOT a handle, which means you have to reassign the output of the object to itself.

In an analysis set, you can add/remove experiments.

### Start a new analysis and add experiments

```matlab
%% Create the Analysis Set
my_analysis = Analysis_Set();

%% Create the Analysis Set with Top folder path, and auto detect all experiments
my_analysis = Analysis_Set('/Top/Folder/path');
my_analysis = my_analysis.update(); % can take some time

%% Add a new preset name for ROIs to the default one
my_analysis.default_tags = [my_analysis.default_tags, {'New Preset'}];

%% Add 4 empty experiments (you can populate them later, see Experiment())
my_analysis = my_analysis.add_experiment(4);

%% Add/Update an experiments and populate with recordings
% idx returns the experiment number.
% If the experiment already exists, it is updated
% If the experiment is new, we create a new one at index end+1
[my_analysis, idx] = my_analysis.add_experiment('/Some/experiment/path/');

%% Delete experiments 1 and 3
my_analysis = my_analysis.pop([1,3]);

%% Delete all experiments done the 4th of december 2018
my_analysis = my_analysis.pop({'2018-12-04'});

%% Update a specific folder
my_analysis = my_analysis.update({'2018-12-04'});

%% Remove empty experiments and experiment with wrong path
% Note : Be careful if you moved the data on another drive/computer, as it may be detected as an incorrect path and removed. If you change computer see update_children_paths()
my_analysis = my_analysis.cleanup();
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