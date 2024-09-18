classdef Polygon < Klayout
    % A polygon consists of an outer hull and holes. The Polygon class
    % from Klayout stores coordinates in integer. Note that we always
    % set the resolution to 1 nm.
    % https://www.klayout.de/doc/code/class_Polygon.html
    % This class maps a Klayout python polygon onto a Malab polyshape
    properties (Dependent)
        Vertices % Matlab vertices
    end
    properties
        pgon % matlab polygon
        pgon_py  % python polygon
        comsol_modeler
        comsol_shape
        comsol_name     % Full comsol name of element (pol1, fil12,sca23,...)
        comsol_prefix   % Comsol element prefix (pol, mir, fil, sca, ...)
    end
    methods
        function obj = Polygon(args)
            arguments
                args.Vertices (:, 2) double = [0, 0]
                args.comsol_modeler ComsolModeler=ComsolModeler.empty
            end
            % Matlab polygon (polyshape)
            obj.pgon = polyshape(args.Vertices);
            % Klayout (Python) Polygon
            obj.pgon_py = obj.pya.Polygon.from_s(...
                Utilities.vertices_to_string(args.Vertices));
            % Comsol
            obj.comsol_modeler = args.comsol_modeler;
            obj.comsol_prefix = "pol";
            if obj.comsol_flag
                index = obj.comsol_modeler.get_next_index(obj.comsol_prefix);
                obj.comsol_shape = obj.comsol_modeler.workplane.geom.create(obj.comsol_prefix+string(index), 'Polygon');
                x_values = Utilities.vertices_to_string(obj.Vertices(:, 1), true);
                y_values = Utilities.vertices_to_string(obj.Vertices(:, 2), true);
                obj.comsol_shape.set('x', x_values);
                obj.comsol_shape.set('y', y_values);
            end
        end
        function y = comsol_flag(obj)
            y = ~isempty(obj.comsol_modeler);
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
        function [comsol_object, previous_object_name] = create_comsol_object(obj, comsol_object_name)
            % This function creates a new comsol object in the plane
            % geometry. Tha comsol name can be "Rotate", "Difference",
            % "Move", "Copy"....
            % It returns the comsol object to be stored in
            % obj.comsol_shape; and the comsol object name of the initial
            % object that can be used for selection.
            obj.comsol_prefix = lower(comsol_object_name.extractBetween(1, 3));
            ind = obj.comsol_modeler.get_next_index(obj.comsol_prefix);
            obj.comsol_name = obj.comsol_prefix+ind;
            comsol_object = obj.comsol_modeler.workplane.geom.create(obj.comsol_name, comsol_object_name);
            previous_object_name = string(obj.comsol_shape.tag); % save name of initial comsol object to be selected
        end
        % Transformations
        function move(obj, vector)
            % Matlab
            moved_mat_pgon = obj.pgon.translate(vector);
            obj.Vertices = moved_mat_pgon.Vertices;
            % Python
            obj.pgon_py.move(vector(1), vector(2));
            % Comsol
            if obj.comsol_flag
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Move");           
                obj.comsol_shape.set('displx', vector(1));
                obj.comsol_shape.set('disply', vector(2));
                obj.comsol_shape.selection('input').set(previous_object_name);             
            end
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
            % Comsol
            if obj.comsol_flag
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Rotate");       
                obj.comsol_shape.set('rot', angle);
                obj.comsol_shape.set('pos', reference_point);
                obj.comsol_shape.selection('input').set(previous_object_name);
            end
        end
        function scale(obj, scaling_factor)
            % Matlab
            scaled_mat_pgon = obj.pgon.scale(scaling_factor);
            obj.Vertices = scaled_mat_pgon.Vertices;
            % Python
            scaling = obj.pya.CplxTrans(scaling_factor);
            obj.pgon_py.transform(scaling);
            % Comsol
            if obj.comsol_flag
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Scale");  
                obj.comsol_shape.set('factor', scaling_factor);
                obj.comsol_shape.selection('input').set(previous_object_name);
            end
        end
        function flip_horizontally(obj, axis)
            arguments
                obj
                axis double = 0
            end
            % Matlab
            obj.Vertices(:, 1) = 2*axis - obj.Vertices(:, 1);
            % Python
            obj.pgon_py.move(-axis, 0);
            mirrorX = obj.pya.Trans.M90;
            obj.pgon_py.transform(mirrorX);
            obj.pgon_py.move(axis, 0);
            % Comsol
            if obj.comsol_flag
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Mirror");
                obj.comsol_shape.set('pos', [axis, 0]); % point on reflexion axis
                obj.comsol_shape.set('axis', [1, 0]); % normal to reflexion axis
                obj.comsol_shape.selection('input').set(previous_object_name);
            end
        end
        function flip_vertically(obj, axis)
            arguments
                obj
                axis double = 0
            end
            obj.Vertices(:, 2) = 2*axis - obj.Vertices(:, 2);
            % Python
            obj.pgon_py.move(0, -axis);
            mirrorY = obj.pya.Trans.M0;
            obj.pgon_py.transform(mirrorY);
            obj.pgon_py.move(0, axis);
            % Comsol
            if obj.comsol_flag
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Mirror");
                obj.comsol_shape.set('pos', [0, axis]); % point on reflexion axis
                obj.comsol_shape.set('axis', [0, 1]); % normal to reflexion axis
                obj.comsol_shape.selection('input').set(previous_object_name);
            end
        end
        function round_corners(obj, radius, npoints, vertices_indices)
            % Returns a polygon with fillets in klayout, fillets added as a
            % separate object in klayout
            % vertices indices are the indices of vertices in Comsol (like  [1, 2, 3, 4]) when
            % selecting them. Maybe there is a way to retrieve them
            % automatically for a given shape...
            arguments
                obj
                radius double = 1
                npoints double = 10
                vertices_indices double = []
            end
            obj.pgon_py = obj.pgon_py.round_corners(radius, radius, npoints);  
            python_vertices = obj.pgon_py.to_s;
            matlab_vertices = Utilities.string_to_vertices(python_vertices);
            obj.Vertices = matlab_vertices;
            if obj.comsol_flag
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Fillet");
                obj.comsol_shape.set('radius', radius); 
                obj.comsol_shape.selection('point').set(previous_object_name, vertices_indices);
            end
        end

        % Boolean operations
        function sub_obj = minus(obj, object_to_subtract)
            if obj.comsol_flag
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Difference");
                obj.comsol_shape.selection('input').set([previous_object_name, string(object_to_subtract.comsol_shape.tag)]);
            end
            sub_obj = obj.apply_operation(object_to_subtract, "subtract");
        end
        function add_obj = plus(obj, object_to_add)
            if obj.comsol_flag
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Union");
                obj.comsol_shape.selection('input').set([previous_object_name, string(object_to_add.comsol_shape.tag)]);
            end
            add_obj = obj.apply_operation(object_to_add, "union");
        end
        function intersection_obj = intersect(obj, object_to_intersect)
            if obj.comsol_flag
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Intersection");
                obj.comsol_shape.selection('input').set([previous_object_name, string(object_to_intersect.comsol_shape.tag)]);
            end
            intersection_obj = obj.apply_operation(object_to_intersect, "intersect");
        end
        function y = apply_operation(obj, obj2, operation_name)
            % This is a wrapper for minus, plus, intersect, and boolean
            % operations. obj2 can be a cell array of objects and operation
            % the operation handle (for Matlab polyshape)

            % Define the matlab operation on polyshape
            switch operation_name
                case "subtract"
                    operation = @subtract;
                case "union"
                    operation = @union;
                case "intersect"
                    operation = @intersect;
            end
            mat_pgon = obj.pgon;
            region1 = obj.pya.Region();
            region1.insert(obj.pgon_py);
            region2 = obj.pya.Region();
            mat_pgon = operation(mat_pgon, obj2.pgon, ...
                'KeepCollinearPoints', false);
            region2.insert(obj2.pgon_py);
            y = Polygon;
            if obj.comsol_flag
                y.comsol_modeler = obj.comsol_modeler;
                y.comsol_shape = obj.comsol_shape;
            end
            y.pgon = mat_pgon;
            % Perform the Python operation on klayout polygon
            switch operation_name
                case "subtract"
                    region = region1-region2;
                case "union"
                    region = region1+region2;
                case "intersect"
                    % Weird that and_ is implemented and not and...
                    region = region1.and_(region2);
            end
            y.pgon_py = region.merge;
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
        % Copy function
        function y = copy(obj)
            y = Polygon;
            % Matlab
            y.pgon = obj.pgon; % polyshape is copyable
            % Klayout
            if isa(obj.pgon_py, 'py.klayout.dbcore.Region')
                % If klayout region
                y.pgon_py = obj.pya.Region();
                y.pgon_py.insert(obj.pgon_py);
            else % if klayout polygon
                y.pgon_py = obj.pya.Polygon.from_s(obj.pgon_py.to_s);
            end
            % Comsol
            if obj.comsol_flag
                y.comsol_modeler = obj.comsol_modeler;
                ind = obj.comsol_modeler.get_next_index('copy');
                y.comsol_prefix = "copy";
                y.comsol_name = y.comsol_prefix+ind;
                y.comsol_shape = obj.comsol_modeler.workplane.geom.create(y.comsol_name, "Copy");
                y.comsol_shape.selection('input').set(string(obj.comsol_shape.tag));
            end
        end
    end
end