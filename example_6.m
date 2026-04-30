import core.*
import primitives.*
import ops.*

% Example 6: layer-level boolean operations in GeometryPipeline.
% This example creates two source layers and computes:
% - merge_layers(src_a, src_b)
% - subtract_layers(src_a, src_b)
% - intersect_layers(src_a, src_b)
ctx = GeometryPipeline(enable_comsol=false, enable_gds=true, ...
    preview_klayout=false, ...
    snap_on_grid=false, ...
    gds_resolution_nm=1, ...
    warn_on_snap=true);

src_a = ctx.add_layer("src_a", gds_layer=1, gds_datatype=0);
src_b = ctx.add_layer("src_b", gds_layer=2, gds_datatype=0);
lay_merge = ctx.add_layer("merge_ab", gds_layer=10, gds_datatype=0);
lay_sub = ctx.add_layer("sub_a_minus_b", gds_layer=11, gds_datatype=0);
lay_int = ctx.add_layer("int_ab", gds_layer=12, gds_datatype=0);

% Build one composite shape on source layer A.
rect_a1 = Rectangle(ctx, center=[0, 0], width=7000, height=3600, layer=src_a);
rect_a2 = Rectangle(ctx, center=[2500, 0], width=2200, height=5600, layer=src_a);
ops.Union(ctx, {rect_a1, rect_a2}, layer=src_a, keep_input_objects=false);

% Build one composite shape on source layer B.
circ_b = Circle(ctx, center=[1700, 300], radius=2200, npoints=96, layer=src_b);
rect_b = Rectangle(ctx, center=[200, -1200], width=3000, height=1800, layer=src_b);
ops.Union(ctx, {circ_b, rect_b}, layer=src_b, keep_input_objects=false);

% Compute layer-level booleans on dedicated output layers.
ctx.merge_layers(src_a, src_b, output_layer=lay_merge, preserve_sources=true);
ctx.subtract_layers(src_a, src_b, output_layer=lay_sub, preserve_sources=true);
ctx.intersect_layers(src_a, src_b, output_layer=lay_int, preserve_sources=true);

out = ctx.build(gds_filename="example_6_layer_booleans.gds", report=false);
if out.built_gds
    fprintf("Example 6 GDS written: %s\n", string(out.gds_filename));
end
