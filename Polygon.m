classdef Polygon < Klayout & matlab.mixin.Copyable
    % A polygon consists of an outer hull and holes. The Polygon class
    % from Klayout stores coordinates in integer. Note that we always
    % set the resolution to 1 nm.
    % https://www.klayout.de/doc/code/class_Polygon.html
    % This class maps a Klayout python polygon onto a Malab polyshape
    % matlab.mixin.Copyable inheritance adds a copy function (shallow copy)
    % It allows to copy handles objects with properties, without calling the
    % constructor. Syntax: q = p.copy, where p is a Polygon object
    properties (Dependent)
        Vertices % Matlab vertices
    end
    properties 
        pgon % matlab polygon
        pgon_py  % python polygon
        Vertices_py % Python vertices
    end
    methods
        function obj = Polygon(args)
            arguments
                args.Vertices (:, 2) double = [0, 0]
            end
            % Matlab polygon (polyshape)
            obj.pgon = polyshape(args.Vertices);
            % Klayout (Python) polygon (DPolygon)
            obj.pgon_py = obj.pya.Polygon.from_s(...
                Utilities.vertices_to_string(args.Vertices));
        end
        function y = get.Vertices(obj)
            y = obj.pgon.Vertices;
        end
        function set.Vertices(obj, vertices)
            obj.pgon.Vertices = vertices;
        end
        function y = npoints(obj)
            y = size(obj.Vertices, 1);
        end
        % Transformations
        function move(obj, vector)
            % Matlab
            moved_mat_pgon = obj.pgon.translate(vector);
            obj.Vertices = moved_mat_pgon.Vertices;
            % Python
            obj.pgon_py.move(vector(1), vector(2));
        end
        function rotate(obj, angle, reference_point)
            arguments
                obj
                angle % in degrees
                reference_point = [0, 0]
            end
            % Matlab
            rotated_mat_pgon = obj.pgon.rotate(angle, reference_point);
            obj.Vertices = rotated_mat_pgon.Vertices;
            % Python
            % Translate by [-xref, -yref], then rotate the translate by [xref, yref]
            obj.pgon_py.move(-reference_point(1), -reference_point(2));
            % CplxTrans (magnification, rotation angle, mirror_x, x_translation, y_translation)
            rotation = obj.pya.CplxTrans(1, angle, py.bool(0), 0, 0);
            obj.pgon_py.transform(rotation);
            obj.pgon_py.move(reference_point(1), reference_point(2));
        end
        function scale(obj, scaling_factor)
            % Matlab
            scaled_mat_pgon = obj.pgon.scale(scaling_factor);
            obj.Vertices = scaled_mat_pgon.Vertices;
            % Python
            scaling = obj.pya.CplxTrans(scaling_factor);
            obj.pgon_py.transform(scaling);
        end
        function flip_horizontally(obj, axis)
            arguments
                obj
                axis double = 0
            end
            % Matlab
            obj.Vertices(:, 1) = 2*axis - obj.Vertices(:, 1);
            % Python : Use Trans.M0, ... mirror and 90° rot implemented
            % there
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
            temp_obj = obj.pgon;
            for o=obj2
                if iscell(obj2)
                    o = o{1};
                end
                temp_obj = operation(temp_obj, o.pgon, ...
                    'KeepCollinearPoints', false);
            end
            temp_obj = Polygon(Vertices=temp_obj.Vertices);
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
            obj.pgon.plot(FaceColor=args.FaceColor, FaceAlpha=args.FaceAlpha);
        end
    end
end