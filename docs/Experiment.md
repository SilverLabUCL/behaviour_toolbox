# Experiment

The Experiment class contains all the recordings contained in an "experiment" folder. An experiment is defined by a series of recordings where the animal was in the same configuration, and where we assume that we can compare the video coming from these recordings. For example, if you change the animal, or if you moved / reposition significantly the animal or the cameras, you should consider changing the "Experiment". 

As a rule of thumb, if you can use the same ROIs throughout the experiment, you can consider it an unique "experiment". Small camera movements can be handled using some offsets.

## Hierarchy

[Analysis_Set](Analysis_Set.md) < Experiment

## Add/Delete and Populate experiments

```matlab
%% Populate the first experiment of your Analysis_Set
my_analysis 	= Analysis_Set();
experiment_path = '/Some/top/folder/2020-01-01/experiment_1/';

% Method 1 (recommended) : Add/Update an experiment and auto-populate
% idx returns the experiment number.
% If the experiment already exists, it is updated
% If the experiment is new, we create a new one at index end+1
idx = my_analysis.add_experiment(experiment_path)

% Method 2 : populate an experiment at a known index
my_analysis.experiments(1).populate(experiment_path); %

% Method 3 : Append a new experiment at the end and populate manually
% Note, With this method you can create a duplicated experiment
my_analysis.experiments(my_analysis.n_expe+1) = Experiment('', experiment_path);
my_analysis.experiments(end).populate();

%% Delete experiments # 2
my_analysis.pop(2);
```



## Manipulate Recordings in an experiment

```matlab
%% Select a set of recordings in one experiment
subset = my_analysis.experiments(1).recordings([2,6,9]);

%% Select Recording in several experiments
subset = {my_analysis.experiments([2,4]).recordings};

%% Select a scalar property in the first recording of several experiments
my_set = arrayfun(@(x) x.recordings(1).n_vid, analysis.experiments([2,4]));

%% Select a non-scalar in the first recording of several experiments
rec_1_paths = arrayfun(@(x) x.recordings(1).path, [my_analysis.experiments([2,4])], 'UniformOutput', false)';

%% Remove empty recordings and sort recordings alphabetically
my_analysis.experiments(1).cleanup();

%% Get the number of recordings in experiment # 1
my_analysis.experiments(1).n_rec

%% Delete a recording # 6 (will be added again if you repopulate the experiment)
my_analysis.experiments(1).pop(6)

%% Remove empty Recordings in Experiment # 1, and sort alphabetically
my_analysis.experiments(1).cleanup();

%% Same as above + clear folders that were removed
my_analysis.experiments(1).cleanup(true);
```



## Get summary properties in an Experiment 

Some get() methods will return list of the properties available across all the recordings of an experiment. Most of the information is available only after you selected ROIs or extracted MIs in the different recordings of the experiment

```matlab
%% List all the types of video in experiment # 1
% Note : some recordings my not have all the videos
my_analysis.experiments(1).videotypes

%% List all the ROI labels already set in the experiment
% Note : empty until you selected them
my_analysis.experiments(1).roi_labels

%% List all the Reference images, per video, recording
% Note : empty until you selected them
my_analysis.experiments(1).global_reference_images

%% List t_start for the experiment
% Note : Only available after the first MI extraction
my_analysis.experiments(1).t_start
```



## Data Analysis

### Set ROIs

If you want to position / update ROIs for a specific experiment or a know set of experiments. 

```matlab
%% Setup all ROIs for a specific experiment
my_analysis.experiment(1).select_ROIs()

%% Setup ROIs for a set of experiment
my_analysis.experiment([1, 4]).select_ROIs()
```

For filtering using experiment paths, see [Analysis_set.select_ROIs](Analysis_Set.md#Set-ROIs)

### Extract MIs

You can extract all the motion indexes at once once the ROI location was defined

```matlab
%% Analyse all un-analysed ROIs for experiment 1
my_analysis.experiments(1).analyse()

%% Analyse all ROIs, reanalyse the ones that were already extracted
my_analysis.experiments(1).analyse(true)

%% Display result for experiment 1
my_analysis.experiments(1).analyse('', true)
```

### Plot MIs

Once extracted, you can display motion indexes

```matlab
%% Display MIs for experiment 6
my_analysis.experiments(6).plot_results()

%% Display MIs for experiment 3 and 4
my_analysis.experiments([3, 4]).plot_results()

%% Get MI values
[MIs, time] = my_analysis.experiments(1).plot_results()

%% Plot MIs in figure 6 and 7. (you need to provide the same number of idx as the mumber of videotypes)
my_analysis.experiments(1).plot_results([6, 7])

%% Plot against absolute time
my_analysis.experiments(1).plot_results('', false)

%% Pause between plots, until figure is closed
my_analysis.experiments(1).plot_results('', '', true)

%% Display only Eye Cam
my_analysis.experiments(1).plot_results('', '', '', 'Eye')

%% Apply a small filter
my_analysis.experiments(1).plot_results('', '', '', '', @(x) movmedian(x, 3))

%% Prevent regrouping ROis with the same name
analysis.experiments(3).plot_results('', '', '', '', '', false)

%% Filter specific ROIs
analysis.experiments(3).plot_results('', '', '', '', '', '', {'Whisker', 'Tail'})
```

