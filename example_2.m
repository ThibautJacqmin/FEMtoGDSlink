import core.*
import types.*
import primitives.*
import ops.*
import lattices.*

% Example 2: primitive shapes, arrays, and lattice-driven replication.
ctx = GeometrySession.with_shared_comsol(use_comsol=true, use_gds=true, ...
    snap_mode='off', gds_resolution_nm=1, warn_on_snap=true, reset_model=true);

ctx.add_layer("metal1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="metal1", comsol_selection_state="all", emit_to_comsol=true);

% Base unit helper (all geometry lengths in um).
p_um = Parameter(1, "u_ex2", unit="um");

p_main_center = Vertices([180, -120], p_um);
p_circle_r = Parameter(24, "cir_r_main", unit="um");
p_ellipse_a = Parameter(56, "ell_a_main", unit="um");
p_ellipse_b = Parameter(30, "ell_b_main", unit="um");
p_ellipse_ang = Parameter(30, "ell_ang_main", unit="deg");
circle_center = Circle(center=p_main_center, radius=p_circle_r, npoints=96, ...
    layer="metal1");
ellipse_center = Ellipse(center=p_main_center, a=p_ellipse_a, b=p_ellipse_b, ...
    angle=p_ellipse_ang, npoints=96, ...
    layer="metal1");
Difference(ellipse_center, {circle_center}, layer="metal1");

p_corner_circle = Vertices([-290, 120], p_um);
p_corner_ellipse = Vertices([-240, 80], p_um);
p_corner_circle_r = Parameter(22, "cir_r_corner", unit="um");
p_corner_ellipse_a = Parameter(38, "ell_a_corner", unit="um");
p_corner_ellipse_b = Parameter(18, "ell_b_corner", unit="um");
p_corner_ellipse_ang = Parameter(-20, "ell_ang_corner", unit="deg");
Circle(base="corner", corner=p_corner_circle, radius=p_corner_circle_r, npoints=96, ...
    layer="metal1");
Ellipse(base="corner", corner=p_corner_ellipse, a=p_corner_ellipse_a, b=p_corner_ellipse_b, ...
    angle=p_corner_ellipse_ang, npoints=96, layer="metal1");

p_arr_nx = Parameter(5, "arr_nx", unit="");
p_arr_ny = Parameter(3, "arr_ny", unit="");
p_arr_pitch_x = Parameter(70, "arr_pitch_x", unit="um");
p_arr_pitch_y = Parameter(70, "arr_pitch_y", unit="um");
p_arr_seed_corner = Vertices([-320, -160], p_um);
p_arr_seed_w = Parameter(24, "arr_seed_w", unit="um");
p_arr_seed_h = Parameter(16, "arr_seed_h", unit="um");
p_arr_seed_ang = Parameter(15, "arr_seed_ang", unit="deg");

array_seed_row = Rectangle(base="corner", corner=p_arr_seed_corner, ...
    width=p_arr_seed_w, height=p_arr_seed_h, angle=p_arr_seed_ang, layer="metal1");
Array1D(array_seed_row, ncopies=p_arr_nx, ...
    delta=Vertices([1, 0], p_arr_pitch_x), layer="metal1");

array_seed_grid = Rectangle(base="corner", corner=p_arr_seed_corner, ...
    width=p_arr_seed_w, height=p_arr_seed_h, angle=p_arr_seed_ang, layer="metal1");
Array2D(array_seed_grid, ncopies_x=p_arr_nx, ncopies_y=p_arr_ny, ...
    delta_x=Vertices([1, 0], p_arr_pitch_x), ...
    delta_y=Vertices([0, 1], p_arr_pitch_y), ...
    layer="metal1");

p_lattice_a = Parameter(46, "lat_a", unit="um");
p_hex_seed_center = Vertices([0, 0], p_um);
p_hex_seed_r = Parameter(4, "lat_hex_seed_r", unit="um");
seed_hex = Circle(center=p_hex_seed_center, radius=p_hex_seed_r, npoints=72, layer="metal1");
[~, ~] = Lattice.createLattice(lattice="Hexagonal", ...
    a=p_lattice_a.value, nw=5, nh=4, seed=seed_hex, ctx=ctx, ...
    a_parameter=p_lattice_a, layer="metal1");

p_honey_seed_A_r = Parameter(2.5, "lat_honey_seedA_r", unit="um");
p_honey_seed_B_w = Parameter(4, "lat_honey_seedB_w", unit="um");
p_honey_seed_B_h = Parameter(4, "lat_honey_seedB_h", unit="um");
seed_honey_A = Circle(center=p_hex_seed_center, radius=p_honey_seed_A_r, npoints=72, ...
    layer="metal1");
seed_honey_B = Rectangle(center=p_hex_seed_center, width=p_honey_seed_B_w, ...
    height=p_honey_seed_B_h, layer="metal1");
[~, ~] = Lattice.createLattice(lattice="HoneyComb", ...
    a=p_lattice_a.value, nw=4, nh=3, seedA=seed_honey_A, seedB=seed_honey_B, ...
    sublattice="AB", ctx=ctx, a_parameter=p_lattice_a, layer="metal1");

ctx.build_comsol();
ctx.export_gds("example_2.gds");
ctx.build_report();
