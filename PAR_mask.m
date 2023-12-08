model = Model;

wafer_thickness = 350;
etching_angle = 54.74;
etching_distance = wafer_thickness/tan(etching_angle*pi/180);
mesa_SIN_suspension_width = 10;
mesa_SI_suspension_width = 10;


% "Structure" refers to front side SiN structures, not backside
structure_width = 3000;
tether_length = 2000;
mesa_rough_height = 3000;
tether_widths = [repmat([150, 50, 25, 10], 1, 3), 150];
tether_spacing = (structure_width -2*etching_distance -...
                  2*mesa_SIN_suspension_width - ...
                  sum(tether_widths))/(length(tether_widths)-1);
disp("tether_spacing " + num2str(tether_spacing))
fillet_width = tether_spacing/2;
fillet_height = 120;

% BACK SIDE LAYER
back_side_layer = model.create_layer(1);

% Back side rectangle opening for tethers defined with center, width and height
top_box = Box(center=[0, 0], ...
              width=structure_width+2*etching_distance, ...
              height=tether_length+2*etching_distance);
% Left opening for mesa
left_box = Box(left=top_box.left, ...
               right=top_box.bottom-mesa_rough_height-mesa_SI_suspension_width,...
               bottom=top_box.left+2*etching_distance+mesa_SIN_suspension_width, ...
               top=top_box.bottom-mesa_SI_suspension_width);
% Right opening for mesa
right_box = copy(left_box);
right_box.translate([structure_width-mesa_SIN_suspension_width, 0]);
% Bottom opening for mesa
bottom_box = Box(left=left_box.left, ...
                 right=left_box.bottom-mesa_SI_suspension_width, ...
                 bottom=right_box.right, ...
                 top=left_box.bottom-mesa_SI_suspension_width-2*etching_distance);

model.add_to_layer(back_side_layer, left_box)
model.add_to_layer(back_side_layer, right_box)
model.add_to_layer(back_side_layer, bottom_box)
model.add_to_layer(back_side_layer, top_box)

model.write("Par_mask_matlab.gds")