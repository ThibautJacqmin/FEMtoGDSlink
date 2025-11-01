classdef HoneyCombPhC < Design
    properties
        % scale = 0.3
        % correction = 0.5e-6/sin(pi/6)
        % bridge_width = 2.5e-6
        % bridge_width_center = 2.5e-6
        % structure_a = 45e-6
        % pad_radius = 11e-6
        % center_pad_radius = 18e-6
        % triangle_angle_radius = 5e-6
        % rhombus_angle_radius = 7e-6
        % y_size = 17
        % x_size
        % frame_size
        % offset = [-0.1, 0.5]
        lattice_constant
        number_of_unit_cells_width
        number_of_unit_cells_height
        comsol_flag
        comsol_modeler
        gds_modeler
        honeycomb_lattice
        unit_cell
        unit_cell_contour
        triangle_edge_length
        triangle_fillet_radius
        fillet_npoints
        tether_width
        rhombus
    end
    methods
        function obj = HoneyCombPhC(args)
            arguments
                args.lattice_constant Parameter
                args.number_of_unit_cells_width Parameter
                args.number_of_unit_cells_height Parameter
                args.tether_width Parameter
                args.fillet_npoints Parameter
                args.triangle_fillet_radius Parameter
                args.gds_modeler GDSModeler
                args.comsol_modeler ComsolModeler
            end
            obj.addParameters(args);
            % GDS Modeler
            obj.gds_modeler = args.gds_modeler;
            % Comsol Modeler
            obj.comsol_modeler = args.comsol_modeler;
            obj.comsol_flag = ~isempty(obj.comsol_modeler);
            % Compute hexagonal lattice
            obj.honeycomb_lattice = HoneyCombLattice(obj.lattice_constant.value, ...
                obj.number_of_unit_cells_width.value, ...
                obj.number_of_unit_cells_height.value);
            % Compute triangle edge length A TRANSFORMER EN PARAMETRE
            % DEPENDANT POUR COMSOL
            obj.triangle_edge_length = Parameter((norm(obj.honeycomb_lattice.siteA-obj.honeycomb_lattice.siteB)-obj.tether_width.value)*2/sqrt(3), "triangle_edge_length", comsol_modeler = obj.comsol_modeler);
        end
        function dummy_layer = getUnitCellContour(obj)
            % Create dummy layer
            dummy_layer = obj.gds_modeler.create_layer(20+randi(100));
            % Draw contour of unit cell
            vertices = Vertices(obj.honeycomb_lattice.unitCellContour);
            obj.unit_cell_contour = Polygon(vertices=vertices, comsol_modeler=obj.comsol_modeler);
            obj.gds_modeler.add_to_layer(dummy_layer, obj.unit_cell_contour);
        end
        function addUnitCell(obj, layer)
            % Get contour of unit cell
            dummy_layer = obj.getUnitCellContour;
            % Draw site A (rounded corners triangle) of honeycomb unit cell:
            % First triangle of the unit cell (with left vertical edge)
            siteA_triangle = obj.drawTriangleUnitCell(obj. honeycomb_lattice.siteA, ...
                210, dummy_layer);
            siteB_triangle = obj.drawTriangleUnitCell(obj. honeycomb_lattice.siteB, ...
                30, dummy_layer);
            triangles = (siteA_triangle+siteB_triangle);
            obj.unit_cell = obj.unit_cell_contour-triangles;
            % Add to current layer
            obj.gds_modeler.add_to_layer(layer, obj.unit_cell);
            % Delete dummy layer
            obj.gds_modeler.delete_layer(dummy_layer);
        end
        function makeLattice(obj, layer)
            lattice = obj.unit_cell.copy_to_positions( ...
                new_position=Vertices(obj.honeycomb_lattice.nodes.sublatticeA), ...
                vertex_to_copy=obj.honeycomb_lattice.siteA);
            obj.gds_modeler.add_to_layer(layer, lattice);
        end
        function triangle = drawTriangleUnitCell(obj, position, angle, layer)
            % Draw round corner trangles of unit cell
            triangle_vertices = Vertices([0, 0; 0, 1; sqrt(3)/2, 1/2], obj.triangle_edge_length);
            triangle = Polygon(vertices=triangle_vertices, comsol_modeler=obj.comsol_modeler);
            barycentre = triangle.vertices.isobarycentre;
            triangle.round_corners(obj.triangle_fillet_radius, obj.fillet_npoints);
            angle_name = string(triangle.comsol_shape.tag);
            triangle.rotate(Parameter(angle, "angle_" + angle_name, comsol_modeler = obj.comsol_modeler, unit="deg"), barycentre);
            triangle.move(position-barycentre);
            obj.gds_modeler.add_to_layer(layer, triangle);
        end
        function rhombus_cell = drawRhombus(obj, pos, angle, layer)
            % Get contour of unit cell
            dummy_layer = obj.getUnitCellContour; % Need to get again since it was detsroyed before
            obj.rhombus = obj.unit_cell_contour.copy;
            obj.rhombus.scale(Parameter(1-obj.tether_width.value*sqrt(3)/obj.triangle_edge_length.value, "rhombus_scaling_factor", comsol_modeler = obj.comsol_modeler, unit=""))
            obj.rhombus.move(obj.tether_width.value*(obj.honeycomb_lattice.a1+obj.honeycomb_lattice.a2)/norm(obj.honeycomb_lattice.a1+obj.honeycomb_lattice.a2))
            
            rhombus_name = string(rhombus.comsol_shape.tag);
            rhombus.scale()
            
            rhombus_vertices = Vertices([0, -1/2; -sqrt(3)/2, 0 ;0, 1/2; sqrt(3)/2, 0], obj.triangle_edge_length+obj.tether_width.value*sqrt(3));
            rhombus = Polygon(vertices=rhombus_vertices, comsol_modeler=obj.comsol_modeler);

            rhombus.rotate(Parameter(30, "angle_" + angle_name, comsol_modeler = obj.comsol_modeler, unit="deg"), rhombus.vertices.isobarycentre);
            %rhombus.move(obj.unit_cell.vertices.isobarycentre - rhombus.vertices.isobarycentre);
            rhombus.round_corners(obj.triangle_fillet_radius, obj.fillet_npoints);
            rhombus_cell = obj.unit_cell_contour-rhombus;
            angle_name = string(rhombus_cell.comsol_shape.tag);
            rhombus_cell.rotate(Parameter(angle, "angle_" + angle_name, comsol_modeler = obj.comsol_modeler, unit="deg"), rhombus_cell.vertices.isobarycentre);
            %rhombus_cell.move(pos-obj.unit_cell.vertices.isobarycentre);
            % Add to current layer
            obj.gds_modeler.add_to_layer(layer, rhombus_cell);

        end
        function addDefect(obj, layer)
             rhombus_1 = obj.drawRhombus(obj.honeycomb_lattice.siteA/2, 0, layer);
             rhombus_1.move([+39068-38970, +22663-22500]);
             rhombus_2 = rhombus_1.copy;
             rhombus_2.move(-obj.honeycomb_lattice.siteA + obj.honeycomb_lattice.a1- obj.honeycomb_lattice.a2)
             angle_name = string(rhombus_2.comsol_shape.tag);
             rhombus_2.rotate(Parameter(60, "angle_" + angle_name, comsol_modeler = obj.comsol_modeler, unit="deg"), rhombus_2.vertices.isobarycentre)
             %rhombus_2 = obj.drawRhombus(-obj.honeycomb_lattice.siteA + 3*obj.honeycomb_lattice.a1/2, 60, layer);
             % rhombus_3 = obj.drawRhombus(obj.honeycomb_lattice.siteA/2 + 3*obj.honeycomb_lattice.a1/2, 120, layer);
             % rhombus_4 = obj.drawRhombus(obj.honeycomb_lattice.siteA/2 + 2*obj.honeycomb_lattice.a1 - obj.honeycomb_lattice.a2, 0, layer);
             % rhombus_5 = obj.drawRhombus(obj.honeycomb_lattice.siteA/2 + obj.honeycomb_lattice.a1/2  - obj.honeycomb_lattice.a2, 120, layer);
             % rhombus_6 = obj.drawRhombus(-obj.honeycomb_lattice.siteA + obj.honeycomb_lattice.a1/2 - obj.honeycomb_lattice.a2, 60, layer);
             % rhombus_7 = obj.drawRhombus(-obj.honeycomb_lattice.siteA + 7*obj.honeycomb_lattice.a1/2 - obj.honeycomb_lattice.a2, 60, layer);
             % rhombus_8 = obj.drawRhombus(obj.honeycomb_lattice.siteA/2 + obj.honeycomb_lattice.a1 - 2*obj.honeycomb_lattice.a2, 0, layer);
             % rhombus_9 = obj.drawRhombus(obj.honeycomb_lattice.siteA/2 + 5*obj.honeycomb_lattice.a1/2 - 2*obj.honeycomb_lattice.a2, 120, layer);
             % rhombus_10 = obj.drawRhombus(-obj.honeycomb_lattice.siteA + 5*obj.honeycomb_lattice.a1/2 - 2*obj.honeycomb_lattice.a2, 60, layer);
             % rhombus_11 = obj.drawRhombus(obj.honeycomb_lattice.siteA/2 + 3*obj.honeycomb_lattice.a1/2 - 3*obj.honeycomb_lattice.a2, 120, layer);
             % rhombus_12 = obj.drawRhombus(obj.honeycomb_lattice.siteA/2 + 3*obj.honeycomb_lattice.a1 - 3*obj.honeycomb_lattice.a2, 0, layer);
        end
    end
end