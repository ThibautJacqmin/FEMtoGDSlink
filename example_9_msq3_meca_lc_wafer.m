import core.*
import types.*
import primitives.*
import ops.*

% Example 9: MSQ3 meca-LC wafer using Array2D + unwanted indices.
% Default is GDS-only because full-wafer COMSOL build is heavy.
use_comsol = false;
use_gds = true;
comsol_api = "mph";   % "mph" or "livelink"
preview_klayout = false;

ctx = GeometryPipeline.with_shared_comsol(enable_comsol=use_comsol, enable_gds=use_gds, ...
    comsol_api=comsol_api, ...
    preview_klayout=preview_klayout, ...
    snap_on_grid=false, gds_resolution_nm=1, warn_on_snap=true, ...
    reset_model=true, clean_on_reset=false);

ctx.add_layer("wafer", gds_layer=90, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="wafer_outline", comsol_selection_state="all");
ctx.add_layer("chip_box", gds_layer=34, gds_datatype=0);
ctx.add_layer("metal1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="metal1", comsol_selection_state="all");
ctx.add_layer("gap", gds_layer=2, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="gap", comsol_selection_state="all");
ctx.add_layer("backside", gds_layer=10, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="backside_opening", comsol_selection_state="all");
ctx.add_layer("membrane", gds_layer=11, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="membrane", comsol_selection_state="all");
ctx.add_layer("front_sin", gds_layer=13, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="front_sin", comsol_selection_state="all");
ctx.add_layer("front_al", gds_layer=33, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="front_al", comsol_selection_state="all");

p_um = Parameter(1, "ex9_u", unit="um");

% Wafer params.
p_wafer_diam = Parameter(50800, "ex9_wafer_diam", unit="um");
p_wafer_flat = Parameter(15500, "ex9_wafer_flat", unit="um");

% Meca-LC chip params.
p_chip_w = Parameter(10740, "ex9_chip_w", unit="um");
p_chip_h = Parameter(9740, "ex9_chip_h", unit="um");
p_mem_off_x = Parameter(0, "ex9_mem_off_x", unit="um");
p_mem_off_y = Parameter(0, "ex9_mem_off_y", unit="um");

p_mem_w = Parameter(140, "ex9_mem_w", unit="um");
p_mem_h = Parameter(110, "ex9_mem_h", unit="um");
p_wafer_thk = Parameter(280, "ex9_wafer_thk", unit="um");
p_tan_etch = Parameter(1.412, "ex9_tan_etch", unit="", auto_register=false);
p_overetch = Parameter(8, "ex9_overetch", unit="um");

p_al_margin = Parameter(10, "ex9_al_margin", unit="um");
p_bias_dist = Parameter(90, "ex9_bias_dist", unit="um");
p_bias_w = Parameter(100, "ex9_bias_w", unit="um");
p_bias_h = Parameter(100, "ex9_bias_h", unit="um");
p_bias_conn_w = Parameter(20, "ex9_bias_conn_w", unit="um");

p_koh_margin = Parameter(40, "ex9_koh_margin", unit="um");
p_koh_corner = Parameter(40, "ex9_koh_corner", unit="um");
p_pillar_size = Parameter(300, "ex9_pillar_size", unit="um");
p_pillar_loc_x = Parameter(700, "ex9_pillar_loc_x", unit="um");
p_pillar_loc_y = Parameter(700, "ex9_pillar_loc_y", unit="um");

p_ind_a = Parameter(1300, "ex9_ind_a", unit="um");
p_ind_b = Parameter(1500, "ex9_ind_b", unit="um");
p_ind_track = Parameter(8, "ex9_ind_track", unit="um");
p_ind_gap = Parameter(12, "ex9_ind_gap", unit="um");
p_mode_center_y = Parameter(30, "ex9_mode_center_y", unit="um");
p_capa_sep = Parameter(30, "ex9_capa_sep", unit="um");
p_capa_pad_w = Parameter(30, "ex9_capa_pad_w", unit="um");
p_capa_pad_h = Parameter(60, "ex9_capa_pad_h", unit="um");
p_ind_coupling_dist = Parameter(1000, "ex9_ind_coupling_dist", unit="um");

p_readout_track = Parameter(20, "ex9_readout_track", unit="um");
p_readout_gap = Parameter(5.33, "ex9_readout_gap", unit="um");
p_dc_track = Parameter(40, "ex9_dc_track", unit="um");
p_dc_gap = Parameter(23, "ex9_dc_gap", unit="um");

p_dicer_alignment_sq = Parameter(600, "ex9_dicer_alignment_sq", unit="um");
p_dicer_alignment_width = Parameter(50, "ex9_dicer_alignment_width", unit="um");
p_dicer_track_width = Parameter(20, "ex9_dicer_track_width", unit="um"); %#ok<NASGU>

p_dc_split_idx = Parameter(13, "ex9_dc_split_idx", unit="", auto_register=false);
p_rd_left_margin = Parameter(300, "ex9_rd_left_margin", unit="um");
p_dc_edge_inset = Parameter(260, "ex9_dc_edge_inset", unit="um");
p_min_span = Parameter(100, "ex9_min_span", unit="um");
p_min_axis = Parameter(1, "ex9_min_axis", unit="um");

p_back_extra = 2 * p_wafer_thk / p_tan_etch - 2 * p_overetch;
p_back_w = p_mem_w + p_back_extra;
p_back_h = p_mem_h + p_back_extra;
p_al_w = p_mem_w - 2 * p_al_margin;
p_al_h = p_mem_h - 2 * p_al_margin;
p_bias_pad_loc_x = p_al_w / 2 + p_bias_dist + p_bias_w / 2;
p_koh_center_dx = 0.5 * (p_bias_dist - p_al_margin + p_bias_w);
p_koh_w = p_mem_w - p_al_margin + p_bias_dist + p_bias_w + 2 * p_koh_margin;
p_koh_h = p_mem_h + 2 * p_koh_margin;
p_pad_dx = 0.5 * (p_capa_sep + p_capa_pad_w);
p_readout_total_w = p_readout_track + 2 * p_readout_gap;
p_dc_total_w = p_dc_track + 2 * p_dc_gap;
p_mark_dx = p_chip_w / 2 - p_dicer_alignment_sq;
p_mark_dy = p_chip_h / 2 - p_dicer_alignment_sq;

p_ind_inner_a = Parameter(@(a, t, m) max(a - 0.5 * t, m), ...
    {p_ind_a, p_ind_track, p_min_axis}, "ex9_ind_inner_a", unit="um");
p_ind_inner_b = Parameter(@(b, t, m) max(b - 0.5 * t, m), ...
    {p_ind_b, p_ind_track, p_min_axis}, "ex9_ind_inner_b", unit="um");

mem_offset_um = [p_mem_off_x.value, p_mem_off_y.value];

% Wafer outline with flat.
wafer_flat_h_um = sqrt((p_wafer_diam.value / 2)^2 - (p_wafer_flat.value^2) / 4);
wafer_disk = Circle(ctx, center=Vertices([0, 0], p_um), radius=p_wafer_diam / 2, layer="wafer");
wafer_flat_cut = Rectangle(ctx, base="corner", ...
    corner=Vertices([-0.5 * p_wafer_diam.value, wafer_flat_h_um], p_um), ...
    width=p_wafer_diam, height=p_wafer_diam, layer="wafer");
wafer_outline = Difference(ctx, wafer_disk, {wafer_flat_cut}, layer="wafer"); %#ok<NASGU>

% Rectangular grid and removal masks.
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
grid_idx = (ix_grid - 1) * ny + iy_grid;
with_dc_mask = grid_idx > p_dc_split_idx.value;

keep_without_dc = inside_mask & ~with_dc_mask;
keep_with_dc = inside_mask & with_dc_mask;

unwanted_common = [ix_grid(~inside_mask), iy_grid(~inside_mask)];
unwanted_with_dc = [ix_grid(~keep_with_dc), iy_grid(~keep_with_dc)];
unwanted_without_dc = [ix_grid(~keep_without_dc), iy_grid(~keep_without_dc)]; %#ok<NASGU>

placed = nnz(inside_mask);
placed_with_dc = nnz(keep_with_dc);
placed_without_dc = nnz(keep_without_dc);

chip_seed_center_um = [x_centers_um(1), y_centers_um(1)];
mem_seed_center_um = chip_seed_center_um + mem_offset_um;
grid_dx = Vertices([p_chip_w.value, 0], p_um);
grid_dy = Vertices([0, p_chip_h.value], p_um);

% Common chip-level arrays.
chip_box_seed = Rectangle(ctx, center=Vertices(chip_seed_center_um, p_um), ...
    width=p_chip_w, height=p_chip_h, layer="chip_box");
chip_box = Array2D(ctx, chip_box_seed, ncopies_x=nx, ncopies_y=ny, ...
    delta_x=grid_dx, delta_y=grid_dy, ...
    unwanted_array_elements=unwanted_common, layer="chip_box"); %#ok<NASGU>

membrane_seed = Rectangle(ctx, center=Vertices(mem_seed_center_um, p_um), ...
    width=p_mem_w, height=p_mem_h, layer="membrane");
membrane = Array2D(ctx, membrane_seed, ncopies_x=nx, ncopies_y=ny, ...
    delta_x=grid_dx, delta_y=grid_dy, ...
    unwanted_array_elements=unwanted_common, layer="membrane"); %#ok<NASGU>

backside_seed = Rectangle(ctx, center=Vertices(mem_seed_center_um, p_um), ...
    width=p_back_w, height=p_back_h, layer="backside");
backside = Array2D(ctx, backside_seed, ncopies_x=nx, ncopies_y=ny, ...
    delta_x=grid_dx, delta_y=grid_dy, ...
    unwanted_array_elements=unwanted_common, layer="backside"); %#ok<NASGU>

al_inside_seed = Rectangle(ctx, center=Vertices(mem_seed_center_um, p_um), ...
    width=p_al_w, height=p_al_h, layer="front_al");
bias_pad_seed = Rectangle(ctx, center=Vertices(mem_seed_center_um + [p_bias_pad_loc_x.value, 0], p_um), ...
    width=p_bias_w, height=p_bias_h, layer="front_al");
al_connector_seed = Rectangle(ctx, ...
    center=Vertices(mem_seed_center_um + [0.5 * p_bias_pad_loc_x.value, 0], p_um), ...
    width=p_bias_pad_loc_x, height=p_bias_conn_w, layer="front_al");
al_layer_seed = Union(ctx, {al_inside_seed, bias_pad_seed, al_connector_seed}, layer="front_al");
al_layer = Array2D(ctx, al_layer_seed, ncopies_x=nx, ncopies_y=ny, ...
    delta_x=grid_dx, delta_y=grid_dy, ...
    unwanted_array_elements=unwanted_common, layer="front_al"); %#ok<NASGU>

% SiN common seed: negative mask and dicer marks.
koh_center_seed_um = mem_seed_center_um + [p_koh_center_dx.value, 0];
koh_main_seed = Rectangle(ctx, center=Vertices(koh_center_seed_um, p_um), ...
    width=p_koh_w, height=p_koh_h, layer="front_sin");
koh_corner_seed = Rectangle(ctx, ...
    center=Vertices(koh_center_seed_um + [-0.5 * p_koh_w.value, -0.5 * p_koh_h.value], p_um), ...
    width=p_koh_corner, height=p_koh_corner, layer="front_sin");
koh_corners_seed = Array2D(ctx, koh_corner_seed, ncopies_x=2, ncopies_y=2, ...
    delta_x=Vertices([1, 0], p_koh_w), delta_y=Vertices([0, 1], p_koh_h), ...
    layer="front_sin");
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
chip_sin_seed = Rectangle(ctx, center=Vertices(chip_seed_center_um, p_um), ...
    width=p_chip_w, height=p_chip_h, layer="front_sin");
sin_negative_seed = Difference(ctx, chip_sin_seed, {sin_positive_seed}, layer="front_sin");

mark_dx_um = p_mark_dx.value;
mark_dy_um = p_mark_dy.value;
mark_seed_um = chip_seed_center_um + [-mark_dx_um, -mark_dy_um];
mark_outer_seed = Square(ctx, center=Vertices(mark_seed_um, p_um), ...
    side=p_dicer_alignment_sq, layer="front_sin");
mark_inner_seed = Square(ctx, center=Vertices(mark_seed_um, p_um), ...
    side=p_dicer_alignment_sq - p_dicer_alignment_width, layer="front_sin");
mark_ring_seed = Difference(ctx, mark_outer_seed, {mark_inner_seed}, layer="front_sin");
dicer_marks_seed = Array2D(ctx, mark_ring_seed, ncopies_x=2, ncopies_y=2, ...
    delta_x=Vertices([2 * mark_dx_um, 0], p_um), ...
    delta_y=Vertices([0, 2 * mark_dy_um], p_um), layer="front_sin");

front_sin_seed = Union(ctx, {sin_negative_seed, dicer_marks_seed}, layer="front_sin");
front_sin = Array2D(ctx, front_sin_seed, ncopies_x=nx, ncopies_y=ny, ...
    delta_x=grid_dx, delta_y=grid_dy, ...
    unwanted_array_elements=unwanted_common, layer="front_sin"); %#ok<NASGU>

% Resonator common metal/gap seed.
res_center_seed_um = mem_seed_center_um + [0, p_mode_center_y.value + p_ind_b.value];
res_outer_seed = Ellipse(ctx, center=Vertices(res_center_seed_um, p_um), ...
    a=p_ind_a + 0.5 * p_ind_track, b=p_ind_b + 0.5 * p_ind_track, layer="metal1");
res_inner_seed = Ellipse(ctx, center=Vertices(res_center_seed_um, p_um), ...
    a=p_ind_inner_a, b=p_ind_inner_b, layer="metal1");
res_ring_seed = Difference(ctx, res_outer_seed, {res_inner_seed}, layer="metal1");
cap_l_seed = Rectangle(ctx, ...
    center=Vertices(mem_seed_center_um + [-p_pad_dx.value, p_mode_center_y.value], p_um), ...
    width=p_capa_pad_w, height=p_capa_pad_h, layer="metal1");
cap_r_seed = Rectangle(ctx, ...
    center=Vertices(mem_seed_center_um + [+p_pad_dx.value, p_mode_center_y.value], p_um), ...
    width=p_capa_pad_w, height=p_capa_pad_h, layer="metal1");
lc_island_seed = Union(ctx, {res_ring_seed, cap_l_seed, cap_r_seed}, layer="metal1");
lc_island = Array2D(ctx, lc_island_seed, ncopies_x=nx, ncopies_y=ny, ...
    delta_x=grid_dx, delta_y=grid_dy, ...
    unwanted_array_elements=unwanted_common, layer="metal1"); %#ok<NASGU>

gap_outer_seed = Ellipse(ctx, center=Vertices(res_center_seed_um, p_um), ...
    a=p_ind_a + 0.5 * p_ind_track + p_ind_gap, ...
    b=p_ind_b + 0.5 * p_ind_track + p_ind_gap, layer="gap");
gap_inner_seed = Ellipse(ctx, center=Vertices(res_center_seed_um, p_um), ...
    a=p_ind_a + 0.5 * p_ind_track, b=p_ind_b + 0.5 * p_ind_track, layer="gap");
gap_ring_seed = Difference(ctx, gap_outer_seed, {gap_inner_seed}, layer="gap");
gap_ring = Array2D(ctx, gap_ring_seed, ncopies_x=nx, ncopies_y=ny, ...
    delta_x=grid_dx, delta_y=grid_dy, ...
    unwanted_array_elements=unwanted_common, layer="gap"); %#ok<NASGU>

% Readout CPW (common).
readout_y_um = res_center_seed_um(2) + p_ind_b.value + p_ind_coupling_dist.value;
rd_x0_um = chip_seed_center_um(1) - p_chip_w.value / 2 + p_rd_left_margin.value;
rd_x1_um = res_center_seed_um(1);
rd_w_um = max(rd_x1_um - rd_x0_um, p_min_span.value);
rd_track_seed = Rectangle(ctx, base="corner", ...
    corner=Vertices([rd_x0_um, readout_y_um - 0.5 * p_readout_track.value], p_um), ...
    width=rd_w_um, height=p_readout_track, layer="metal1");
rd_gap_seed = Rectangle(ctx, base="corner", ...
    corner=Vertices([rd_x0_um, readout_y_um - 0.5 * p_readout_total_w.value], p_um), ...
    width=rd_w_um, height=p_readout_total_w, layer="gap");
rd_track = Array2D(ctx, rd_track_seed, ncopies_x=nx, ncopies_y=ny, ...
    delta_x=grid_dx, delta_y=grid_dy, ...
    unwanted_array_elements=unwanted_common, layer="metal1"); %#ok<NASGU>
rd_gap = Array2D(ctx, rd_gap_seed, ncopies_x=nx, ncopies_y=ny, ...
    delta_x=grid_dx, delta_y=grid_dy, ...
    unwanted_array_elements=unwanted_common, layer="gap"); %#ok<NASGU>

% Optional DC bias line: only keep split chips requiring DC.
bias_center_seed_um = mem_seed_center_um + [p_bias_pad_loc_x.value, 0];
dc_y0_um = chip_seed_center_um(2) - p_chip_h.value / 2 + p_dc_edge_inset.value;
dc_y1_um = bias_center_seed_um(2) - 0.5 * p_bias_h.value;
dc_h_um = max(dc_y1_um - dc_y0_um, p_min_span.value);
dc_track_seed = Rectangle(ctx, base="corner", ...
    corner=Vertices([bias_center_seed_um(1) - 0.5 * p_dc_track.value, dc_y0_um], p_um), ...
    width=p_dc_track, height=dc_h_um, layer="metal1");
dc_gap_seed = Rectangle(ctx, base="corner", ...
    corner=Vertices([bias_center_seed_um(1) - 0.5 * p_dc_total_w.value, dc_y0_um], p_um), ...
    width=p_dc_total_w, height=dc_h_um, layer="gap");
dc_track = Array2D(ctx, dc_track_seed, ncopies_x=nx, ncopies_y=ny, ...
    delta_x=grid_dx, delta_y=grid_dy, ...
    unwanted_array_elements=unwanted_with_dc, layer="metal1"); %#ok<NASGU>
dc_gap = Array2D(ctx, dc_gap_seed, ncopies_x=nx, ncopies_y=ny, ...
    delta_x=grid_dx, delta_y=grid_dy, ...
    unwanted_array_elements=unwanted_with_dc, layer="gap"); %#ok<NASGU>

fprintf("Example 9 wafer diameter: %.3f um, flat: %.3f um\n", p_wafer_diam.value, p_wafer_flat.value);
fprintf("Example 9 chip grid: nx=%d ny=%d\n", nx, ny);
fprintf("Example 9 placed chips: %d (with_dc_bias=%d, without_dc_bias=%d)\n", ...
    placed, placed_with_dc, placed_without_dc);

ctx.build();
