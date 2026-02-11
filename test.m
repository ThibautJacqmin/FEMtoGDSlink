ctx = GeometrySession.with_shared_comsol(enable_gds=true, emit_on_create=false, ...
    snap_mode='off', snap_grid_nm=1, warn_on_snap=true, reset_model=true);

ctx.add_layer("metal1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="metal1", comsol_selection_state="all");

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
p_fillet_n = DependentParameter(@(x) max(8, round(3*x)), p_fillet_r, "fillet_n", unit="");

% Array parameters.
p_arr_nx = Parameter(5, "arr_nx", unit="");
p_arr_ny = Parameter(3, "arr_ny", unit="");
p_arr_pitch_x = Parameter(70, "arr_pitch_x");
p_arr_pitch_y = Parameter(70, "arr_pitch_y");

% 1) Build a tower from stacked, shrinking rectangles.
tower_parts = cell(1, nlevels);
for k = 1:nlevels
    width_k = p_base_width - p_width_step*(k-1);
    center_k = Vertices([0, (k-1)], p_pitch_y);
    tower_parts{k} = Rectangle(center=center_k, width=width_k, height=p_level_height, ...
        layer="metal1", output=false);
end
tower = Union(tower_parts, layer="metal1", output=false);

% 2) Apply transforms: scale -> rotate -> move -> mirror.
tower_scaled = Scale(tower, factor=p_tower_scale, origin=Vertices([0, 0], p_pitch_y), output=false);
tower_rotated = Rotate(tower_scaled, angle=p_tower_angle, origin=Vertices([0, 0], p_pitch_y), output=false);
tower_moved = Move(tower_rotated, delta=Vertices([6, 1], p_move_unit), output=false);
tower_mirrored = Mirror(tower_moved, point=Vertices([0, 0], p_pitch_y), axis=[1, 0], output=false);
towers = Union({tower_moved, tower_mirrored}, layer="metal1", output=false);

% 3) Intersection with an envelope.
% Use Rectangle corner mode (bottom-left corner) here.
envelope = Rectangle(base="corner", corner=[-190, -10], ...
    width=p_env_w, height=p_env_h, layer="metal1", output=false);
towers_in_envelope = Intersection({towers, envelope}, layer="metal1", output=false);

% 4) Difference: cut a central trench.
trench = Rectangle(center=Vertices([0, 1], p_trench_center_y), width=p_trench_w, ...
    height=p_trench_h, layer="metal1", output=false);
towers_cut = Difference(towers_in_envelope, {trench}, layer="metal1", output=false);

% 5) Fillet the final shape and export.
final_shape = Fillet(towers_cut, radius=p_fillet_r, npoints=p_fillet_n, ...
    points="all", layer="metal1", output=true);

% 6) Circle/Ellipse primitive examples (center and corner base modes).
circle_center = Circle(center=[180, -120], radius=24, npoints=96, ...
    layer="metal1", output=false);
ellipse_center = Ellipse(center=[180, -120], a=56, b=30, angle=30, npoints=96, ...
    layer="metal1", output=false);
ellipse_cut = Difference(ellipse_center, {circle_center}, layer="metal1", output=true);

circle_corner = Circle(base="corner", corner=[-290, 120], radius=22, npoints=96, ...
    layer="metal1", output=true);
ellipse_corner = Ellipse(base="corner", corner=[-240, 80], a=38, b=18, ...
    angle=-20, npoints=96, layer="metal1", output=true);

% 7) Add a small 2D marker array using Array1D/Array2D features.
array_seed = Rectangle(base="corner", corner=[-320, -160], width=24, height=16, ...
    angle=15, layer="metal1", output=false);
array_row = Array1D(array_seed, ncopies=p_arr_nx, ...
    delta=Vertices([1, 0], p_arr_pitch_x), layer="metal1", output=false);
array_grid = Array2D(array_seed, ncopies_x=p_arr_nx, ncopies_y=p_arr_ny, ...
    delta_x=Vertices([1, 0], p_arr_pitch_x), ...
    delta_y=Vertices([0, 1], p_arr_pitch_y), ...
    layer="metal1", output=true);

% To debug in COMSOL as you build:
ctx.build_comsol();
ctx.export_gds("out.gds");

% Consolidated build report (includes snap report).
ctx.build_report();
