# Analysis_Set

Analysis_Set Class is the container for all your experiments. It contains information about the location of your data, as well as some default properties.

For now, the class is NOT a handle, which means you have to reassign the output of the object to itself.

```matlab
%% Create the Analysis Set
my_analysis = Analysis_Set();

%% Add a new preset name for ROIs to the default one
my_analysis.default_tags = [my_analysis.default_tags, {'New Preset'}];

%% Add 4 empty experiments
my_analysis = my_analysis.add_experiment(4);

%% Delete experiments 1 and 3
my_analysis = my_analysis.pop([1,3]);

```





