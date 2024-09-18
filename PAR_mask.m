% Transformer ce fichier en classe avec fonction pour ajouter les
% propriétés automatiquement
warning('off');
gds_modeler = GDSModeler;
% if ~exist('comsol_modeler', 'var')
%     comsol_modeler = ComsolModeler;
% end

wafer_thickness = 280e3; 
etching_angle = 54.74;
etching_distance = wafer_thickness/tan(etching_angle*pi/180);
mesa_SIN_suspension_width = 40e3;
mesa_SI_suspension_width = 5e3;
mesa_hole_width = 1600e3;
number_of_structures = 4;
distance_between_structures = 10000e3;
centering = -15000e3;
Si_suspension_hole_width = 100e3;

% "Structure" refers to front side SiN structures, not backside
structure_width = 4000e3;
tether_length = 2000e3;
mesa_rough_height = 3500e3;
tether_widths = [repmat([120, 80, 60, 40, 20], 1, 4), 120]*1e3;
tether_spacing = (structure_width -2*etching_distance...
                  - 2*mesa_SIN_suspension_width...
                  - sum(tether_widths))/(length(tether_widths)-1);
disp("tether_spacing " + num2str(tether_spacing))
fillet_width = tether_spacing/2;
fillet_height = 120e3;

% BACK SIDE LAYER
back_side_layer = gds_modeler.create_layer(0);

% Back side rectangle opening for tethers defined with center, width and height
top_box = Box(center=[centering, 0], ...
              width=structure_width+2*etching_distance, ...
              height=tether_length+2*etching_distance);
% Left opening for mesa
left_box = Box(left=top_box.left, ...
               right=top_box.left+2*etching_distance+mesa_SIN_suspension_width,...
               bottom=top_box.bottom-mesa_rough_height-mesa_SI_suspension_width,...                   
               top=top_box.bottom-mesa_SI_suspension_width);

% Right opening for mesa
right_box = left_box.copy;
right_box.move([structure_width-mesa_SIN_suspension_width, 0]);
% Bottom opening for mesa
bottom_box = Box(left=left_box.left, ...
                 right=right_box.right, ...
                 top=left_box.bottom-mesa_SI_suspension_width, ...
                 bottom=left_box.bottom-mesa_SI_suspension_width-2*etching_distance);

% Mesa hole
mesa_hole = Box(center=[top_box.center(1), (bottom_box.top+top_box.bottom)/2], ...
              width=mesa_hole_width+2*etching_distance, ...
              height=mesa_hole_width+2*etching_distance);


gds_modeler.add_to_layer(back_side_layer, left_box)
gds_modeler.add_to_layer(back_side_layer, right_box)
gds_modeler.add_to_layer(back_side_layer, bottom_box)
gds_modeler.add_to_layer(back_side_layer, top_box)
gds_modeler.add_to_layer(back_side_layer, mesa_hole)

% FRONT SIDE LAYER
front_side_layer = gds_modeler.create_layer(1);
fillets = {};
tethers = {};
previous_tether_width = 0;
i = 1;
for tether_width=tether_widths
    accumulated_width = sum(previous_tether_width);
    tether = Box(left=left_box.right+(i-1)*tether_spacing + accumulated_width, ...
                 right=left_box.right + tether_width + (i-1)*tether_spacing + accumulated_width,...
                 bottom=top_box.bottom + etching_distance, ...
                 top=top_box.top - etching_distance,...
                 fillet_height=fillet_height,...
                 fillet_width=fillet_width);
    fillets = tether.get_fillets;
    tethers{end+1} = tether+fillets{1}+fillets{2}+fillets{3}+fillets{4};
    previous_tether_width(end+1) = tether_width;
    i = i+1;
end

% Create box for subtraction
temp_box = Box(left=top_box.left,...
               right=top_box.right,...
               top=tether.top,...
               bottom=tether.bottom);
% Subtract
for i = 1:length(tethers)
     temp_box = temp_box-tethers{i};
end
gds_modeler.add_to_layer(front_side_layer, temp_box);

% Add alignment mark
mark = gds_modeler.add_alignment_mark(type=1);
mark.move([top_box.center(1), bottom_box.bottom-1000e3]);
gds_modeler.add_to_layer(back_side_layer, mark);

% Add 2 inch wafer
wafer_layer = gds_modeler.create_layer(2);
wafer = gds_modeler.add_two_inch_wafer;
gds_modeler.add_to_layer(wafer_layer, wafer);

% Make array
gds_modeler.make_array(distance_between_structures, 0, number_of_structures-1, 1, layer=0);
gds_modeler.make_array(distance_between_structures, 0, number_of_structures-1, 1, layer=1);

% Add hole in 1/2 bridges
hole_box_top_left = Box(center=[left_box.center(1),  left_box.top+mesa_SI_suspension_width/2], ...
              width=Si_suspension_hole_width, ...
              height=mesa_SI_suspension_width);
hole_box_bottom_left = hole_box_top_left.copy;
hole_box_bottom_left.move([0, -left_box.height-mesa_SI_suspension_width]);
hole_box_bottom_right = hole_box_bottom_left.copy;
hole_box_bottom_right.move([bottom_box.width-right_box.width, 0]);
hole_box_top_right = hole_box_top_left.copy;
hole_box_top_right.move([bottom_box.width-right_box.width, 0]);
gds_modeler.add_to_layer(back_side_layer, hole_box_top_left)
gds_modeler.add_to_layer(back_side_layer, hole_box_bottom_left)
gds_modeler.add_to_layer(back_side_layer, hole_box_bottom_right)
gds_modeler.add_to_layer(back_side_layer, hole_box_top_right)


gds_modeler.write("Par_mask_matlab_test.gds")
% Plot Comsol geometry in Matlab 
%comsol_modeler.plot;
% Export model in .m file
% comsol_modeler.save_to_m_file;
