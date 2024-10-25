warning('off');
gds_modeler = GDSModeler;

% BACK SIDE LAYER
back_side_layer = gds_modeler.create_layer(0);

wafer_thickness = Parameter("wafer_thickness", 280e3);
etching_angle = 54.74;
% Needs to implement multiple variables in DependentParameters etching
% distance should be a depent parameter. Should implement addition and
% scalar multipication for dependent parameters
etching_distance = Parameter("etching_distance", wafer_thickness.value/tan(etching_angle*pi/180));

% Add square windows of various sizes
window_size = linspace(100e3, 3000e3, 17)+ 2*etching_distance.value;
window_size = [window_size(1:2:end), fliplr(window_size(2:2:end))];
spacing = 500e3;
for j = [-10000e3, -5000e3, 0, 5000e3, 10000e3]
    for i = 1:length(window_size)
        side_length = Parameter("side_length",window_size(i));
        center = Vertices([-20500e3+spacing*(i-1)+sum(window_size(1:i-1))+window_size(i)/2, j]);
        b = Box(center=center, width=side_length, height=side_length);
        gds_modeler.add_to_layer(back_side_layer, b);
    end
end

for j = [-15000e3, 15000e3]
for i = 4:length(window_size)-3
        side_length = Parameter("side_length",window_size(i));
        center = Vertices([-20500e3+spacing*(i-1)+sum(window_size(1:i-1))+window_size(i)/2,j]);
        b = Box(center=center, width=side_length, height=side_length);
        gds_modeler.add_to_layer(back_side_layer, b);
end
end


for i = 1:length(window_size)-3
    val = 500e3+2*etching_distance.value;
        side_length = Parameter("side_length", val);
        center = Vertices([-10000e3+spacing*(i-1)+val*i+250e3,19000e3]);
        b = Box(center=center, width=side_length, height=side_length);
        gds_modeler.add_to_layer(back_side_layer, b);
end

for i = 1:length(window_size)-7
    val = 1000e3+2*etching_distance.value;
        side_length = Parameter("side_length", val);
        center = Vertices([-10000e3+spacing*(i-1)+val*i+500e3,-19000e3]);
        b = Box(center=center, width=side_length, height=side_length);
        gds_modeler.add_to_layer(back_side_layer, b);
end



% Add 2 inch wafer
wafer_layer = gds_modeler.create_layer(1);
wafer = gds_modeler.add_two_inch_wafer;
gds_modeler.add_to_layer(wafer_layer, wafer);


gds_modeler.write("D_mask.gds")