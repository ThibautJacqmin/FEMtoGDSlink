% Transformer ce fichier en classe avec fonction pour ajouter les
% propriétés automatiquement
warning('off');
gds_modeler = GDSModeler;
% if ~exist('comsol_modeler', 'var')
%     comsol_modeler = ComsolModeler;
% end


% BACK SIDE LAYER
back_side_layer_bottom = gds_modeler.create_layer(0);
back_side_layer_top = gds_modeler.create_layer(1);

% FRONT SIDE LAYER
front_side_layer = gds_modeler.create_layer(2);

structure_position_1 = Vertices([-15000e3, -12250e3]);
structure_position_2 = Vertices([-5000e3, -18250e3]);
structure_position_3 = Vertices([5000e3, -18250e3]);
structure_position_4 = Vertices([15000e3, -12250e3]);
generate_structure(structure_position_1, front_side_layer, back_side_layer_bottom, gds_modeler);
generate_structure(structure_position_2, front_side_layer, back_side_layer_bottom, gds_modeler);
generate_structure(structure_position_3, front_side_layer, back_side_layer_bottom, gds_modeler);
generate_structure(structure_position_4, front_side_layer, back_side_layer_bottom, gds_modeler);

% Add 2 inch wafer
wafer_layer = gds_modeler.create_layer(3);
wafer = gds_modeler.add_two_inch_wafer;
gds_modeler.add_to_layer(wafer_layer, wafer);

% Add square opening (etching flag window)
square_size = Parameter("square_size", 3000e3);
etching_flag_window = Box(center=Vertices([0, 16350e3]), width=square_size, ...
    height=square_size);
gds_modeler.add_to_layer(back_side_layer_top, etching_flag_window);

% Add glue grooves for gluing tight
for i = 1:29
    groove_width = Parameter("square_size", 100e3);
    groove_height = Parameter("square_size", 8000e3);
    groove_right = Box(center=Vertices([8500e3, 11000e3+300e3*i]), width=groove_height, ...
        height=groove_width);
    gds_modeler.add_to_layer(back_side_layer_top, groove_right);
    groove_left = Box(center=Vertices([-8500e3, 11000e3+300e3*i]), width=groove_height, ...
        height=groove_width);
    gds_modeler.add_to_layer(back_side_layer_top, groove_left);
end

gds_modeler.write("Par_mask_matlab_test.gds")

function generate_structure(structure_position, front_side_layer, back_side_layer_bottom, gds_modeler)

wafer_thickness = Parameter("wafer_thickness", 280e3);
etching_angle = 54.74;
% Needs to implement multiple variables in DependentParameters etching
% distance should be a depent parameter. Should implement addition and
% scalar multipication for dependent parameters
etching_distance = Parameter("etching_distance", wafer_thickness.value/tan(etching_angle*pi/180));
mesa_SIN_suspension_width = Parameter("mesa_SIN_suspension_width", 500e3);
mesa_SI_suspension_width = Parameter("mesa_SI_suspension_width", 15e3);
mesa_hole_width = Parameter("mesa_hole_width", 1600e3);


% "Structure" refers to front side SiN structures, not backside
structure_width = Parameter("structure_width", 4920e3);
tether_length = Parameter("structure_width", 2000e3);
mesa_rough_height = Parameter("structure_width", 3500e3);
tether_widths = [repmat([120, 80, 60, 40, 20], 1, 4), 120]*1e3;
tether_spacing = (structure_width.value -2*etching_distance.value...
    - 2*mesa_SIN_suspension_width.value...
    - sum(tether_widths))/(length(tether_widths)-1);
tether_spacing = Parameter("tether_spacing", tether_spacing);
disp("tether_spacing " + num2str(tether_spacing.value))
fillet_width = Parameter("fillet_width", tether_spacing.value/2);
fillet_height = Parameter("fillet_height", 120e3);


% Back side rectangle opening for tethers defined with center, width and height
top_box_height = tether_length+etching_distance.*2;
structure_position.array(1, 2) = structure_position.array(1, 2)+top_box_height.value/2+...
    mesa_rough_height.value/2 + mesa_SI_suspension_width.value;
top_box = Box(center=structure_position, ...
    width=structure_width+etching_distance.*2, ...
    height=top_box_height);
% Left opening for mesa
left_box = Box(left=top_box.left, ...
    right=top_box.left+etching_distance.*2+mesa_SIN_suspension_width,...
    bottom=top_box.bottom-mesa_rough_height-mesa_SI_suspension_width,...
    top=top_box.bottom-mesa_SI_suspension_width);

% Right opening for mesa
right_box = left_box.copy;
translation = structure_width-mesa_SIN_suspension_width;
right_box.move(Vertices([translation.value, 0]));
% Bottom opening for mesa
bottom_box = Box(left=left_box.left, ...
    right=right_box.right, ...
    top=left_box.bottom-mesa_SI_suspension_width, ...
    bottom=left_box.bottom-mesa_SI_suspension_width-etching_distance.*2);

% Mesa hole
mesa_hole = Box(center=Vertices([top_box.center.value(1), (bottom_box.top.value+top_box.bottom.value)/2]), ...
    width=mesa_hole_width+etching_distance.*2, ...
    height=mesa_hole_width+etching_distance.*2);


gds_modeler.add_to_layer(back_side_layer_bottom, left_box)
gds_modeler.add_to_layer(back_side_layer_bottom, right_box)
gds_modeler.add_to_layer(back_side_layer_bottom, bottom_box)
gds_modeler.add_to_layer(back_side_layer_bottom, top_box)
gds_modeler.add_to_layer(back_side_layer_bottom, mesa_hole)

fillets = {};
tethers = {};
previous_tether_width = 0;
i = 1;

for tether_width=tether_widths
    accumulated_width = Parameter("accumulated_width", sum(previous_tether_width));
    tether_width_p = Parameter("tether_width", tether_width);
    tether = Box(left=left_box.right+tether_spacing.*(i-1) + accumulated_width, ...
        right=left_box.right + tether_width_p + tether_spacing.*(i-1) + accumulated_width,...
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

% Add square on the mesa
mesa_opening = Box(center=mesa_hole.center.value, ...
    width=mesa_hole.width-etching_distance.*2, ...
    height=mesa_hole.height-etching_distance.*2);
gds_modeler.add_to_layer(front_side_layer, mesa_opening);


% Add alignment mark
mark_distance = 300e3;
mark = gds_modeler.add_alignment_mark(type=1);
mark.move(Vertices([right_box.center.value(1)+right_box.width.value+mark_distance, ...
    right_box.center.value(2)]));
gds_modeler.add_to_layer(back_side_layer_bottom, mark);

end


% Plot Comsol geometry in Matlab
%comsol_modeler.plot;
% Export model in .m file
% comsol_modeler.save_to_m_file;
