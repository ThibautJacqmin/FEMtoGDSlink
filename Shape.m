classdef Shape < matlab.mixin.Copyable
    properties
        points
    end
    methods
        function obj = Shape
        end
        function translate(obj, vector)
            obj.points = obj.points+repmat(vector, 4, 1);
        end
    end
end
