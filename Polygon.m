classdef Polygon < Klayout & matlab.mixin.Copyable
    properties (Dependent)
        Vertices
    end
    properties %(Access=private)
        p % matlab polygon
    end
    methods
        function obj = Polygon(args)
            arguments
                args.vertices (:, 2) double = []
            end
            obj.p = polyshape(args.vertices);
        end
        function y = get.Vertices(obj)
            y = obj.p.Vertices;
        end
        function set.Vertices(obj, val)
            obj.p.Vertices = val;
        end
        function y = npoints(obj)
            y = size(obj.Vertices, 1);
        end
        function translated_polygon = translate(obj, vector)
            tpgon = obj.p.translate(vector);
            % Output object of good Polygon class (Box if Box, ...)
            translated_polygon = feval(class(obj), vertices=tpgon.Vertices);
        end
        function sub_obj = minus(obj, objects_to_subtract)
            sub_obj = obj.p;
            for o=objects_to_subtract
                if iscell(objects_to_subtract)
                    o = o{1};
                end
                sub_obj = subtract(sub_obj, o.p);
            end
            sub_obj = Polygon(vertices=sub_obj.Vertices);
        end
        function add_obj = plus(obj, objects_to_add)
            add_obj = obj.p;
            for o=objects_to_add
                if iscell(objects_to_add)
                    o = o{1};
                end
                add_obj = union(add_obj, o.p);
            end
            add_obj = Polygon(vertices=add_obj.Vertices);
        end
        function plot(obj)
            figure(1)
            obj.p.plot;
        end
        function flip_horizontally(obj, axis)
            arguments
                obj
                axis double = 0
            end
            obj.Vertices(:, 1) = 2*axis - obj.Vertices(:, 1);
        end
        function flip_vertically(obj, axis)
            arguments
                obj
                axis double = 0
            end
            obj.Vertices(:, 2) = 2*axis - obj.Vertices(:, 2);
        end
        function scaled_obj = scale(obj, factor)
            % factor can be a number or a two components vector
            scaled_obj = obj.p.scale(factor);
            scaled_obj = Polygon(vertices=scaled_obj.Vertices);
        end
    end
    methods (Hidden)
        function py_obj = get_python_obj(obj)
            pts_list = py.list();
            % Find indices of NaN (Nan separate the hull and the holes)
            x = find(isnan(obj.Vertices(:, 1)));
            pts_list.extend();
            py_obj = obj.pya.DPolygon(pts_list);            
    
            end
            
        end
    end
end