import core.*
import types.*
import primitives.*
import ops.*

% Example 3: curve primitives and Thicken operation.
% COMSOL backend: "livelink" or "mph" (default).
comsol_api = "livelink";
preview_klayout = false;
ctx = GeometrySession.with_shared_comsol(enable_comsol=true, enable_gds=true, ...
    comsol_api=comsol_api, ...
    preview_klayout=preview_klayout, ...
    snap_on_grid=false, gds_resolution_nm=1, warn_on_snap=true, reset_model=true);

ctx.add_layer("metal1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="metal1", comsol_selection_state="all");

% Base unit helper (all geometry lengths in um).
p_um = Parameter(1, "u_ex3", unit="um");
p_curve_w = Parameter(0.2, "curve_w", unit="um");
p_marker_size = Parameter(0.2, "pt_marker", unit="um");

p_line_thk_seed = Parameter(0.25, "line_thk_seed", unit="um");
p_line_thk = Parameter(@(x) x + 0.15, p_line_thk_seed, "line_thk");
p_interp_up = Parameter(0.4, "interp_up", unit="um");
p_interp_down = Parameter(0.25, "interp_down", unit="um");
p_quad_thk = Parameter(0.45, "quad_thk", unit="um");
p_cubic_thk = Parameter(0.35, "cubic_thk", unit="um");
p_arc_thk = Parameter(0.5, "arc_thk", unit="um");
p_param_up = Parameter(0.42, "param_up", unit="um");
p_param_down = Parameter(0.22, "param_down", unit="um");

Point(p=Vertices([-330, -240; -320, -230], p_um), marker_size=p_marker_size, layer="metal1");

line_raw = LineSegment(p1=Vertices([-300, -210], p_um), p2=Vertices([-160, -180], p_um), ...
    width=p_curve_w, layer="metal1");
Thicken(line_raw, offset="symmetric", totalthick=p_line_thk, ...
    ends="circular", convexcorner="fillet", layer="metal1");

interp_raw = InterpolationCurve(points=Vertices([-300 -155; -255 -125; -205 -165; -145 -130], p_um), ...
    type="open", width=p_curve_w, layer="metal1");
Thicken(interp_raw, offset="asymmetric", upthick=p_interp_up, downthick=p_interp_down, ...
    ends="straight", convexcorner="extend", layer="metal1");

quad_raw = QuadraticBezier(p0=Vertices([-80 -210], p_um), p1=Vertices([-20 -120], p_um), ...
    p2=Vertices([40 -190], p_um), type="open", npoints=96, width=p_curve_w, layer="metal1");
Thicken(quad_raw, offset="symmetric", totalthick=p_quad_thk, ...
    ends="straight", convexcorner="fillet", layer="metal1");

cubic_raw = CubicBezier(p0=Vertices([60 -210], p_um), p1=Vertices([110 -110], p_um), ...
    p2=Vertices([180 -250], p_um), p3=Vertices([240 -170], p_um), ...
    type="open", npoints=128, width=p_curve_w, layer="metal1");
Thicken(cubic_raw, offset="symmetric", totalthick=p_cubic_thk, ...
    ends="straight", convexcorner="noconnection", layer="metal1");

p_arc_r = Parameter(55, "arc_r", unit="um");
p_arc_a0 = Parameter(20, "arc_a0", unit="deg");
p_arc_a1 = Parameter(290, "arc_a1", unit="deg");
arc_raw = CircularArc(center=Vertices([320, -180], p_um), radius=p_arc_r, ...
    start_angle=p_arc_a0, end_angle=p_arc_a1, ...
    type="open", npoints=160, width=p_curve_w, layer="metal1");
Thicken(arc_raw, offset="symmetric", totalthick=p_arc_thk, ...
    ends="circular", convexcorner="fillet", layer="metal1");

p_pc_rx = Parameter(42, "pc_rx", unit="um");
p_pc_ry2 = Parameter(20, "pc_ry2", unit="um");
p_smin = Parameter(0, "pc_smin", unit="");
p_smax = Parameter(pi, "pc_smax", unit="");
param_raw = ParametricCurve(coord={"pc_rx*cos(s)", "pc_ry2*sin(2*s)"}, parname="s", ...
    parmin=p_smin, parmax=p_smax, type="open", npoints=180, width=p_curve_w, layer="metal1");
Thicken(param_raw, offset="asymmetric", upthick=p_param_up, downthick=p_param_down, ...
    ends="straight", convexcorner="tangent", layer="metal1");

p_pc2_r = Parameter(20, "pc2_r", unit="um");
p_s2min = Parameter(0, "pc2_smin", unit="");
p_s2max = Parameter(2*pi, "pc2_smax", unit="");
ParametricCurve(coord={"pc2_r*cos(s)", "pc2_r*sin(s)"}, parname="s", ...
    parmin=p_s2min, parmax=p_s2max, type="closed", npoints=128, width=p_curve_w, layer="metal1");

ctx.build();
