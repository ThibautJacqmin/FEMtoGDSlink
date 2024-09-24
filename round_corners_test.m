% Transformer ce fichier en classe avec fonction pour ajouter les
% propriétés automatiquement
warning('off');
gm = GDSModeler;


if ~exist('comsol_modeler', 'var')
    cm = ComsolModeler;
    cm.start_gui;
end

% BACK SIDE LAYER
layer = gm.create_layer(0);

lattice_parameter = Parameter("lattice_parameter", 77.94e3, comsol_modeler=cm);
fillet_radius = Parameter("fillet_radius", 5.62e3, comsol_modeler=cm);
fillet_npoints = Parameter("fillet_npoints", 64, comsol_modeler=cm);
triangle_edge_length = Parameter("triangle_edge_length", 35e3, comsol_modeler=cm);
tether_width = Parameter("tether_width", 5e3, comsol_modeler=cm);

% First triangle of the unit cell (with left vertical edge)
triangle_vertices = Vertices([0, 0; 0, 1; sqrt(3)/2, 1/2], triangle_edge_length);
triangle_1 = Polygon(Vertices=triangle_vertices, comsol_modeler=cm);
triangle_1.round_corners(fillet_radius, fillet_npoints);

% Define symmetry axis to get the other triangle of the unit cell. It is
% the axis rotated by pi/6 with respect to the vertical axis
triangle_2 = triangle_1.copy;
flip_axis = DependentParameter("flip_axis", @(x)(-x/2), tether_width, comsol_modeler=cm);
triangle_2.flip_horizontally(flip_axis);
unit_cell = triangle_1+triangle_2;




gm.add_to_layer(layer, unit_cell)



gm.write("round_corner_test.gds")
% Plot Comsol geometry in Matlab 
cm.plot;
% Export model in .m file
% comsol_modeler.save_to_m_file;
