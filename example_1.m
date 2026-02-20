import core.*
import types.*
import primitives.*
import ops.*

% Example 1: tower composition with transforms + boolean operations + fillet.
ctx = GeometryPipeline.with_shared_comsol(enable_comsol=false, ...
                                         enable_gds=true, ...
                                         comsol_api="mph", ...
                                         preview_klayout=true, ...
                                         snap_on_grid=false, ...
                                         gds_resolution_nm=1, ...
                                         warn_on_snap=true, ...
                                         reset_model=true);

ctx.add_layer("metal1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="metal1", comsol_selection_state="all");

% Base unit helper (all geometry lengths in um).
p_um = Parameter(1, "u_ex1", unit="um");

nlevels = 6;
p_pitch_y = Parameter(36, "pitch_y1", unit="um");
p_base_width = Parameter(260, "tower_w0", unit="um");
p_width_step = Parameter(32, "tower_dw", unit="um");
p_level_height = Parameter(28, "tower_h", unit="um");
p_tower_scale = Parameter(0.92, "tower_scale", unit="");
p_tower_angle = Parameter(8, "tower_rot_deg", unit="deg");
p_move_unit = Parameter(20, "tower_move_unit", unit="um");

p_env_w = Parameter(380, "env_w", unit="um");
p_env_h = Parameter(210, "env_h", unit="um");
p_trench_center_y = Parameter(60, "trench_cy", unit="um");
p_trench_w = Parameter(55, "trench_w", unit="um");
p_trench_h = Parameter(240, "trench_h", unit="um");
p_fillet_r = Parameter(8, "fillet_r", unit="um");
p_fillet_n = Parameter(@(x) max(8, round(3*x)), p_fillet_r, "fillet_n", unit="");
p_env_corner = p_um*Vertices([-190, -10]);

tower_parts = cell(1, nlevels);
for k = 1:nlevels
    width_k = p_base_width - p_width_step * (k - 1);
    center_k = Vertices([0, (k - 1)])*p_pitch_y;
    tower_parts{k} = Rectangle(center=center_k, width=width_k, height=p_level_height, ...
        layer="metal1");
end
tower = Union(tower_parts, layer="metal1");

tower_scaled = Scale(tower, factor=p_tower_scale, origin=Vertices([0, 0], p_um));
tower_rotated = Rotate(tower_scaled, angle=p_tower_angle, origin=Vertices([0, 0], p_um));
tower_moved = Move(tower_rotated, delta=Vertices([6, 1], p_move_unit));
tower_mirrored = Mirror(tower_moved, point=Vertices([0, 0], p_um), axis=[1, 0]);
towers = Union({tower_moved, tower_mirrored}, layer="metal1");

envelope = Rectangle(base="corner", corner=p_env_corner, ...
    width=p_env_w, height=p_env_h, layer="metal1");
towers_in_envelope = Intersection({towers, envelope}, layer="metal1");

trench = Rectangle(center=Vertices([0, 1], p_trench_center_y), width=p_trench_w, ...
    height=p_trench_h, layer="metal1");
towers_cut = Difference(towers_in_envelope, {trench}, layer="metal1");

Fillet(towers_cut, radius=p_fillet_r, npoints=p_fillet_n, ...
    points="all", layer="metal1");

ctx.build();
