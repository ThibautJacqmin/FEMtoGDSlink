classdef Polygon < Klayout
    % A polygon consists of an outer hull and holes. The Polygon class
    % from Klayout stores coordinates in integer. Note that we always
    % set the resolution to 1 nm.
    % https://www.klayout.de/doc/code/class_Polygon.html
    properties
        vertices % Vertices object
        pgon_py  % python polygon
        comsol_modeler
        comsol_shape
        comsol_name     % Full comsol name of element (pol1, fil12,sca23,...)
        layer % layer where Polygon is added (if added to any layer)
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
                if obj.comsol_flag
                    obj.comsol_shape = obj.comsol_modeler.create_comsol_object("Polygon");
                    obj.comsol_shape.set('x', obj.vertices.comsol_string_x);
                    obj.comsol_shape.set('y', obj.vertices.comsol_string_y);
                end
            end
        end
        function y = comsol_flag(obj)
            y = ~isempty(obj.comsol_modeler);
        end
        function y = nvertices(obj)
            y = obj.vertices.nvertices;
        end
        % Transformations
        function move(obj, vector)
            arguments
                obj
                vector Vertices
            end
            % Modifier cette ligne pour utiliser les opérations sur les
            % Vertices directement
            obj.vertices.array = obj.vertices.array + [vector.value(1), vector.value(2)]./obj.vertices.prefactor.value;
            % Python
            obj.pgon_py.move(vector.value(1), vector.value(2));
            % Comsol
            if obj.comsol_flag
                previous_object_name = string(obj.comsol_shape.tag); % save name of initial comsol object to be selected
                obj.comsol_shape = obj.comsol_modeler.create_comsol_object("Move");
                obj.comsol_shape.set('displx', vector.value(1));
                obj.comsol_shape.set('disply', vector.value(2));
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
                previous_object_name = string(obj.comsol_shape.tag); % save name of initial comsol object to be selected
                obj.comsol_shape = obj.comsol_modeler.create_comsol_object("Rotate");
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
                previous_object_name = string(obj.comsol_shape.tag); % save name of initial comsol object to be selected
                obj.comsol_shape = obj.comsol_modeler.create_comsol_object("Scale");
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
                previous_object_name = string(obj.comsol_shape.tag); % save name of initial comsol object to be selected
                obj.comsol_shape = obj.comsol_modeler.create_comsol_object("Mirror");
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
                previous_object_name = string(obj.comsol_shape.tag); % save name of initial comsol object to be selected
                obj.comsol_shape = obj.comsol_modeler.create_comsol_object("Mirror");
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
            obj.vertices = Vertices(Utilities.get_vertices_from_klayout(obj.pgon_py));
            disp("Number of points in fillets cannot be set in Comsol")
            if obj.comsol_flag
                previous_object_name = string(obj.comsol_shape.tag); % save name of initial comsol object to be selected
                vertices_indices = linspace(1, obj.nvertices);
                obj.comsol_shape = obj.comsol_modeler.create_comsol_object("Fillet");
                obj.comsol_shape.set('radius', fillet_radius.name);
                obj.comsol_shape.selection('point').set(previous_object_name, vertices_indices);
            end
        end
        function y = make_2D_array(obj, ncopies_x, ncopies_y, vertices, gds_modeler, layer)
            % returns a polygon
            arguments
                obj
                ncopies_x {mustBeA(ncopies_x, {'Variable', 'Parameter', 'DependentParameter'})}
                ncopies_y {mustBeA(ncopies_y, {'Variable', 'Parameter', 'DependentParameter'})}
                vertices {mustBeA(vertices, {'Vertices'})}
                gds_modeler
                layer
            end
            cell_name_1 = 'intermediate_cell_1';
            intermediate_cell_1 = gds_modeler.pylayout.create_cell(cell_name_1);
            gds_modeler.add_to_layer(layer, obj, intermediate_cell_1);
            transformation = obj.pya.Trans(obj.pya.Point(0,0));
            array_1_cell_instance = obj.pya.CellInstArray(intermediate_cell_1.cell_index(), transformation, ...
                obj.pya.Vector(vertices.value(1, 1), vertices.value(1, 2)), obj.pya.Vector(0, 1), ncopies_x.value, 1);
            gds_modeler.pycell.insert(array_1_cell_instance);
            cell_name_2 = 'intermediate_cell_2';
            intermediate_cell_2 = gds_modeler.pylayout.create_cell(cell_name_2);
            intermediate_cell_2.insert(array_1_cell_instance);
            array_2_cell_instance = obj.pya.CellInstArray(intermediate_cell_2.cell_index(), transformation, ...
                obj.pya.Vector(vertices.value(2, 1), vertices.value(2, 2)), obj.pya.Vector(1, 0), ncopies_y.value, 1);
            gds_modeler.pycell.insert(array_2_cell_instance);
            gds_modeler.pycell.flatten(-1);
            region = obj.pya.Region();
            region.insert(gds_modeler.pycell.shapes(layer));
            region.merge();
            % Create Polygon object to return
            y = Polygon;
            y.pgon_py = region;
            if obj.comsol_flag
                y.comsol_modeler = obj.comsol_modeler;
                y.comsol_shape = obj.comsol_modeler.make_1D_array(ncopies_x, vertices.get_sub_vertex(1), obj.comsol_shape);
                y.comsol_shape = obj.comsol_modeler.make_1D_array(ncopies_y, vertices.get_sub_vertex(2), y.comsol_shape);
                % Create Union (otherwise selection difficult later)
                previous_object_name = string(y.comsol_shape.tag); % array name
                y.comsol_shape = obj.comsol_modeler.create_comsol_object("Union");
                y.comsol_shape.selection('input').set(previous_object_name);
            end
        end
        function y = make_1D_array(obj, ncopies, vertex, gds_modeler, layer)
            % Need to modify as 2D arrays otherwise does not work
            arguments
                obj
                ncopies {mustBeA(ncopies, {'Variable', 'Parameter', 'DependentParameter'})}
                vertex {mustBeA(vertex, {'Vertices'})}
                gds_modeler
                layer
            end
            cell_name = 'intermediate_cell';
            new_cell = gds_modeler.pylayout.create_cell(cell_name);
            gds_modeler.add_to_layer(layer, obj, new_cell);
            transformation = obj.pya.Trans(obj.pya.Point(0,0));
            cell_instance = obj.pya.CellInstArray(new_cell.cell_index(), transformation, ...
                obj.pya.Vector(vertex.value(1), vertex.value(2)), obj.pya.Vector(0, 1), ncopies.value, 1);
            gds_modeler.pycell.insert(cell_instance);
            gds_modeler.pycell.flatten(-1);
            region = obj.pya.Region();
            region.insert(gds_modeler.pycell.shapes(layer));
            region.merge();
            % Create Polygon object to return
            y = Polygon;
            y.pgon_py = region;
            if obj.comsol_flag
                y.comsol_modeler = obj.comsol_modeler;
                obj.comsol_shape = obj.comsol_modeler.make_1D_array(ncopies, vertex, obj.comsol_shape);
                % Create Union (otherwise selection difficult later)
                previous_object_name = string(y.comsol_shape.tag); % array name
                y.comsol_shape = obj.comsol_modeler.create_comsol_object("Union");
                y.comsol_shape.selection('input').set(previous_object_name);
            end
        end

        % Boolean operations
        function sub_obj = minus(obj, object_to_subtract)
            sub_obj = obj.apply_operation(object_to_subtract, "Difference");
            if obj.comsol_flag
                sub_obj.comsol_modeler = obj.comsol_modeler;
                previous_object_name = string(obj.comsol_shape.tag); % save name of initial comsol object to be selected
                sub_obj.comsol_shape = obj.comsol_modeler.create_comsol_object("Difference");
                sub_obj.comsol_shape.selection('input').set(previous_object_name);
                sub_obj.comsol_shape.selection('input2').set(string(object_to_subtract.comsol_shape.tag));
            end
        end
        function add_obj = plus(obj, object_to_add)
            add_obj = obj.apply_operation(object_to_add, "Union");
            if obj.comsol_flag
                add_obj.comsol_modeler = obj.comsol_modeler;
                previous_object_name = string(obj.comsol_shape.tag); % save name of initial comsol object to be selected
                add_obj.comsol_shape = obj.comsol_modeler.create_comsol_object("Union");
                add_obj.comsol_shape.selection('input').set([previous_object_name, string(object_to_add.comsol_shape.tag)]);
            end
        end
        function intersection_obj = intersect(obj, object_to_intersect)
            intersection_obj = obj.apply_operation(object_to_intersect, "Intersection");
            if obj.comsol_flag
                intersection_obj.comsol_modeler = obj.comsol_modeler;
                previous_object_name = string(obj.comsol_shape.tag); % save name of initial comsol object to be selected
                intersection_obj.comsol_shape = obj.comsol_modeler.create_comsol_object("Intersection");
                sub_obj.comsol_shape.selection('input').set(previous_object_name); %To be checked
                sub_obj.comsol_shape.selection('input2').set(string(object_to_intersect.comsol_shape.tag)); % To be checked
                disp('warning check selection for intersection operation in Polygon for Comsol')
            end

        end
        function y = apply_operation(obj, obj2, operation_name)
            % This is a wrapper for minus, plus, intersect, and boolean
            % operations. obj2 can be a cell array of objects and operation
            region1 = obj.pya.Region();
            region1.insert(obj.pgon_py);
            region1.flatten;
            region1.merge;
            region2 = obj.pya.Region();
            region2.insert(obj2.pgon_py);
            region2.flatten;
            region2.merge;
            y = Polygon;
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
            y.pgon_py = region.merged;
            y.vertices = Vertices(Utilities.get_vertices_from_klayout(y.pgon_py)); % gives NaN...
        end

        % Copy function
        function y = copy(obj)
            y = Polygon;
            % Klayout
            if isa(obj.pgon_py, 'py.klayout.dbcore.Region')
                % If klayout region
                y.pgon_py = obj.pya.Region();
                y.pgon_py.insert(obj.pgon_py);
                y.pgon_py.flatten;
                y.pgon_py.merge;
            else % if klayout polygon
                y.pgon_py = obj.pya.Polygon.from_s(obj.pgon_py.to_s);
            end
            % Retrieve vertices
            y.vertices = Vertices(Utilities.get_vertices_from_klayout(y.pgon_py));
            % Comsol
            if obj.comsol_flag
                y.comsol_modeler = obj.comsol_modeler;
                y.comsol_shape = obj.comsol_modeler.create_comsol_object("Copy");
                y.comsol_shape.selection('input').set(string(obj.comsol_shape.tag));
            end
        end
        function y = copy_to_positions(obj, args)
            % This methods copies a Polygon to positions input as Vertices
            % object. The origin vertice is vertex_to_copy.
            arguments
                obj Polygon
                args.vertex_to_copy  % coordinates of vertex to copy
                args.new_positions Vertices   % Vertices where to duplicate the shape
                args.layer
            end
            
            % Klayout
            y = Polygon;
            % Store ensemble of polygons in a KLayout Region
            y.pgon_py = obj.pya.Region();
            for i=1:args.new_positions.nvertices
                y.pgon_py.insert(obj.pgon_py.transformed(obj.pya.Trans( ...
                    obj.pya.Point(args.new_positions.value(i, 1), args.new_positions.value(i, 2)))));
            end
            y.pgon_py.flatten;
            y.pgon_py.merge;
            % Retrieve vertices
            y.vertices = Vertices(Utilities.get_vertices_from_klayout(y.pgon_py));


            % Comsol
            if obj.comsol_flag
                y.comsol_modeler = obj.comsol_modeler;
                y.comsol_shape = obj.comsol_modeler.create_comsol_object("Copy");
                y.comsol_shape.set('keep', false);
                y.comsol_shape.selection('input').set(string(obj.comsol_shape.tag));
                y.comsol_shape.set("specify", "pos");
                y.comsol_shape.set("oldpos", "coord");
                y.comsol_shape.set("newpos", "coord");
                y.comsol_shape.set("oldposcoord", args.vertex_to_copy);
                y.comsol_shape.set("newposx", args.new_positions.xvalue);
                y.comsol_shape.set("newposy",  args.new_positions.yvalue);
            end
        end
    end
end