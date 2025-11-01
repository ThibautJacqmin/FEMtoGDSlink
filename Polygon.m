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
        comsol_adapter ComsolShapeAdapter
    end
    methods
        function obj = Polygon(args)
            arguments
                args.vertices Vertices=Vertices.empty
                args.comsol_modeler ComsolModeler=ComsolModeler.empty
                args.initialize_comsol (1,1) logical = true
            end
            % Vertices object
            obj.vertices = args.vertices;
            % Klayout (Python) Polygon
            if ~isempty(obj.vertices)
                obj.pgon_py = obj.pya.Polygon.from_s(obj.vertices.klayout_string);
            end
            % Comsol
            obj.comsol_modeler = args.comsol_modeler;
            obj.comsol_adapter = ComsolShapeAdapter(obj.comsol_modeler);
            if obj.comsol_flag && ~isempty(obj.vertices) && args.initialize_comsol
                obj.comsol_adapter.initializePolygon(obj.vertices);
                obj.sync_comsol_shape();
            end
        end
        function y = comsol_flag(obj)
            y = ~isempty(obj.comsol_adapter) && obj.comsol_adapter.isActive();
        end
        function sync_comsol_shape(obj)
            if obj.comsol_flag
                obj.comsol_shape = obj.comsol_adapter.shape;
            else
                obj.comsol_shape = [];
            end
        end
        function assign_comsol_adapter(obj, adapter)
            if nargin < 2 || isempty(adapter) || ~adapter.isActive()
                return;
            end
            if isempty(adapter.shape)
                return;
            end
            obj.comsol_adapter = adapter;
            obj.comsol_modeler = adapter.getModeler();
            obj.sync_comsol_shape();
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
                obj.comsol_adapter.move(vector);
                obj.sync_comsol_shape();
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
                obj.comsol_adapter.rotate(angle, reference_point);
                obj.sync_comsol_shape();
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
                obj.comsol_adapter.scale(scaling_factor);
                obj.sync_comsol_shape();
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
                obj.comsol_adapter.mirrorHorizontal(axis);
                obj.sync_comsol_shape();
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
                obj.comsol_adapter.mirrorVertical(axis);
                obj.sync_comsol_shape();
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
                vertices_indices = 1:obj.nvertices;
                obj.comsol_adapter.fillet(fillet_radius, vertices_indices);
                obj.sync_comsol_shape();
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
                array_adapter = obj.comsol_adapter.spawn();
                array_adapter.linearArray(ncopies_x, vertices.get_sub_vertex(1));
                array_adapter.linearArray(ncopies_y, vertices.get_sub_vertex(2));
                array_adapter.finalizeArray();
                y.assign_comsol_adapter(array_adapter);
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
                array_adapter = obj.comsol_adapter.spawn();
                array_adapter.linearArray(ncopies, vertex);
                array_adapter.finalizeArray();
                y.assign_comsol_adapter(array_adapter);
            end
        end

        % Boolean operations
        function sub_obj = minus(obj, object_to_subtract)
            sub_obj = obj.apply_operation(object_to_subtract, "Difference");
            if obj.comsol_flag && Polygon.has_comsol_target(object_to_subtract)
                difference_adapter = obj.comsol_adapter.spawn();
                difference_adapter.difference(object_to_subtract);
                sub_obj.assign_comsol_adapter(difference_adapter);
            end
        end
        function add_obj = plus(obj, object_to_add)
            add_obj = obj.apply_operation(object_to_add, "Union");
            if obj.comsol_flag && Polygon.has_comsol_target(object_to_add)
                union_adapter = obj.comsol_adapter.spawn();
                union_adapter.unite(object_to_add);
                add_obj.assign_comsol_adapter(union_adapter);
            end
        end
        function intersection_obj = intersect(obj, object_to_intersect)
            intersection_obj = obj.apply_operation(object_to_intersect, "Intersection");
            if obj.comsol_flag && Polygon.has_comsol_target(object_to_intersect)
                intersection_adapter = obj.comsol_adapter.spawn();
                intersection_adapter.intersect(object_to_intersect);
                intersection_obj.assign_comsol_adapter(intersection_adapter);
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
                copy_adapter = obj.comsol_adapter.copy();
                y.assign_comsol_adapter(copy_adapter);
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
                copy_adapter = obj.comsol_adapter.spawn();
                copy_adapter.copyPositions(vertex_to_copy=args.vertex_to_copy, new_positions=args.new_positions);
                y.assign_comsol_adapter(copy_adapter);
            end
        end
    end
    methods (Static, Access = private)
        function flag = has_comsol_target(target)
            if isa(target, 'Polygon')
                flag = target.comsol_flag;
            elseif isa(target, 'ComsolShapeAdapter')
                flag = target.isActive() && ~isempty(target.shape);
            elseif iscell(target)
                if isempty(target)
                    flag = false;
                else
                    flags = cellfun(@(item) Polygon.has_comsol_target(item), target);
                    flag = all(flags);
                end
            else
                flag = false;
            end
        end
    end
end