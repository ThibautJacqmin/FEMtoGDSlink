function feat = taper(ctx, p, layer, width0_nm, width1_nm, opts)
arguments
    ctx core.GeometrySession
    p routing.PortRef
    layer {mustBeTextScalar}
    width0_nm double
    width1_nm double
    opts.along0_nm double = -100
    opts.along1_nm double = 0
end

u = p.ori;
n = p.normal();
p0 = p.position_value() + opts.along0_nm * u;
p1 = p.position_value() + opts.along1_nm * u;

verts = [
    p0 + 0.5 * width0_nm * n;
    p0 - 0.5 * width0_nm * n;
    p1 - 0.5 * width1_nm * n;
    p1 + 0.5 * width1_nm * n];

pref = p.pos.prefactor;
feat = primitives.Polygon(ctx, vertices=types.Vertices(verts / pref.value, pref), layer=layer);
end
