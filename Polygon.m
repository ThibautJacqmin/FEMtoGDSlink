classdef Polygon < Klayout
    % A polygon consists of an outer hull and holes. The Polygon class
    % from Klayout stores coordinates in integer. Note that we always
    % set the resolution to 1 nm.
    % https://www.klayout.de/doc/code/class_Polygon.html
    % This class maps a Klayout python polygon onto a Malab polyshape
    properties 
        vertices % Vertices object
        pgon_py  % python polygon
        comsol_modeler
        comsol_shape
        comsol_name     % Full comsol name of element (pol1, fil12,sca23,...)
        comsol_prefix   % Comsol element prefix (pol, mir, fil, sca, ...)
    end
    methods
        function obj = Polygon(args)
            arguments
                args.vertices Vertices=Vertices.empty
                args.comsol_modeler ComsolModeler=ComsolModeler.empty
            end
            % Vertices object
            obj.vertices = args.vertices;
            % Klayout (Python) Polygon
            if ~isempty(obj.vertices)
                obj.pgon_py = obj.pya.Polygon.from_s(obj.vertices.klayout_string);
                % Comsol
                obj.comsol_modeler = args.comsol_modeler;
                obj.comsol_prefix = "pol";
                if obj.comsol_flag
                    index = obj.comsol_modeler.get_next_index(obj.comsol_prefix);
                    obj.comsol_shape = obj.comsol_modeler.workplane.geom.create(obj.comsol_prefix+string(index), 'Polygon');
                    obj.comsol_shape.set('x', obj.vertices.comsol_string_x);
                    obj.comsol_shape.set('y', obj.vertices.comsol_string_y);
                end
            end
        end
        function y = comsol_flag(obj)
            y = ~isempty(obj.comsol_modeler);
        end
        function y = npoints(obj)
            y = size(obj.vertices.array, 1);
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
                angle {mustBeA(angle, {'Variable', 'Parameter', 'DependentParameter'})} % in degree
                reference_point = [0, 0]
            end
            % Python
            % Translate by [-xref, -yref], then rotate the translate by [xref, yref]
            obj.pgon_py.move(-reference_point(1), -reference_point(2));
            % CplxTrans (magnification, rotation angle, mirror_x, x_translation, y_translation)
            rotation = obj.pya.CplxTrans(1, angle.value, py.bool(0), 0, 0);
            obj.pgon_py.transform(rotation);
            obj.pgon_py.move(reference_point(1), reference_point(2));
            % Comsol
            if obj.comsol_flag
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Rotate");       
                obj.comsol_shape.set('rot', angle.name);
                obj.comsol_shape.set('pos', reference_point);
                obj.comsol_shape.selection('input').set(previous_object_name);
            end
        end
        function scale(obj, scaling_factor)
            arguments
                obj
                scaling_factor {mustBeA(scaling_factor, {'Variable', 'Parameter', 'DependentParameter'})}
            end
            % Python
            scaling = obj.pya.CplxTrans(scaling_factor.value);
            obj.pgon_py.transform(scaling);
            % Comsol
            if obj.comsol_flag
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Scale");  
                obj.comsol_shape.set('factor', scaling_factor.name);
                obj.comsol_shape.selection('input').set(previous_object_name);
            end
        end
        function flip_horizontally(obj, axis)
            arguments
                obj
                axis {mustBeA(axis, {'Variable', 'Parameter', 'DependentParameter'})}
            end
            % Python
            obj.pgon_py.move(-axis.value, 0);
            mirrorX = obj.pya.Trans.M90;
            obj.pgon_py.transform(mirrorX);
            obj.pgon_py.move(axis.value, 0);
            % Comsol
            if obj.comsol_flag
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Mirror");
                obj.comsol_shape.set('pos', [axis.name, 0]); % point on reflexion axis
                obj.comsol_shape.set('axis', [1, 0]); % normal to reflexion axis
                obj.comsol_shape.selection('input').set(previous_object_name);
            end
        end
        function flip_vertically(obj, axis)
            arguments
                obj
                axis {mustBeA(axis, {'Variable', 'Parameter', 'DependentParameter'})}
            end
            % Python
            obj.pgon_py.move(0, -axis.value);
            mirrorY = obj.pya.Trans.M0;
            obj.pgon_py.transform(mirrorY);
            obj.pgon_py.move(0, axis.value);
            % Comsol
            if obj.comsol_flag
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Mirror");
                obj.comsol_shape.set('pos', [0, axis.name]); % point on reflexion axis
                obj.comsol_shape.set('axis', [0, 1]); % normal to reflexion axis
                obj.comsol_shape.selection('input').set(previous_object_name);
            end
        end
        function round_corners(obj, fillet_radius, fillet_npoints)
            % Returns a polygon with fillets in klayout, fillets added as a
            % separate object in klayout
            % vertices indices are the indices of vertices in Comsol (like  [1, 2, 3, 4]) when
            % selecting them. Maybe there is a way to retrieve them
            % automatically for a given shape...
            arguments
                obj
                fillet_radius Parameter
                fillet_npoints Parameter
            end
            obj.pgon_py = obj.pgon_py.round_corners(fillet_radius.value,...
                fillet_radius.value, fillet_npoints.value); 
            disp("Number of points in fillets cannot be set in Comsol")
            if obj.comsol_flag
                vertices_indices = linspace(1, obj.npoints);
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Fillet");
                obj.comsol_shape.set('radius', fillet_radius.name); 
                obj.comsol_shape.selection('point').set(previous_object_name, vertices_indices);
            end
        end

        % Boolean operations
        function sub_obj = minus(obj, object_to_subtract)
            if obj.comsol_flag
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Difference");
                obj.comsol_shape.selection('input').set([previous_object_name, string(object_to_subtract.comsol_shape.tag)]);
            end
            sub_obj = obj.apply_operation(object_to_subtract, "Difference");
        end
        function add_obj = plus(obj, object_to_add)
            if obj.comsol_flag
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Union");
                obj.comsol_shape.selection('input').set([previous_object_name, string(object_to_add.comsol_shape.tag)]);
            end
            add_obj = obj.apply_operation(object_to_add, "Union");
        end
        function intersection_obj = intersect(obj, object_to_intersect)
            if obj.comsol_flag
                [obj.comsol_shape, previous_object_name] = obj.create_comsol_object("Intersection");
                obj.comsol_shape.selection('input').set([previous_object_name, string(object_to_intersect.comsol_shape.tag)]);
            end
            intersection_obj = obj.apply_operation(object_to_intersect, "Intersection");
        end
        function y = apply_operation(obj, obj2, operation_name)
            % This is a wrapper for minus, plus, intersect, and boolean
            % operations. obj2 can be a cell array of objects and operation

            region1 = obj.pya.Region();
            region1.insert(obj.pgon_py);
            region2 = obj.pya.Region();
            region2.insert(obj2.pgon_py);
            y = Polygon;
            if obj.comsol_flag
                y.comsol_modeler = obj.comsol_modeler;
                y.comsol_shape = obj.comsol_shape;
            end
            % Perform the Python operation on klayout polygon
            switch operation_name
                case "Difference"
                    region = region1-region2;
                case "Union"
                    region = region1+region2;
                case "Intersection"
                    % Weird that and_ is implemented and not and...
                    region = region1.and_(region2);
            end
            y.pgon_py = region.merge;
        end

        % Copy function
        function y = copy(obj)
            y = Polygon;
            % Klayout
            if isa(obj.pgon_py, 'py.klayout.dbcore.Region')
                % If klayout region
                y.pgon_py = obj.pya.Region();
                y.pgon_py.insert(obj.pgon_py);
            else % if klayout polygon
                y.pgon_py = obj.pya.Polygon.from_s(obj.pgon_py.to_s);
            end
            % Retrieve vertices
            y.vertices = Vertices(Utilities.get_vertices_from_klayout(y.pgon_py));
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