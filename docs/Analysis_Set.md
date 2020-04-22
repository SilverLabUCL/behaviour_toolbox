# Analysis_Set

Analysis_Set Class is the container for all your experiments. It contains information about the location of your data, as well as some default properties.

For now, the class is NOT a handle, which means you have to reassign the output of the object to itself.

In an analysis set, you can add/remove experiments.

```matlab
%% Create the Analysis Set
my_analysis = Analysis_Set();

%% Create the Analysis Set with Top folder path, and auto detect all experiments
my_analysis = Analysis_Set(''/Top/Folder/path');
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

%% Remove empty experiments and experiment with wrong path
% Note : Be careful if you moved the data on another drive/computer, as it may be detected as an incorrect path and removed
my_analysis = my_analysis.cleanup();

```





