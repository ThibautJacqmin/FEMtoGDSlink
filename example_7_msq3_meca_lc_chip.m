import core.*
import types.*
import primitives.*
import ops.*

% Example 7: MSQ3 meca-LC chip (inline, no external YAML/helpers).
% Includes membrane stack + LC resonator + readout/DC routing.

ctx = GeometryPipeline.with_shared_comsol(enable_comsol=false, ...
                                         enable_gds=true, ...
                                         comsol_api="mph", ...
                                         preview_klayout=true, ...
                                         snap_on_grid=false,...
                                         gds_resolution_nm=1,...
                                         warn_on_snap=true);

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
ctx.add_layer("portmark", gds_layer=50, gds_datatype=0);

% Base unit helper for vertex coordinates expressed in um.
p_um = Parameter(1, "ex7_u", unit="um");
p_nm_per_um = Parameter(1e3, "ex7_nm_per_um", unit="", auto_register=false);

% Chip and membrane parameters (from meca_lc + MSQ3 params).
p_chip_w = Parameter(10740, "ex7_chip_w", unit="um");
p_chip_h = Parameter(9740, "ex7_chip_h", unit="um");
p_mem_cx = Parameter(0, "ex7_mem_cx", unit="um");
p_mem_cy = Parameter(0, "ex7_mem_cy", unit="um");
p_mem_w = Parameter(140, "ex7_mem_w", unit="um");
p_mem_h = Parameter(110, "ex7_mem_h", unit="um");
p_wafer_thk = Parameter(280, "ex7_wafer_thk", unit="um");
p_tan_etch = Parameter(1.412, "ex7_tan_etch", unit="", auto_register=false);
p_overetch = Parameter(8, "ex7_overetch", unit="um");

p_al_margin = Parameter(10, "ex7_al_margin", unit="um");
p_bias_dist = Parameter(90, "ex7_bias_dist", unit="um");
p_bias_w = Parameter(100, "ex7_bias_w", unit="um");
p_bias_h = Parameter(100, "ex7_bias_h", unit="um");
p_bias_conn_w = Parameter(20, "ex7_bias_conn_w", unit="um");

p_koh_margin = Parameter(40, "ex7_koh_margin", unit="um");
p_koh_corner = Parameter(40, "ex7_koh_corner", unit="um");
p_pillar_size = Parameter(300, "ex7_pillar_size", unit="um");
p_pillar_loc_x = Parameter(700, "ex7_pillar_loc_x", unit="um");
p_pillar_loc_y = Parameter(700, "ex7_pillar_loc_y", unit="um");

% Meca-LC resonator / routing parameters.
p_ind_a = Parameter(1300, "ex7_ind_a", unit="um");
p_ind_b = Parameter(1500, "ex7_ind_b", unit="um");
p_ind_track = Parameter(8, "ex7_ind_track", unit="um");
p_ind_gap = Parameter(12, "ex7_ind_gap", unit="um");
p_mode_center_y = Parameter(30, "ex7_mode_center_y", unit="um");
p_capa_sep = Parameter(30, "ex7_capa_sep", unit="um");
p_capa_pad_w = Parameter(30, "ex7_capa_pad_w", unit="um");
p_capa_pad_h = Parameter(60, "ex7_capa_pad_h", unit="um");
p_ind_coupling_dist = Parameter(1000, "ex7_ind_coupling_dist", unit="um");

p_readout_track = Parameter(20, "ex7_readout_track", unit="um");
p_readout_gap = Parameter(5.33, "ex7_readout_gap", unit="um");
p_dc_track = Parameter(40, "ex7_dc_track", unit="um");
p_dc_gap = Parameter(23, "ex7_dc_gap", unit="um");

