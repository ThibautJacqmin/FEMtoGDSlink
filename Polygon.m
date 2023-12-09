classdef Polygon < Shape
    methods
        function obj = Polygon(points)
            arguments
                points (:, 2) double
            end
            obj.points = points;
        end
    end
    methods (Hidden)
        function py_obj = get_python_obj(obj, pya)
            pts_list = py.list();
            for i=1:obj.npoints
                pts_list.append(pya.Point(obj.points(i, 1), obj.points(i, 2)));
            end
            py_obj = pya.Polygon(pts_list);
        end
    end
end