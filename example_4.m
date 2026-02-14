import core.*
import types.*
import primitives.*
import ops.*

% Example 4: Chamfer, Offset, Tangent and dependent parameter usage.
ctx = GeometrySession.with_shared_comsol(use_comsol=true, use_gds=true, ...
    snap_mode='off', snap_grid_nm=1, warn_on_snap=true, reset_model=true);

ctx.add_layer("metal1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="metal1", comsol_selection_state="all", emit_to_comsol=true);

p_off_seed = Parameter(7, "off_seed");
p_offset_dist = Parameter(@(x) x + 3, p_off_seed, "off_dist");
p_line_thk_seed = Parameter(6, "line_thk_seed");
p_line_thk = Parameter(@(x) x + 2, p_line_thk_seed, "line_thk");
Parameter(p_line_thk / p_offset_dist, name="dummy", unit="");

chamfer_base = Rectangle(center=[-250, 220], width=90, height=60, layer="metal1");
Chamfer(chamfer_base, dist=10, points=[1 2 3 4], layer="metal1");

offset_base = Rectangle(center=[-120, 220], width=100, height=45, layer="metal1");
Offset(offset_base, distance=p_offset_dist, reverse=false, ...
    convexcorner="fillet", trim=true, keep=false, layer="metal1");

tangent_circle = Circle(center=[30, 220], radius=28, npoints=96, layer="metal1");
Tangent(tangent_circle, type="coord", coord=[95, 250], ...
    start=0.7, edge_index=1, width=8, layer="metal1");

ctx.build_comsol();
ctx.export_gds("example_4.gds");
ctx.build_report();