p_rd_edge_inset = Parameter(250, "ex7_rd_edge_inset", unit="um");
p_rd_edge_extra = Parameter(300, "ex7_rd_edge_extra", unit="um");
p_rd_cpl_extra = Parameter(120, "ex7_rd_cpl_extra", unit="um");
p_rd_fillet = Parameter(70, "ex7_rd_fillet", unit="um");
p_rd_start_straight = Parameter(260, "ex7_rd_start_straight", unit="um");
p_rd_end_straight = Parameter(120, "ex7_rd_end_straight", unit="um");
p_launch_length = Parameter(250, "ex7_launch_length", unit="um");
p_launch_sig_wide = Parameter(90, "ex7_launch_sig_wide", unit="um");
p_launch_gap_wide = Parameter(160, "ex7_launch_gap_wide", unit="um");
p_dc_edge_inset = Parameter(260, "ex7_dc_edge_inset", unit="um");
p_dc_fillet = Parameter(60, "ex7_dc_fillet", unit="um");
p_min_axis = Parameter(1, "ex7_min_axis", unit="um");

p_back_extra = 2 * p_wafer_thk / p_tan_etch - 2 * p_overetch;
p_back_w = p_mem_w + p_back_extra;
p_back_h = p_mem_h + p_back_extra;

p_al_w = p_mem_w - 2 * p_al_margin;
p_al_h = p_mem_h - 2 * p_al_margin;
p_bias_pad_loc_x = p_al_w / 2 + p_bias_dist + p_bias_w / 2;

p_koh_center_x = p_mem_cx + 0.5 * (p_bias_dist - p_al_margin + p_bias_w);
p_koh_w = p_mem_w - p_al_margin + p_bias_dist + p_bias_w + 2 * p_koh_margin;
p_koh_h = p_mem_h + 2 * p_koh_margin;
p_res_center_y = p_mem_cy + p_mode_center_y + p_ind_b;

p_ind_inner_a = Parameter(@(a, t, m) max(a - 0.5 * t, m), ...
    {p_ind_a, p_ind_track, p_min_axis}, "ex7_ind_inner_a", unit="um");
p_ind_inner_b = Parameter(@(b, t, m) max(b - 0.5 * t, m), ...
    {p_ind_b, p_ind_track, p_min_axis}, "ex7_ind_inner_b", unit="um");

p_rd_edge_x = -0.5 * p_chip_w + p_rd_edge_inset;
p_rd_edge_y = p_res_center_y + p_ind_b + p_rd_edge_extra;
p_rd_cpl_x = p_mem_cx;
p_rd_cpl_y = p_res_center_y + p_ind_b + p_rd_cpl_extra;
p_dc_x = p_mem_cx + p_bias_pad_loc_x;
p_dc_edge_y = -0.5 * p_chip_h + p_dc_edge_inset;
p_dc_target_y = p_mem_cy - 0.5 * p_bias_h;
p_launch_length_nm = p_launch_length * p_nm_per_um;
p_launch_sig_wide_nm = p_launch_sig_wide * p_nm_per_um;
p_launch_gap_wide_nm = p_launch_gap_wide * p_nm_per_um;

v_mem_center = Vertices([p_mem_cx.value, p_mem_cy.value], p_um);
v_bias_pad_center = Vertices([p_dc_x.value, p_mem_cy.value], p_um);
v_koh_center = Vertices([p_koh_center_x.value, p_mem_cy.value], p_um);
mem_center_um = v_mem_center.value;

% Membrane and backside opening.
membrane = Rectangle(ctx, center=v_mem_center, ...
    width=p_mem_w, height=p_mem_h, layer="membrane"); %#ok<NASGU>
backside = Rectangle(ctx, center=v_mem_center, ...
    width=p_back_w, height=p_back_h, layer="backside"); %#ok<NASGU>

% Aluminium membrane pattern (inside + bias pad + connector).
al_inside = Rectangle(ctx, center=v_mem_center, ...
    width=p_al_w, height=p_al_h, layer="front_al");
bias_pad = Rectangle(ctx, center=v_bias_pad_center, ...
    width=p_bias_w, height=p_bias_h, layer="front_al");
al_connector = Rectangle(ctx, ...
    center=Vertices([p_mem_cx.value + 0.5 * p_bias_pad_loc_x.value, p_mem_cy.value], p_um), ...
    width=p_bias_pad_loc_x, height=p_bias_conn_w, layer="front_al");
