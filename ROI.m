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
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

