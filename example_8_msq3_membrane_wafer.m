import core.*
import types.*
import primitives.*
import ops.*

% Example 8: MSQ3 membrane wafer tiling using Array2D + unwanted indices.
% Default is GDS-only because full-wafer COMSOL build is heavy.
use_comsol = false;
use_gds = true;
comsol_api = "mph";   % "mph" or "livelink"
preview_klayout = true;

ctx = GeometryPipeline.with_shared_comsol(enable_comsol=use_comsol, enable_gds=use_gds, ...
    comsol_api=comsol_api, ...
    preview_klayout=preview_klayout, ...
    snap_on_grid=false, gds_resolution_nm=1, warn_on_snap=true, ...
    reset_model=true, clean_on_reset=false);

ctx.add_layer("wafer", gds_layer=90, gds_datatype=0);
ctx.add_layer("backside", gds_layer=10, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="backside_opening", comsol_selection_state="all");
ctx.add_layer("membrane", gds_layer=11, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="membrane", comsol_selection_state="all");
ctx.add_layer("front_sin", gds_layer=13, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="front_sin", comsol_selection_state="all");
ctx.add_layer("front_al", gds_layer=33, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="front_al", comsol_selection_state="all");

p_um = Parameter(1, "ex8_u", unit="um");

% Wafer and chip params (from MSQ3 wafers/scripts).
p_wafer_diam = Parameter(50800, "ex8_wafer_diam", unit="um");
p_wafer_flat = Parameter(15500, "ex8_wafer_flat", unit="um");
p_chip_w = Parameter(6000, "ex8_chip_w", unit="um");
p_chip_h = Parameter(6000, "ex8_chip_h", unit="um");
p_mem_off_x = Parameter(0, "ex8_mem_off_x", unit="um");
p_mem_off_y = Parameter(0, "ex8_mem_off_y", unit="um");

p_mem_w = Parameter(140, "ex8_mem_w", unit="um");
p_mem_h = Parameter(110, "ex8_mem_h", unit="um");
p_wafer_thk = Parameter(280, "ex8_wafer_thk", unit="um");
p_tan_etch = Parameter(1.412, "ex8_tan_etch", unit="", auto_register=false);
p_overetch = Parameter(8, "ex8_overetch", unit="um");

p_al_margin = Parameter(10, "ex8_al_margin", unit="um");
p_bias_dist = Parameter(90, "ex8_bias_dist", unit="um");
p_bias_w = Parameter(100, "ex8_bias_w", unit="um");
p_bias_h = Parameter(100, "ex8_bias_h", unit="um");
p_bias_conn_w = Parameter(20, "ex8_bias_conn_w", unit="um");

p_koh_margin = Parameter(40, "ex8_koh_margin", unit="um");
p_koh_corner = Parameter(40, "ex8_koh_corner", unit="um");
p_pillar_size = Parameter(300, "ex8_pillar_size", unit="um");
p_pillar_loc_x = Parameter(700, "ex8_pillar_loc_x", unit="um");
p_pillar_loc_y = Parameter(700, "ex8_pillar_loc_y", unit="um");

p_back_extra = 2 * p_wafer_thk / p_tan_etch - 2 * p_overetch;
p_back_w = p_mem_w + p_back_extra;
p_back_h = p_mem_h + p_back_extra;
p_al_w = p_mem_w - 2 * p_al_margin;
p_al_h = p_mem_h - 2 * p_al_margin;
p_bias_pad_loc_x = p_al_w / 2 + p_bias_dist + p_bias_w / 2;
p_koh_center_dx = 0.5 * (p_bias_dist - p_al_margin + p_bias_w);
p_koh_w = p_mem_w - p_al_margin + p_bias_dist + p_bias_w + 2 * p_koh_margin;
p_koh_h = p_mem_h + 2 * p_koh_margin;

mem_offset_um = [p_mem_off_x.value, p_mem_off_y.value];

% Wafer outline with flat.
wafer_flat_h_um = sqrt((p_wafer_diam.value / 2)^2 - (p_wafer_flat.value^2) / 4);
wafer_disk = Circle(ctx, center=Vertices([0, 0], p_um), radius=p_wafer_diam / 2, layer="wafer");
wafer_flat_cut = Rectangle(ctx, base="corner", ...
    corner=Vertices([-0.5 * p_wafer_diam.value, wafer_flat_h_um], p_um), ...
    width=p_wafer_diam, height=p_wafer_diam, layer="wafer");
wafer_outline = Difference(ctx, wafer_disk, {wafer_flat_cut}, layer="wafer"); %#ok<NASGU>

% Rectangular grid and outside-wafer pruning indices.
x_range_um = p_wafer_diam.value;
y_range_um = p_wafer_diam.value / 2 + wafer_flat_h_um;
nx = floor(x_range_um / p_chip_w.value);
ny = floor(y_range_um / p_chip_h.value);
x_centers_um = ((-nx / 2):(nx / 2 - 1)) * p_chip_w.value;
y_centers_um = ((-ny / 2):(ny / 2 - 1)) * p_chip_h.value;

[ix_grid, iy_grid] = ndgrid(1:nx, 1:ny);
chip_x_um = x_centers_um(ix_grid);
chip_y_um = y_centers_um(iy_grid);
inside_mask = (abs(chip_x_um) + p_chip_w.value / 2).^2 + ...
    (abs(chip_y_um) + p_chip_h.value / 2).^2 < (p_wafer_diam.value / 2)^2;
unwanted_grid = [ix_grid(~inside_mask), iy_grid(~inside_mask)];
placed = nnz(inside_mask);