al_layer = Union(ctx, {al_inside, bias_pad, al_connector}, layer="front_al"); %#ok<NASGU>

% Frontside SiN protection + pillars.
koh_main = Rectangle(ctx, center=v_koh_center, ...
    width=p_koh_w, height=p_koh_h, layer="front_sin");
p_koh_corner_seed_x = p_koh_center_x - 0.5 * p_koh_w;
p_koh_corner_seed_y = p_mem_cy - 0.5 * p_koh_h;
koh_corner_seed = Rectangle(ctx, ...
    center=Vertices([p_koh_corner_seed_x.value, p_koh_corner_seed_y.value], p_um), ...
    width=p_koh_corner, height=p_koh_corner, layer="front_sin");
koh_corners = Array2D(ctx, koh_corner_seed, ncopies_x=2, ncopies_y=2, ...
    delta_x=Vertices([1, 0], p_koh_w), delta_y=Vertices([0, 1], p_koh_h), ...
    unwanted_array_elements=zeros(0, 2), ...
    layer="front_sin");
koh_layer = Union(ctx, {koh_main, koh_corners}, layer="front_sin");

p_pillar_seed_x = p_mem_cx - p_pillar_loc_x;
p_pillar_seed_y = p_mem_cy - p_pillar_loc_y;
pillar_seed = Rectangle(ctx, ...
    center=Vertices([p_pillar_seed_x.value, p_pillar_seed_y.value], p_um), ...
    width=p_pillar_size, height=p_pillar_size, layer="front_sin");
pillar_corner_seed = Rectangle(ctx, ...
    center=Vertices([p_pillar_seed_x.value - 0.5 * p_pillar_size.value, ...
    p_pillar_seed_y.value - 0.5 * p_pillar_size.value], p_um), ...
    width=p_koh_corner, height=p_koh_corner, layer="front_sin");
pillar_corners = Array2D(ctx, pillar_corner_seed, ncopies_x=2, ncopies_y=2, ...
    delta_x=Vertices([1, 0], p_pillar_size), delta_y=Vertices([0, 1], p_pillar_size), ...
    layer="front_sin");
pillar_template = Union(ctx, {pillar_seed, pillar_corners}, layer="front_sin");
pillars_layer = Array2D(ctx, pillar_template, ncopies_x=2, ncopies_y=2, ...
    delta_x=Vertices([1, 0], 2 * p_pillar_loc_x), ...
    delta_y=Vertices([0, 1], 2 * p_pillar_loc_y), ...
    layer="front_sin");
sin_positive = Union(ctx, {koh_layer, pillars_layer}, layer="front_sin");
chip_sin_rect = Rectangle(ctx, center=Vertices([0, 0], p_um), ...
    width=p_chip_w, height=p_chip_h, layer="front_sin");
sin_negative = Difference(ctx, chip_sin_rect, {sin_positive}, layer="front_sin"); %#ok<NASGU>

% LC resonator island (elliptic inductor ring + capacitor pads).
v_res_center = Vertices([p_mem_cx.value, p_res_center_y.value], p_um);
res_center_um = v_res_center.value;
res_outer = Ellipse(ctx, center=v_res_center, ...
    a=p_ind_a + 0.5 * p_ind_track, ...
    b=p_ind_b + 0.5 * p_ind_track, ...
    layer="metal1");
res_inner = Ellipse(ctx, center=v_res_center, ...
    a=p_ind_inner_a, ...
    b=p_ind_inner_b, ...
    layer="metal1");
res_ring = Difference(ctx, res_outer, {res_inner}, layer="metal1");

p_pad_dx = 0.5 * (p_capa_sep + p_capa_pad_w);
pad_l = Rectangle(ctx, ...
    center=Vertices([p_mem_cx.value - p_pad_dx.value, p_mem_cy.value + p_mode_center_y.value], p_um), ...
    width=p_capa_pad_w, height=p_capa_pad_h, layer="metal1");
