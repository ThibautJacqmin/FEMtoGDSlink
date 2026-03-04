import core.*
import types.*
import primitives.*
import ops.*

% Example 10: PAR mask ported from legacy GDSModeler script.
% All geometry values are kept in nm to preserve legacy dimensions exactly.
use_comsol = true;
use_gds = true;
comsol_api = "mph";      % "mph" or "livelink"
preview_klayout = true;

ctx = GeometryPipeline( ...
    enable_comsol=use_comsol, ...
    enable_gds=use_gds, ...
    comsol_api=comsol_api, ...
    preview_klayout=preview_klayout, ...
    snap_on_grid=false, ...
    gds_resolution_nm=1, ...
    warn_on_snap=true);

ctx.add_layer("back_side_bottom", gds_layer=0, gds_datatype=0);
ctx.add_layer("back_side_top", gds_layer=1, gds_datatype=0);
ctx.add_layer("front_side_1", gds_layer=2, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="front_side", comsol_selection_state="all");
for i =2:4
ctx.add_layer("front_side_" + string(i), gds_layer=2, gds_datatype=0);
end
ctx.add_layer("wafer", gds_layer=3, gds_datatype=0);

% Shared structure parameters (defined once, reused for every structure).
geom = struct();
geom.wafer_thickness = types.Parameter(300e3, "wafer_thickness");
geom.etching_angle_deg = types.Parameter(54.74, "etching_angle_deg", unit="");
geom.etching_distance = types.Parameter( ...
    geom.wafer_thickness.value / tan(deg2rad(geom.etching_angle_deg.value)), ...
    "etching_distance");
geom.mesa_sin_suspension = types.Parameter(500e3, "mesa_sin_suspension_width");
geom.mesa_sin_bottom_suspension = types.Parameter(200e3, "mesa_sin_bottom_suspension_width");
geom.mesa_si_suspension = types.Parameter(25e3, "mesa_si_suspension_width");
geom.mesa_hole_width = types.Parameter(1600e3, "mesa_hole_width");
geom.structure_width = types.Parameter(4920e3, "structure_width");
geom.tether_length = types.Parameter(2000e3, "tether_length");
geom.mesa_rough_height = types.Parameter(3500e3, "mesa_rough_height");

geom.tether_width_set = { ...
    types.Parameter(120e3, "tether_width_1"), ...
    types.Parameter(80e3, "tether_width_2"), ...
    types.Parameter(60e3, "tether_width_3"), ...
    types.Parameter(40e3, "tether_width_4"), ...
    types.Parameter(20e3, "tether_width_5")};
geom.tether_width_indices = [repmat(1:5, 1, 4), 1];

sum_tether_widths = geom.tether_width_set{geom.tether_width_indices(1)};
for i = 2:numel(geom.tether_width_indices)
    sum_tether_widths = sum_tether_widths + geom.tether_width_set{geom.tether_width_indices(i)};
end

geom.tether_spacing = types.Parameter((geom.structure_width ...
    - 2 * geom.etching_distance ...
    - 2 * geom.mesa_sin_suspension ...
    - sum_tether_widths) / (numel(geom.tether_width_indices) - 1), ...
    "tether_spacing");
geom.fillet_width = types.Parameter(geom.tether_spacing.value / 2, "fillet_width");
geom.fillet_height = types.Parameter(120e3, "fillet_height");
geom.mark_distance = types.Parameter(300e3, "mark_distance");
geom.mark_pitch = types.Parameter(200e3, "mark_pitch");

% Packaged alignment mark from Library/alignment_mark_type_1.mat.
mark_seed = components.markers.alignment_mark(ctx, type=1, layer="back_side_bottom");

% Four structures.
structure_positions_nm = 1e3 * [ ...
    -15000, -12250; ...
    -5000,  -18250; ...
    5000,   -18250; ...
    15000,  -12250];
alignment_mark_counts = [1, 2, 3, 4];

for i = 1:size(structure_positions_nm, 1)
    generate_structure(ctx, structure_positions_nm(i, :), alignment_mark_counts(i), ...
        layer_front="front_side_" + string(i), ...
        layer_back_bottom="back_side_bottom", ...
        geom=geom, ...
        mark_seed=mark_seed);
end

% Packaged 2-inch wafer polygon from Library/two_inch_wafer.mat.
components.wafer.two_inch(ctx, layer="wafer");

% Square etching flag window.
Square(ctx, center=[0, 16350e3], side=3000e3, layer="back_side_top");

% Glue grooves.
for i = 1:29
    y_nm = 11000e3 + 300e3 * i;
    Rectangle(ctx, center=[8500e3, y_nm], width=8000e3, height=100e3, layer="back_side_top");
    Rectangle(ctx, center=[-8500e3, y_nm], width=8000e3, height=100e3, layer="back_side_top");
end

out = ctx.build(gds_filename="Par_mask_matlab_test.gds");

if out.built_gds
    fprintf("PAR mask GDS written: %s\n", string(out.gds_filename));
end
if out.built_comsol
    fprintf("PAR mask COMSOL geometry emitted on workplane wp1.\n");
end


