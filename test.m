ctx = GeometrySession(enable_comsol=false, enable_gds=true);
ctx.add_layer("metal1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");

r1 = Rectangle(ctx, center=[0 0], width=100, height=50, layer="metal1");
r2 = Rectangle(ctx, center=[20 0], width=30, height=30, layer="metal1");

u = Union(ctx, {r1, r2}, output=true);
r1.output = false;
r2.output = false;

m = Move(ctx, u, delta=[10 0]);
f = Fillet(ctx, m, radius=2, npoints=16, points=[1 2 3 4]);

%ctx.build_comsol();
ctx.export_gds("out.gds");
