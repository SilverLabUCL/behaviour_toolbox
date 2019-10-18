classdef ROI
    %EXPERIMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        n_ROI
        ROI_location
        motion_index
        name
    end
    
    methods
        function obj = ROI()
            obj.ROI_location    = [];
            obj.motion_index    = [];
            obj.name            = [];
        end
    end
end

