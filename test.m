ctx = GeometrySession(enable_comsol=false, enable_gds=true, emit_on_create=false, ...
    snap_mode="strict", snap_grid_nm=1, warn_on_snap=true);
ctx.add_layer("metal1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="metal1", comsol_selection_state="all");

% 1) Build a tower from stacked, shrinking rectangles.
nlevels = 6;
step_y = 36;
tower_parts = cell(1, nlevels);
for k = 1:nlevels
    width_k = 260 - (k-1)*32;
    center_k = [0, (k-1)*step_y];
    tower_parts{k} = Rectangle(center=center_k, width=width_k, height=28, ...
        layer="metal1", output=false);
end
tower = Union(tower_parts, layer="metal1", output=false);

% 2) Apply transforms: scale -> rotate -> move -> mirror.
tower_scaled = Scale(tower, factor=0.92, origin=[0, 0], output=false);
tower_rotated = Rotate(tower_scaled, angle=8, origin=[0, 0], output=false);
tower_moved = Move(tower_rotated, delta=[120, 20], output=false);
tower_mirrored = Mirror(tower_moved, point=[0, 0], axis=[1, 0], output=false);
towers = Union({tower_moved, tower_mirrored}, layer="metal1", output=false);

% 3) Intersection with an envelope.
envelope = Rectangle(center=[0, 95], width=380, height=210, layer="metal1", output=false);
towers_in_envelope = Intersection({towers, envelope}, layer="metal1", output=false);

% 4) Difference: cut a central trench.
trench = Rectangle(center=[0, 60], width=55, height=240, layer="metal1", output=false);
towers_cut = Difference(towers_in_envelope, {trench}, layer="metal1", output=false);

% 5) Fillet the final shape and export.
final_shape = Fillet(towers_cut, radius=8, npoints=24, layer="metal1", output=true); %#ok<NASGU>

% To debug in COMSOL as you build:
% ctx = GeometrySession(enable_comsol=true, enable_gds=true, emit_on_create=true);
% ctx.build_comsol();
ctx.export_gds("out.gds");
