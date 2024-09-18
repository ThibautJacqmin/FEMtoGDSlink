% Transformer ce fichier en classe avec fonction pour ajouter les
% propriétés automatiquement
warning('off');
gds_modeler = GDSModeler;


if ~exist('comsol_modeler', 'var')
    comsol_modeler = ComsolModeler;
    comsol_modeler.start_gui;
end

% BACK SIDE LAYER
layer = gds_modeler.create_layer(0);

lattice_parameter = 77.94e3;
comsol_modeler.add_parameter("lattice_parameter", lattice_parameter, "nm");
fillet_radius = 5.62e3;
comsol_modeler.add_parameter("fillet_radius", fillet_radius, "nm");
triangle_edge_length = 35e3;
comsol_modeler.add_parameter("triangle_edge_length", triangle_edge_length, "nm");
tether_width = 5e3;

% First triangle of the unit cell (with left vertical edge)
triangle_vertices = [0, 0; 0, 1; sqrt(3)/2, 1/2]*triangle_edge_length;
triangle_1 = Polygon(Vertices=triangle_vertices, comsol_modeler=comsol_modeler);
triangle_1.round_corners(fillet_radius, 64, [1, 2, 3] );

% Define symmetry axis to get the other triangle of the unit cell. It is
% the axis rotated by pi/6 with respect to the vertical axis
triangle_2 = triangle_1.copy;
triangle_2.flip_horizontally(-tether_width);
unit_cell = triangle_1+triangle_2;
unit_cell.rotate(30);



gds_modeler.add_to_layer(layer, unit_cell)



gds_modeler.write("round_corner_test.gds")
% Plot Comsol geometry in Matlab 
comsol_modeler.plot;
% Export model in .m file
% comsol_modeler.save_to_m_file;
