import core.*
import types.*
import primitives.*
import ops.*

% Example 4: Chamfer, Offset, Tangent and dependent parameter usage.
% COMSOL backend: "livelink" (default) or "mph".
cfg = ProjectConfig.load();
comsol_api = "livelink";
preview_klayout = false;
ctx = GeometrySession.with_shared_comsol(use_comsol=true, use_gds=true, ...
    comsol_api=comsol_api, comsol_host=cfg.comsol.host, comsol_port=cfg.comsol.port, ...
    comsol_root=cfg.comsol.root, ...
    preview_klayout=preview_klayout, preview_scope="all", preview_step_delay_s=0.08, ...
    snap_mode='off', gds_resolution_nm=1, warn_on_snap=true, reset_model=true);

ctx.add_layer("metal1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="metal1", comsol_selection_state="all", emit_to_comsol=true);

% Base unit helper (all geometry lengths in um).
p_um = Parameter(1, "u_ex4", unit="um");

p_off_seed = Parameter(0.35, "off_seed", unit="um");
p_offset_dist = Parameter(@(x) x + 0.15, p_off_seed, "off_dist");
p_line_thk_seed = Parameter(0.25, "line_thk_seed", unit="um");
p_line_thk = Parameter(@(x) x + 0.1, p_line_thk_seed, "line_thk");
Parameter(p_line_thk / p_offset_dist, name="dummy", unit="");

p_chamfer_w = Parameter(90, "chamfer_w", unit="um");
p_chamfer_h = Parameter(60, "chamfer_h", unit="um");
p_chamfer_d = Parameter(0.2, "chamfer_d", unit="um");
chamfer_base = Rectangle(center=Vertices([-250, 220], p_um), ...
    width=p_chamfer_w, height=p_chamfer_h, layer="metal1");
Chamfer(chamfer_base, dist=p_chamfer_d, points=[1 2 3 4], layer="metal1");

% keep_input_objects demo: both seed and moved copy are kept.
keep_seed = Rectangle(center=Vertices([-300, 120], p_um), ...
    width=Parameter(18, "keep_seed_w", unit="um"), ...
    height=Parameter(12, "keep_seed_h", unit="um"), layer="metal1");
Move(keep_seed, delta=Vertices([1, 0], Parameter(26, "keep_seed_dx", unit="um")), ...
    keep_input_objects=true, layer="metal1");

p_offset_w = Parameter(100, "offset_w", unit="um");
p_offset_h = Parameter(45, "offset_h", unit="um");
offset_base = Rectangle(center=Vertices([-120, 220], p_um), ...
    width=p_offset_w, height=p_offset_h, layer="metal1");
Offset(offset_base, distance=p_offset_dist, reverse=false, ...
    convexcorner="fillet", trim=true, keep_input_objects=false, layer="metal1");

p_tangent_r = Parameter(28, "tan_r", unit="um");
p_tangent_w = Parameter(1, "tan_w", unit="um");
tangent_circle = Circle(center=Vertices([30, 220], p_um), ...
    radius=p_tangent_r, npoints=96, layer="metal1");
Tangent(tangent_circle, type="coord", coord=Vertices([95, 250], p_um), ...
    start=0.7, edge_index=1, width=p_tangent_w, layer="metal1");

ctx.export_gds("example_4.gds");
ctx.build_comsol();
ctx.build_report();
