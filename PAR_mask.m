% Transformer ce fichier en classe avec fonction pour ajouter les
% propriétés automatiquement
warning('off');
gds_modeler = GDSModeler;
%comsol_modeler = ComsolModeler;

wafer_thickness = 280e3; 
etching_angle = 54.74;
etching_distance = wafer_thickness/tan(etching_angle*pi/180);
mesa_SIN_suspension_width = 20e3;
mesa_SI_suspension_width = 5e3;


% "Structure" refers to front side SiN structures, not backside
structure_width = 4000e3;
tether_length = 2000e3;
mesa_rough_height = 4000e3;
tether_widths = [repmat([120, 80, 60, 40, 20], 1, 4), 120]*1e3;
tether_spacing = (structure_width -2*etching_distance...
                  - 2*mesa_SIN_suspension_width...
                  - sum(tether_widths))/(length(tether_widths)-1);
disp("tether_spacing " + num2str(tether_spacing))
fillet_width = tether_spacing/2;
fillet_height = 120e3;

% BACK SIDE LAYER
back_side_layer = gds_modeler.create_layer(1);

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
right_box = left_box.copy;
right_box.move([structure_width-mesa_SIN_suspension_width, 0]);
% Bottom opening for mesa
bottom_box = Box(left=left_box.left, ...
                 right=right_box.right, ...
                 bottom=left_box.bottom-mesa_SI_suspension_width, ...
                 top=left_box.bottom-mesa_SI_suspension_width-2*etching_distance);

gds_modeler.add_to_layer(back_side_layer, left_box)
gds_modeler.add_to_layer(back_side_layer, right_box)
gds_modeler.add_to_layer(back_side_layer, bottom_box)
gds_modeler.add_to_layer(back_side_layer, top_box)

% FRONT SIDE LAYER
front_side_layer = gds_modeler.create_layer(2);
fillets = {};
tethers = {};
previous_tether_width = 0;
i = 1;
for tether_width=tether_widths(1)
    accumulated_width = sum(previous_tether_width);
    tether = Box(left=left_box.right+(i-1)*tether_spacing + accumulated_width, ...
                 right=left_box.right + tether_width + (i-1)*tether_spacing + accumulated_width,...
                 bottom=top_box.bottom + etching_distance, ...
                 top=top_box.top - etching_distance,...
                 fillet_height=fillet_height,...
                 fillet_width=fillet_width, ...
                 comsol_modeler=comsol_modeler);
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
mark.move([0, bottom_box.bottom-1000e3]);
gds_modeler.add_to_layer(front_side_layer, mark);

% Make array
gds_modeler.make_array(10000*1e3, 0, 3, 1);

gds_modeler.plot;
gds_modeler.write("Par_mask_matlab.gds")
% Plot Comsol geometry in Matlab 
comsol_modeler.plot;
% Export model in .m file
% comsol_modeler.save_to_m_file;
