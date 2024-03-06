% Transformer ce fichier en classe avec fonction pour ajouter les
% propriétés automatiquement

model = GDSModeler;

wafer_thickness = 280;
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
               right=top_box.left+2*etching_distance+mesa_SIN_suspension_width,...
               bottom=top_box.bottom-mesa_rough_height-mesa_SI_suspension_width,...                   
               top=top_box.bottom-mesa_SI_suspension_width);
% Right opening for mesa
right_box = left_box.translate([structure_width-mesa_SIN_suspension_width, 0]);
% Bottom opening for mesa
bottom_box = Box(left=left_box.left, ...
                 right=right_box.right, ...
                 bottom=left_box.bottom-mesa_SI_suspension_width, ...
                 top=left_box.bottom-mesa_SI_suspension_width-2*etching_distance);

model.add_to_layer(back_side_layer, left_box)
model.add_to_layer(back_side_layer, right_box)
model.add_to_layer(back_side_layer, bottom_box)
model.add_to_layer(back_side_layer, top_box)

% FRONT SIDE LAYER
front_side_layer = model.create_layer(2);
filleted_tether_list = {};
previous_tether_width = 0;
i = 1;
for tether_width=tether_widths
    accumulated_width = sum(previous_tether_width);
    tether = Box(left=left_box.right+(i-1)*tether_spacing + accumulated_width, ...
                 bottom=top_box.bottom + etching_distance, ...
                 right=left_box.right + tether_width + (i-1)*tether_spacing + accumulated_width,...
                 top=top_box.top - etching_distance);
    tether.fillet_width = fillet_width;
    tether.fillet_height = fillet_height;
    filleted_tether = tether + tether.get_fillets;
    previous_tether_width(end+1) = tether_width;
    i = i+1;
    if i==2 | i==length(tether_widths)+1
        filleted_tether_list{end+1} = tether;
    else
        filleted_tether_list{end+1} = filleted_tether;
    end
end

% Create box for subtraction
temp_box = Box(left=top_box.left,...
               right=top_box.right,...
               top=tether.top,...
               bottom=tether.bottom);

model.add_to_layer(front_side_layer, temp_box-filleted_tether_list)

% mark = model.add_alignment_mark(type=1);
% mark = mark.translate([0, bottom_box.bottom-1000]);
% model.add_to_layer(front_side_layer, mark);


model.plot;
model.write("Par_mask_matlab.gds")