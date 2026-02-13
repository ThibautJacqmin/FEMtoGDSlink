import femtogds.core.*
import femtogds.types.*
import femtogds.primitives.*
import femtogds.ops.*

ctx = GeometrySession.with_shared_comsol(use_comsol=true, use_gds=true, ...
    snap_mode='off', snap_grid_nm=1, warn_on_snap=true, reset_model=true);

ctx.add_layer("metal1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="metal1", comsol_selection_state="all", emit_to_comsol=true);

% Global design parameters.
nlevels = 6;
p_pitch_y = Parameter(36, "pitch_y1");
p_base_width = Parameter(260, "tower_w0");
p_width_step = Parameter(32, "tower_dw");
p_level_height = Parameter(28, "tower_h");
p_tower_scale = Parameter(0.92, "tower_scale", unit="");
p_tower_angle = Parameter(8, "tower_rot_deg", unit="");
p_move_unit = Parameter(20, "tower_move_unit");

p_env_w = Parameter(380, "env_w");
p_env_h = Parameter(210, "env_h");

p_trench_center_y = Parameter(60, "trench_cy");
p_trench_w = Parameter(55, "trench_w");
p_trench_h = Parameter(240, "trench_h");

p_fillet_r = Parameter(8, "fillet_r");
p_fillet_n = Parameter(@(x) max(8, round(3*x)), p_fillet_r, "fillet_n", unit="");

% Array parameters.
p_arr_nx = Parameter(5, "arr_nx", unit="");
p_arr_ny = Parameter(3, "arr_ny", unit="");
p_arr_pitch_x = Parameter(70, "arr_pitch_x");
p_arr_pitch_y = Parameter(70, "arr_pitch_y");

% Dependent parameter examples for geometry dimensions.
p_line_thk_seed = Parameter(6, "line_thk_seed");
p_line_thk = Parameter(@(x) x + 2, p_line_thk_seed, "line_thk");
p_off_seed = Parameter(7, "off_seed");
p_offset_dist = Parameter(@(x) x + 3, p_off_seed, "off_dist");

% 1) Build a tower from stacked, shrinking rectangles.
tower_parts = cell(1, nlevels);
for k = 1:nlevels
    width_k = p_base_width - p_width_step*(k-1);
    center_k = Vertices([0, (k-1)], p_pitch_y);
    tower_parts{k} = Rectangle(center=center_k, width=width_k, height=p_level_height, ...
        layer="metal1");
end
tower = Union(tower_parts, layer="metal1");

% 2) Apply transforms: scale -> rotate -> move -> mirror.
tower_scaled = Scale(tower, factor=p_tower_scale, origin=Vertices([0, 0], p_pitch_y));
tower_rotated = Rotate(tower_scaled, angle=p_tower_angle, origin=Vertices([0, 0], p_pitch_y));
tower_moved = Move(tower_rotated, delta=Vertices([6, 1], p_move_unit));
tower_mirrored = Mirror(tower_moved, point=Vertices([0, 0], p_pitch_y), axis=[1, 0]);
towers = Union({tower_moved, tower_mirrored}, layer="metal1");

% 3) Intersection with an envelope.
% Use Rectangle corner mode (bottom-left corner) here.
envelope = Rectangle(base="corner", corner=[-190, -10], ...
    width=p_env_w, height=p_env_h, layer="metal1");
towers_in_envelope = Intersection({towers, envelope}, layer="metal1");

% 4) Difference: cut a central trench.
trench = Rectangle(center=Vertices([0, 1], p_trench_center_y), width=p_trench_w, ...
    height=p_trench_h, layer="metal1");
towers_cut = Difference(towers_in_envelope, {trench}, layer="metal1");

% 5) Fillet the final shape and export.
final_shape = Fillet(towers_cut, radius=p_fillet_r, npoints=p_fillet_n, ...
    points="all", layer="metal1");

% 6) Circle/Ellipse primitive examples (center and corner base modes).
circle_center = Circle(center=[180, -120], radius=24, npoints=96, ...
    layer="metal1");
ellipse_center = Ellipse(center=[180, -120], a=56, b=30, angle=30, npoints=96, ...
    layer="metal1");
ellipse_cut = Difference(ellipse_center, {circle_center}, layer="metal1");

circle_corner = Circle(base="corner", corner=[-290, 120], radius=22, npoints=96, ...
    layer="metal1");
