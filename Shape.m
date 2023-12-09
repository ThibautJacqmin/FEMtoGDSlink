classdef Shape < matlab.mixin.Copyable
    properties
        points (:, 2) double
    end
    methods
        function obj = Shape
        end
        function translate(obj, vector)
            obj.points = obj.points+repmat(vector, 4, 1);
        end
        function plot(obj)
            pts = [obj.points; obj.points(1,:)];
            plot(pts(:, 1), pts(:, 2));
        end
        function y = npoints(obj)
            y = size(obj.points, 1);
        end
    end
end
