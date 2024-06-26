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
        comsol_flag = false
        comsol_modeler
        comsol_shape
        comsol_name
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
            obj.comsol_flag = ~isempty(obj.comsol_modeler);
            obj.comsol_name = 'pol';
            if obj.comsol_flag
                index = obj.comsol_modeler.get_next_index(obj.comsol_name);
                obj.comsol_shape = obj.comsol_modeler.workplane.geom.create(obj.comsol_name+string(index), 'Polygon');
                x_values = Utilities.vertices_to_string(obj.Vertices(:, 1), true);
                y_values = Utilities.vertices_to_string(obj.Vertices(:, 2), true);
                obj.comsol_shape.set('x', x_values);
                obj.comsol_shape.set('y', y_values);
            end
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
            % Comsol
            if obj.comsol_flag
                ind = obj.comsol_modeler.get_next_index('mov');
                move_object =obj.comsol_modeler.workplane.geom.create("mov"+ind, "Move");           
                move_object.set('displx', vector(1));
                move_object.set('disply', vector(2));
                move_object.selection('input').set(string(obj.comsol_shape.tag));
                obj.comsol_shape = move_object;
                obj.comsol_name = 'mov';
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
                ind = obj.comsol_modeler.get_next_index('rot');
                rot_object = obj.comsol_modeler.workplane.geom.create("rot"+ind, "Rotate");
                rot_object.set('rot', angle);
                rot_object.set('pos', reference_point);
                rot_object.selection('input').set(string(obj.comsol_shape.tag));
                obj.comsol_shape = sca_object;
                obj.comsol_name = 'sca';
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
                ind = obj.comsol_modeler.get_next_index('sca');
                sca_object = obj.comsol_modeler.workplane.geom.create("sca"+ind, "Scale");
                sca_object.set('factor', scaling_factor);
                sca_object.selection('input').set(string(obj.comsol_shape.tag));
                obj.comsol_shape = sca_object;
                obj.comsol_name = 'sca';
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
                ind = obj.comsol_modeler.get_next_index('mir');
                mir_object = obj.comsol_modeler.workplane.geom.create("mir"+ind, "Mirror");
                mir_object.set('pos', [axis, 0]); % point on reflexion axis
                mir_object.set('axis', [1, 0]); % normal to reflexion axis
                mir_object.selection('input').set(string(obj.comsol_shape.tag));
                obj.comsol_shape = mir_object;
                obj.comsol_name = 'mir';
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
                ind = obj.comsol_modeler.get_next_index('mir');
                mir_object = obj.comsol_modeler.workplane.geom.create("mir"+ind, "Mirror");
                mir_object.set('pos', [0, axis]); % point on reflexion axis
                mir_object.set('axis', [0, 1]); % normal to reflexion axis
                mir_object.selection('input').set(string(obj.comsol_shape.tag));
                obj.comsol_shape = mir_object;
                obj.comsol_name = 'mir';
            end
        end

        % Boolean operations
        function sub_obj = minus(obj, object_to_subtract)
            sub_obj = obj.apply_operation(object_to_subtract, "subtract");
        end
        function add_obj = plus(obj, object_to_add)
            add_obj = obj.apply_operation(object_to_add, "union");
        end
        function intersection_obj = intersect(obj, object_to_intersect)
            intersection_obj = obj.apply_operation(object_to_intersect, "intersect");
        end
        function xor_obj = xor(obj, object_to_xor)
            xor_obj = obj.apply_operation(object_to_xor, "xor");
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
                case "xor"
                    operation = @xor;
            end
            mat_pgon = obj.pgon;
            region1 = obj.pya.Region();
            region1.insert(obj.pgon_py);
            region2 = obj.pya.Region();
            mat_pgon = operation(mat_pgon, obj2.pgon, ...
                'KeepCollinearPoints', false);
            region2.insert(obj2.pgon_py);
            y = Polygon;
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
                case "xor"
                    region = region1.xor(region2);
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
                y.comsol_flag = obj.comsol_flag;
                ind = obj.comsol_modeler.get_next_index('copy');
                y.comsol_name = "copy"+ind;
                y.comsol_shape = obj.comsol_modeler.workplane.geom.create(y.comsol_name, "Copy");
                y.comsol_shape.selection('input').set(string(obj.comsol_shape.tag));
            end
        end
    end
end