ellipse_corner = Ellipse(base="corner", corner=[-240, 80], a=38, b=18, ...
    angle=-20, npoints=96, layer="metal1");

% 7) Add a small 2D marker array using Array1D/Array2D features.
array_seed = Rectangle(base="corner", corner=[-320, -160], width=24, height=16, ...
    angle=15, layer="metal1");
array_row = Array1D(array_seed, ncopies=p_arr_nx, ...
    delta=Vertices([1, 0], p_arr_pitch_x), layer="metal1");
array_seed = Rectangle(base="corner", corner=[-320, -160], width=24, height=16, ...
    angle=15, layer="metal1");

array_grid = Array2D(array_seed, ncopies_x=p_arr_nx, ncopies_y=p_arr_ny, ...
    delta_x=Vertices([1, 0], p_arr_pitch_x), ...
    delta_y=Vertices([0, 1], p_arr_pitch_y), ...
    layer="metal1");

% 8) Curve primitives + Thicken operation examples.
curve_points = Point(p=[-330, -240; -320, -230], marker_size=6, ...
    layer="metal1");

line_raw = LineSegment(p1=[-300, -210], p2=[-160, -180], ...
    layer="metal1");
line_thk = Thicken(line_raw, offset="symmetric", totalthick=p_line_thk, ...
    ends="circular", convexcorner="fillet", layer="metal1");

interp_raw = InterpolationCurve(points=[-300 -155; -255 -125; -205 -165; -145 -130], ...
    type="open", layer="metal1");
interp_thk = Thicken(interp_raw, offset="asymmetric", upthick=10, downthick=6, ...
    ends="straight", convexcorner="extend", layer="metal1");

quad_raw = QuadraticBezier(p0=[-80 -210], p1=[-20 -120], p2=[40 -190], ...
    type="open", npoints=96, layer="metal1");
quad_thk = Thicken(quad_raw, offset="symmetric", totalthick=12, ...
    ends="straight", convexcorner="fillet", layer="metal1");

cubic_raw = CubicBezier(p0=[60 -210], p1=[110 -110], p2=[180 -250], p3=[240 -170], ...
    type="open", npoints=128, layer="metal1");
cubic_thk = Thicken(cubic_raw, offset="symmetric", totalthick=10, ...
    ends="straight", convexcorner="noconnection", layer="metal1");

arc_raw = CircularArc(center=[320, -180], radius=55, start_angle=20, end_angle=290, ...
    type="open", npoints=160, layer="metal1");
arc_thk = Thicken(arc_raw, offset="symmetric", totalthick=16, ...
    ends="circular", convexcorner="fillet", layer="metal1");

param_raw = ParametricCurve(coord={"42*cos(s)", "20*sin(2*s)"}, parname="s", ...
    parmin=0, parmax=pi, type="open", npoints=180, ...
    layer="metal1");
param_thk = Thicken(param_raw, offset="asymmetric", upthick=9, downthick=5, ...
    ends="straight", convexcorner="tangent", layer="metal1");

param_closed = ParametricCurve(coord={"20*cos(s)", "20*sin(s)"}, parname="s", ...
    parmin=0, parmax=2*pi, type="closed", npoints=128, ...
    layer="metal1");

% 9) New operation features: Chamfer / Offset / Tangent.
chamfer_base = Rectangle(center=[-250, 220], width=90, height=60, ...
    layer="metal1");
chamfered = Chamfer(chamfer_base, dist=10, points=[1 2 3 4], ...
    layer="metal1");

offset_base = Rectangle(center=[-120, 220], width=100, height=45, ...
    layer="metal1");
offset_shape = Offset(offset_base, distance=p_offset_dist, reverse=false, ...
    convexcorner="fillet", trim=true, keep=false, layer="metal1");

tangent_circle = Circle(center=[30, 220], radius=28, npoints=96, ...
    layer="metal1");
tangent_line = Tangent(tangent_circle, type="coord", coord=[95, 250], ...
    start=0.7, edge_index=1, width=8, layer="metal1");
envelope = Rectangle(base="corner", corner=[-187, -10], ...
    width=p_env_w, height=p_env_h, layer="metal1");

ctx.build_comsol();
ctx.export_gds("out.gds");

% Consolidated build report (includes snap report).
ctx.build_report();
