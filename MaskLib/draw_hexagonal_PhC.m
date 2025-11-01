% Transformer ce fichier en classe avec fonction pour ajouter les
% propriétés automatiquement
warning('off');
gm = GDSModeler;
%cm = ComsolModeler.empty;

if ~exist('comsol_modeler', 'var')
        cm = ComsolModeler;
        cm.start_gui;
end

% % BACK SIDE LAYER
unit_cell_layer = gm.create_layer(0);
PhC_layer = gm.create_layer(1);
defect_layer = gm.create_layer(2);

lattice_constant = Parameter(77.94e3, "lattice_constant", comsol_modeler=cm);
number_of_unit_cells_width= Parameter(8, "number_of_unit_cells_width", unit="", comsol_modeler=cm);
number_of_unit_cells_height = Parameter(8, "number_of_unit_cells_height", unit="", comsol_modeler=cm);
triangle_fillet_radius = Parameter(5e3, "triangle_fillet_radius", comsol_modeler=cm);
fillet_npoints = Parameter(64, "fillet_npoints"); % Number of fillet point cannot be set in Comsol
tether_width = Parameter(5e3, "tether_width", comsol_modeler=cm);


% This lattice is a hexagonal lattice of pads, but a honeycomb lattice of
% holes. It is easier to implement the latter than the former. Hence:
h = HoneyCombPhC(lattice_constant=lattice_constant, ...
                 number_of_unit_cells_width=number_of_unit_cells_width, ...
                 number_of_unit_cells_height=number_of_unit_cells_height, ...
                 tether_width=tether_width,...
                 fillet_npoints=fillet_npoints,...
                 triangle_fillet_radius=triangle_fillet_radius,...
                 gds_modeler=gm,...
                 comsol_modeler=cm);
h.addUnitCell(unit_cell_layer);
h.makeLattice(PhC_layer);
h.addDefect(PhC_layer);

% triangle_fillet_radius = Parameter("triangle_fillet_radius", 5e3, comsol_modeler=cm);
% fillet_npoints = Parameter("fillet_npoints", 64, comsol_modeler=cm);
% tether_width = Parameter("tether_width", 5e3, comsol_modeler=cm);
% triangle_edge_length = (lattice_parameter.value-tether_width.value)/sqrt(3);
% 
% % First triangle of the unit cell (with left vertical edge)
% triangle_vertices = Vertices([0, 0; 0, 1; sqrt(3)/2, 1/2], triangle_edge_length);
% triangle_1 = Polygon(Vertices=triangle_vertices, comsol_modeler=cm);
% triangle_1.round_corners(triangle_fillet_radius, fillet_npoints);
% 
% % Define symmetry axis to get the other triangle of the unit cell. It is
% % the axis rotated by pi/6 with respect to the vertical axis
% triangle_2 = triangle_1.copy;
% flip_axis = DependentParameter("flip_axis", @(x)(-x/2), tether_width, comsol_modeler=cm);
% triangle_2.flip_horizontally(flip_axis);
% unit_cell = triangle_1+triangle_2;
% 
% 
% array_size = Parameter("array_size", 40, comsol_modeler=cm);
% unit_cell.move(Vertices([-array_size.value*(lattice_parameter.value+tether_width.value*2)/2, 0]));
% vector_1 = Vertices([1/2, 1/(2*sqrt(3))], lattice_parameter+tether_width.*2);
% vector_2 = Vertices([1/2, -1/(2*sqrt(3))], lattice_parameter+tether_width.*2);
% array = unit_cell.make_2D_array(array_size, array_size, vector_1+vector_2, gm, layer);
% 
% % Define truncating square
% membrane_width = Parameter("membrane_width", 1000e3, comsol_modeler=cm);
% membrane_height = Parameter("membrane_height", 1000e3, comsol_modeler=cm);
% square = Box(center=[0, 0], width=membrane_width, height=membrane_height, comsol_modeler=cm);
% 
% gm.add_to_layer(layer, square);
% 
% % Intersection square and array
% % Need to solve issue : region an polygon boolean operation does not work
% % in klayout
% membrane = array.intersect(square);
% 
% layer_membrane = gm.create_layer(1);
% gm.add_to_layer(layer_membrane, membrane);
% 
% %gm.delete_layer(layer);
% 
% layer_lotus = gm.create_layer(2);

% rhombus_fillet_radius = Parameter("rhombus_fillet_radius", 7e3, comsol_modeler=cm);
% rhombus_edge_length = Parameter("rhombus_edge_length", triangle_edge_length+tether_width.value/sqrt(3), comsol_modeler=cm);
% rhombus_vertices = Vertices([0, 0; ...
%                              sqrt(3)/2, 1/2; ...
%                              0, 1;...
%                              -sqrt(3)/2, 1/2], ...
%                              rhombus_edge_length);
% 
% rhombus_1 = Polygon(Vertices=rhombus_vertices, comsol_modeler=cm);
% rhombus_1.move(Vertices([-tether_width.value/2, -tether_width.value/(2*sqrt(3))]));
% rhombus_2 = rhombus_1.copy;
% rhombus_1.round_corners(fillet_radius, fillet_npoints);
% 
% rhombus_2.rotate(Parameter("", 60), mean(rhombus_2.vertices.value) + [0, lattice_parameter.value-tether_width.value/(3)]);
% gm.add_to_layer(layer_lotus, rhombus_1);
% gm.add_to_layer(layer_lotus, rhombus_2);

gm.write("hexagonal_PhC_unit_cell.gds")
% Plot Comsol geometry in Matlab 
%cm.plot;
% Export model in .m file
% comsol_modeler.save_to_m_file;
