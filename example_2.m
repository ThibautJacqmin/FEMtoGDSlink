import core.*
import types.*
import primitives.*
import ops.*
import lattices.*

% Example 2: primitive shapes, arrays, and lattice-driven replication.
ctx = GeometrySession.with_shared_comsol(use_comsol=true, use_gds=true, ...
    snap_mode='off', snap_grid_nm=1, warn_on_snap=true, reset_model=true);

ctx.add_layer("metal1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="metal1", comsol_selection_state="all", emit_to_comsol=true);

circle_center = Circle(center=[180, -120], radius=24, npoints=96, ...
    layer="metal1");
ellipse_center = Ellipse(center=[180, -120], a=56, b=30, angle=30, npoints=96, ...
    layer="metal1");
Difference(ellipse_center, {circle_center}, layer="metal1");

Circle(base="corner", corner=[-290, 120], radius=22, npoints=96, ...
    layer="metal1");
Ellipse(base="corner", corner=[-240, 80], a=38, b=18, ...
    angle=-20, npoints=96, layer="metal1");

p_arr_nx = Parameter(5, "arr_nx", unit="");
p_arr_ny = Parameter(3, "arr_ny", unit="");
p_arr_pitch_x = Parameter(70, "arr_pitch_x");
p_arr_pitch_y = Parameter(70, "arr_pitch_y");

array_seed_row = Rectangle(base="corner", corner=[-320, -160], width=24, height=16, ...
    angle=15, layer="metal1");
Array1D(array_seed_row, ncopies=p_arr_nx, ...
    delta=Vertices([1, 0], p_arr_pitch_x), layer="metal1");

array_seed_grid = Rectangle(base="corner", corner=[-320, -160], width=24, height=16, ...
    angle=15, layer="metal1");
Array2D(array_seed_grid, ncopies_x=p_arr_nx, ncopies_y=p_arr_ny, ...
    delta_x=Vertices([1, 0], p_arr_pitch_x), ...
    delta_y=Vertices([0, 1], p_arr_pitch_y), ...
    layer="metal1");

p_lattice_a = Parameter(46, "lat_a");
seed_hex = Circle(center=[0, 0], radius=4, npoints=72, layer="metal1");
[~, ~] = Lattice.createLattice(lattice="Hexagonal", ...
    a=p_lattice_a.value, nw=5, nh=4, seed=seed_hex, ctx=ctx, ...
    a_parameter=p_lattice_a, layer="metal1");

seed_honey_A = Circle(center=[0, 0], radius=2.5, npoints=72, layer="metal1");
seed_honey_B = Rectangle(center=[0, 0], width=4, height=4, layer="metal1");
[~, ~] = Lattice.createLattice(lattice="HoneyComb", ...
    a=p_lattice_a.value, nw=4, nh=3, seedA=seed_honey_A, seedB=seed_honey_B, ...
    sublattice="AB", ctx=ctx, a_parameter=p_lattice_a, layer="metal1");

ctx.build_comsol();
ctx.export_gds("example_2.gds");
ctx.build_report();