pad_r = Rectangle(ctx, ...
    center=Vertices([p_mem_cx.value + p_pad_dx.value, p_mem_cy.value + p_mode_center_y.value], p_um), ...
    width=p_capa_pad_w, height=p_capa_pad_h, layer="metal1");
lc_island = Union(ctx, {res_ring, pad_l, pad_r}, layer="metal1"); %#ok<NASGU>

% Keep-out ring around the resonator in CPW gap layer.
res_gap_outer = Ellipse(ctx, center=v_res_center, ...
    a=p_ind_a + 0.5 * p_ind_track + p_ind_gap, ...
    b=p_ind_b + 0.5 * p_ind_track + p_ind_gap, ...
    layer="gap");
res_gap_inner = Ellipse(ctx, center=v_res_center, ...
    a=p_ind_a + 0.5 * p_ind_track, ...
    b=p_ind_b + 0.5 * p_ind_track, ...
    layer="gap");
res_gap_ring = Difference(ctx, res_gap_outer, {res_gap_inner}, layer="gap"); %#ok<NASGU>

% Readout CPW routing to the resonator coupler.
cpw_readout = components.cpw.spec( ...
    p_readout_track * p_nm_per_um, ...
    (p_readout_track + 2 * p_readout_gap) * p_nm_per_um, ...
    layer_sig="metal1", layer_gap="gap");

p_rd_edge = components.cpw.port("ex7_rd_edge", ...
    Vertices([p_rd_edge_x.value, p_rd_edge_y.value], p_nm_per_um), [1, 0], cpw_readout);
p_rd_cpl = components.cpw.port("ex7_rd_cpl", ...
    Vertices([p_rd_cpl_x.value, p_rd_cpl_y.value], p_nm_per_um), [0, -1], cpw_readout);
rd_line = components.cpw.routed_line(ctx, p_rd_edge, p_rd_cpl, ...
    name="ex7_readout", fillet=p_rd_fillet * p_nm_per_um, ...
    start_straight=p_rd_start_straight * p_nm_per_um, ...
    end_straight=p_rd_end_straight * p_nm_per_um);
rd_launch = components.cpw.edge_launch(ctx, p_rd_edge, ...
    name="ex7_readout_launch", length_nm=p_launch_length_nm.value, ...
    sig_wide_nm=p_launch_sig_wide_nm.value, ...
    gap_wide_nm=p_launch_gap_wide_nm.value, ...
    direction="outward"); %#ok<NASGU>

% DC bias CPW routing to the membrane bias pad.
cpw_dc = components.cpw.spec( ...
    p_dc_track * p_nm_per_um, ...
    (p_dc_track + 2 * p_dc_gap) * p_nm_per_um, ...
    layer_sig="metal1", layer_gap="gap");
p_dc_edge = components.cpw.port("ex7_dc_edge", ...
    Vertices([p_dc_x.value, p_dc_edge_y.value], p_nm_per_um), [0, 1], cpw_dc);
p_dc_target = components.cpw.port("ex7_dc_target", ...
    Vertices([p_dc_x.value, p_dc_target_y.value], p_nm_per_um), [0, -1], cpw_dc);
dc_line = components.cpw.connector(ctx, p_dc_edge, p_dc_target, ...
    name="ex7_dc_bias", fillet=p_dc_fillet * p_nm_per_um);

% Triangular port markers.
rd_markers = p_rd_edge.draw_markers(ctx=ctx, layer="portmark", tip_scale=0.5); %#ok<NASGU>
dc_markers = p_dc_edge.draw_markers(ctx=ctx, layer="portmark", tip_scale=0.5); %#ok<NASGU>

fprintf("Example 7 membrane center: [%.3f, %.3f] um\n", ...
    mem_center_um(1), mem_center_um(2));
fprintf("Example 7 resonator center: [%.3f, %.3f] um\n", ...
    res_center_um(1), res_center_um(2));
fprintf("Example 7 readout length: %.3f um\n", rd_line.length_nm / 1e3);
fprintf("Example 7 dc-bias length: %.3f um\n", dc_line.length_nm / 1e3);

ctx.build();