function generate_structure(ctx, structure_position_nm, number_of_alignment_marks, args)
arguments
    ctx core.GeometryPipeline
    structure_position_nm (1,2) double
    number_of_alignment_marks (1,1) double {mustBeInteger, mustBePositive}
    args.layer_front {mustBeTextScalar} = "front_side"
    args.layer_back_bottom {mustBeTextScalar} = "back_side_bottom"
    args.geom struct
    args.mark_seed core.GeomFeature
end

p = args.geom;

top_box_height = p.tether_length + 2 * p.etching_distance;
top_box_width = p.structure_width + 2 * p.etching_distance;
top_box_height_v = top_box_height.value;
top_box_width_v = top_box_width.value;

top_center = structure_position_nm;
top_center(2) = top_center(2) ...
    + 0.5 * top_box_height_v ...
    + 0.5 * p.mesa_rough_height.value ...
    + p.mesa_si_suspension.value;

top_left = top_center(1) - 0.5 * top_box_width_v;
top_bottom = top_center(2) - 0.5 * top_box_height_v;
top_top = top_center(2) + 0.5 * top_box_height_v;

top_box = primitives.Rectangle(ctx, center=top_center, ...
    width=top_box_width, height=top_box_height, layer=args.layer_back_bottom); %#ok<NASGU>

left_box_width = 2 * p.etching_distance + p.mesa_sin_suspension;
left_box_height = p.mesa_rough_height;
left_box_width_v = left_box_width.value;
left_box_height_v = left_box_height.value;
left_top = top_bottom - p.mesa_si_suspension.value;
left_bottom = left_top - left_box_height_v;
left_center = [top_left + 0.5 * left_box_width_v, left_bottom + 0.5 * left_box_height_v];
left_box = primitives.Rectangle(ctx, center=left_center, ...
    width=left_box_width, height=left_box_height, layer=args.layer_back_bottom); %#ok<NASGU>

right_shift = p.structure_width - p.mesa_sin_suspension;
right_center = left_center + [right_shift.value, 0];
right_box = primitives.Rectangle(ctx, center=right_center, ...
    width=left_box_width, height=left_box_height, layer=args.layer_back_bottom); %#ok<NASGU>

bottom_box_height = 2 * p.etching_distance + p.mesa_sin_bottom_suspension;
bottom_box_height_v = bottom_box_height.value;
bottom_top = left_bottom - p.mesa_si_suspension.value;
bottom_center = [top_center(1), bottom_top - 0.5 * bottom_box_height_v];
bottom_box = primitives.Rectangle(ctx, center=bottom_center, ...
    width=top_box_width, height=bottom_box_height, layer=args.layer_back_bottom); %#ok<NASGU>

mesa_hole_size = p.mesa_hole_width + 2 * p.etching_distance;
mesa_hole_center = [top_center(1), 0.5 * (bottom_top + top_bottom)];
mesa_hole = primitives.Rectangle(ctx, center=mesa_hole_center, ...
    width=mesa_hole_size, height=mesa_hole_size, layer=args.layer_back_bottom); %#ok<NASGU>

% Front-side tether mask.
inner_bottom = top_bottom + p.etching_distance.value;
inner_top = top_top - p.etching_distance.value;
inner_height = inner_top - inner_bottom;
inner_center = [top_center(1), 0.5 * (inner_bottom + inner_top)];

front_box = primitives.Rectangle(ctx, center=inner_center, ...
    width=top_box_width, height=inner_height, layer=args.layer_front);

tether_shapes = cell(1, numel(p.tether_width_indices));
accumulated_width_v = 0;
left_box_right = top_left + left_box_width_v;
tether_spacing_v = p.tether_spacing.value;

for i = 1:numel(p.tether_width_indices)
    tether_w = p.tether_width_set{p.tether_width_indices(i)};
    tether_w_v = tether_w.value;
    tether_left = left_box_right + tether_spacing_v * (i - 1) + accumulated_width_v;
    tether_center = [tether_left + 0.5 * tether_w_v, inner_center(2)];

    tether = primitives.Rectangle(ctx, center=tether_center, ...
        width=tether_w, height=inner_height, ...
        fillet_width=p.fillet_width, fillet_height=p.fillet_height, ...
        layer=args.layer_front);
    fillets = tether.get_fillets(layer=args.layer_front);
    tether_shapes{i} = ops.Union(ctx, [{tether}, fillets], layer=args.layer_front);
    accumulated_width_v = accumulated_width_v + tether_w_v;
end

front_skeleton = ops.Difference(ctx, front_box, tether_shapes, layer=args.layer_front); %#ok<NASGU>

mesa_opening_size = p.mesa_hole_width;
mesa_opening = primitives.Rectangle(ctx, center=mesa_hole_center, ...
    width=mesa_opening_size, height=mesa_opening_size, ...
    layer=args.layer_front); %#ok<NASGU>

% Alignment marks on backside bottom.
mark_anchor = [ ...
    right_center(1) + left_box_width_v + p.mark_distance.value, ...
    left_top];
mark_placed = ops.Move(ctx, args.mark_seed, ...
    delta=mark_anchor, keep_input_objects=true, layer=args.layer_back_bottom);
marks = ops.Array2D(ctx, mark_placed, ncopies_x=1, ncopies_y=number_of_alignment_marks, ...
    delta_x=[1, 0], delta_y=[0, p.mark_pitch.value], layer=args.layer_back_bottom); %#ok<NASGU>
end