chip_seed_center_um = [x_centers_um(1), y_centers_um(1)];
mem_seed_center_um = chip_seed_center_um + mem_offset_um;
grid_dx = Vertices([p_chip_w.value, 0], p_um);
grid_dy = Vertices([0, p_chip_h.value], p_um);

% Membrane and backside opening.
membrane_seed = Rectangle(ctx, center=Vertices(mem_seed_center_um, p_um), ...
    width=p_mem_w, height=p_mem_h, layer="membrane");
membrane = Array2D(ctx, membrane_seed, ncopies_x=nx, ncopies_y=ny, ...
    delta_x=grid_dx, delta_y=grid_dy, ...
    unwanted_array_elements=unwanted_grid, layer="membrane"); %#ok<NASGU>

backside_seed = Rectangle(ctx, center=Vertices(mem_seed_center_um, p_um), ...
    width=p_back_w, height=p_back_h, layer="backside");
backside = Array2D(ctx, backside_seed, ncopies_x=nx, ncopies_y=ny, ...
    delta_x=grid_dx, delta_y=grid_dy, ...
    unwanted_array_elements=unwanted_grid, layer="backside"); %#ok<NASGU>

% Frontside AL.
al_inside_seed = Rectangle(ctx, center=Vertices(mem_seed_center_um, p_um), ...
    width=p_al_w, height=p_al_h, layer="front_al");
bias_pad_seed = Rectangle(ctx, ...
    center=Vertices(mem_seed_center_um + [p_bias_pad_loc_x.value, 0], p_um), ...
    width=p_bias_w, height=p_bias_h, layer="front_al");
al_connector_seed = Rectangle(ctx, ...
    center=Vertices(mem_seed_center_um + [0.5 * p_bias_pad_loc_x.value, 0], p_um), ...
    width=p_bias_pad_loc_x, height=p_bias_conn_w, layer="front_al");
al_layer_seed = Union(ctx, {al_inside_seed, bias_pad_seed, al_connector_seed}, layer="front_al");
al_layer = Array2D(ctx, al_layer_seed, ncopies_x=nx, ncopies_y=ny, ...
    delta_x=grid_dx, delta_y=grid_dy, ...
    unwanted_array_elements=unwanted_grid, layer="front_al"); %#ok<NASGU>

% Frontside SiN positive seed (KOH + pillars).
koh_center_seed_um = mem_seed_center_um + [p_koh_center_dx.value, 0];
koh_main_seed = Rectangle(ctx, center=Vertices(koh_center_seed_um, p_um), ...
    width=p_koh_w, height=p_koh_h, layer="front_sin");
koh_corner_seed = Rectangle(ctx, ...
    center=Vertices(koh_center_seed_um + [-0.5 * p_koh_w.value, -0.5 * p_koh_h.value], p_um), ...
    width=p_koh_corner, height=p_koh_corner, layer="front_sin");
koh_corners_seed = Array2D(ctx, koh_corner_seed, ncopies_x=2, ncopies_y=2, ...
    delta_x=Vertices([1, 0], p_koh_w), delta_y=Vertices([0, 1], p_koh_h), layer="front_sin");
koh_layer_seed = Union(ctx, {koh_main_seed, koh_corners_seed}, layer="front_sin");

pillar_seed_center_um = mem_seed_center_um + [-p_pillar_loc_x.value, -p_pillar_loc_y.value];
pillar_seed = Rectangle(ctx, center=Vertices(pillar_seed_center_um, p_um), ...
    width=p_pillar_size, height=p_pillar_size, layer="front_sin");
pillar_corner_seed = Rectangle(ctx, ...
    center=Vertices(pillar_seed_center_um + [-0.5 * p_pillar_size.value, -0.5 * p_pillar_size.value], p_um), ...
    width=p_koh_corner, height=p_koh_corner, layer="front_sin");
pillar_corners_seed = Array2D(ctx, pillar_corner_seed, ncopies_x=2, ncopies_y=2, ...
    delta_x=Vertices([1, 0], p_pillar_size), delta_y=Vertices([0, 1], p_pillar_size), ...
    layer="front_sin");
pillar_template_seed = Union(ctx, {pillar_seed, pillar_corners_seed}, layer="front_sin");
pillars_layer_seed = Array2D(ctx, pillar_template_seed, ncopies_x=2, ncopies_y=2, ...
    delta_x=Vertices([2 * p_pillar_loc_x.value, 0], p_um), ...
    delta_y=Vertices([0, 2 * p_pillar_loc_y.value], p_um), layer="front_sin");

sin_positive_seed = Union(ctx, {koh_layer_seed, pillars_layer_seed}, layer="front_sin");
chip_rect_seed = Rectangle(ctx, center=Vertices(chip_seed_center_um, p_um), ...
    width=p_chip_w, height=p_chip_h, layer="front_sin");
sin_negative_seed = Difference(ctx, chip_rect_seed, {sin_positive_seed}, layer="front_sin");
sin_negative = Array2D(ctx, sin_negative_seed, ncopies_x=nx, ncopies_y=ny, ...
    delta_x=grid_dx, delta_y=grid_dy, ...
    unwanted_array_elements=unwanted_grid, layer="front_sin"); %#ok<NASGU>

fprintf("Example 8 wafer diameter: %.3f um, flat: %.3f um\n", p_wafer_diam.value, p_wafer_flat.value);
fprintf("Example 8 chip grid: nx=%d ny=%d\n", nx, ny);
fprintf("Example 8 placed chips: %d\n", placed);

ctx.build();
