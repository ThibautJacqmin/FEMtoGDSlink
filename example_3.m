import core.*
import types.*
import primitives.*
import ops.*

% Example 3: curve primitives and Thicken operation.
ctx = GeometrySession.with_shared_comsol(use_comsol=true, use_gds=true, ...
    snap_mode='off', snap_grid_nm=1, warn_on_snap=true, reset_model=true);

ctx.add_layer("metal1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="metal1", comsol_selection_state="all", emit_to_comsol=true);

p_line_thk_seed = Parameter(6, "line_thk_seed");
p_line_thk = Parameter(@(x) x + 2, p_line_thk_seed, "line_thk");

Point(p=[-330, -240; -320, -230], marker_size=6, layer="metal1");

line_raw = LineSegment(p1=[-300, -210], p2=[-160, -180], layer="metal1");
Thicken(line_raw, offset="symmetric", totalthick=p_line_thk, ...
    ends="circular", convexcorner="fillet", layer="metal1");

interp_raw = InterpolationCurve(points=[-300 -155; -255 -125; -205 -165; -145 -130], ...
    type="open", layer="metal1");
Thicken(interp_raw, offset="asymmetric", upthick=10, downthick=6, ...
    ends="straight", convexcorner="extend", layer="metal1");

quad_raw = QuadraticBezier(p0=[-80 -210], p1=[-20 -120], p2=[40 -190], ...
    type="open", npoints=96, layer="metal1");
Thicken(quad_raw, offset="symmetric", totalthick=12, ...
    ends="straight", convexcorner="fillet", layer="metal1");

cubic_raw = CubicBezier(p0=[60 -210], p1=[110 -110], p2=[180 -250], p3=[240 -170], ...
    type="open", npoints=128, layer="metal1");
Thicken(cubic_raw, offset="symmetric", totalthick=10, ...
    ends="straight", convexcorner="noconnection", layer="metal1");

arc_raw = CircularArc(center=[320, -180], radius=55, start_angle=20, end_angle=290, ...
    type="open", npoints=160, layer="metal1");
Thicken(arc_raw, offset="symmetric", totalthick=16, ...
    ends="circular", convexcorner="fillet", layer="metal1");

param_raw = ParametricCurve(coord={"42*cos(s)", "20*sin(2*s)"}, parname="s", ...
    parmin=0, parmax=pi, type="open", npoints=180, layer="metal1");
Thicken(param_raw, offset="asymmetric", upthick=9, downthick=5, ...
    ends="straight", convexcorner="tangent", layer="metal1");

ParametricCurve(coord={"20*cos(s)", "20*sin(s)"}, parname="s", ...
    parmin=0, parmax=2*pi, type="closed", npoints=128, layer="metal1");

ctx.build_comsol();
ctx.export_gds("example_3.gds");
ctx.build_report();
