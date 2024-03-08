classdef DSimplePolygon < Klayout & matlab.mixin.Copyable
    % A simple polygon consists of an outer hull only. The DSimplePolygon 
    % class from Klayout stores coordinates in floating-point format.
    % https://www.klayout.de/doc/code/class_DSimplePolygon.html
    % This class maps a Klayout python polygon onto a Malab polyshape
    % and later on a Comsol polygon (to do ...)
    % matlab.mixin.Copyable inheritance adds a copy function (shallow copy)
    % It allows to copy handles objects with properties, without calling the
    % constructor. Syntax: q = p.copy, where p is a DSimplePolygon object
    properties (Dependent)
        Vertices
    end
    properties %(Access=private)
        p_mat % matlab polygon
        p_py  % python polygon
    end
    methods
        function obj = DSimplePolygon(args)
            arguments
                args.Vertices (:, 2) double = []
            end
            if ~ isempty(args.Vertices)
                obj.Vertices = args.Vertices;
            end
        end
        function y = get.Vertices(obj)
            y = obj.p_mat.Vertices;
        end
        function set.Vertices(obj, vertices)
            % Matlab polygon (polyshape)
            obj.p_mat = polyshape(vertices);
            % Klayout (Python) polygon (DPolygon)
            py_vertices = obj.get_list_of_tuples_from_vertices_array(vertices);
            obj.p_py = obj.pya.DSimplePolygon(py_vertices);
        end
        function y = npoints(obj)
            y = size(obj.Vertices, 1);
        end
        % Transformations
        function move(obj, vector)
            moved_mat_polygon = obj.p_mat.translate(vector);
            obj.Vertices = moved_mat_polygon.Vertices;
        end
        function rotate(obj, angle, reference_point)
            arguments
                obj
                angle % in degrees
                reference_point = [0, 0]
            end
            rotated_mat_polygon = obj.p_mat.rotate(angle, reference_point);
            obj.Vertices = rotated_mat_polygon.Vertices;
        end
        function scale(obj, scaling_factor, reference_point)
            arguments
                obj
                scaling_factor
                reference_point = [0, 0]
            end
            scaled_mat_polygon = obj.p_mat.scale(scaling_factor, reference_point);
            obj.Vertices = scaled_mat_polygon.Vertices;
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

        % Boolean operations
        function sub_obj = minus(obj, objects_to_subtract)
            sub_obj = obj.apply_operation(objects_to_subtract, @subtract);
        end
        function add_obj = plus(obj, objects_to_add)
            add_obj = obj.apply_operation(objects_to_add, @union);
        end
        function intersection_obj = intersect(obj, objects_to_intersect)
            intersection_obj = obj.apply_operation(objects_to_intersect, @intersect);
        end
        function xor_obj = xor(obj, objects_to_xor)
            xor_obj = obj.apply_operation(objects_to_xor, @xor);
        end
        function temp_obj = apply_operation(obj, obj2, operation)
            % This is a wrapper for minus, plus, intersect, and boolean
            % operations. obj2 can be a cell array of objects and operation
            % the operation handle (for Matlab polyshape)
            temp_obj = obj.p_mat;
            for o=obj2
                if iscell(obj2)
                    o = o{1};
                end
                temp_obj = operation(temp_obj, o.p_mat, ...
                    'KeepCollinearPoints', false);
            end
            temp_obj = DSimplePolygon(Vertices=temp_obj.Vertices);
        end
        % Plot functions
        function plot(obj, args)
            arguments
                obj
                args.FigIndex = 1
                args.FaceColor = "blue"
                args.FaceAlpha = 0.4
            end
            figure(args.FigIndex)
            obj.p_mat.plot(FaceColor=args.FaceColor, FaceAlpha=args.FaceAlpha);
        end
    end
end