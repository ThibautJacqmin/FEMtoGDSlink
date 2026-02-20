function out = edge_launch(ctx, narrow_port, opts)
arguments
    ctx core.GeometryPipeline
    narrow_port routing.PortRef
    opts.name {mustBeTextScalar} = "edge_launch_0"
    opts.length_nm double = 120
    opts.sig_wide_nm double = 90
    opts.gap_wide_nm double = 160
    opts.direction {mustBeTextScalar} = "outward" % "outward"|"inward"
end

s = narrow_port.spec;
sig_n = s.width_value(1);
gap_n = s.width_value(2);

if lower(string(opts.direction)) == "outward"
    along0 = -opts.length_nm;
    along1 = 0;
else
    along0 = 0;
    along1 = opts.length_nm;
end

f_sig = components.cpw.taper(ctx, narrow_port, s.layers(1), ...
    opts.sig_wide_nm, sig_n, along0_nm=along0, along1_nm=along1);
f_gap = components.cpw.taper(ctx, narrow_port, s.layers(2), ...
    opts.gap_wide_nm, gap_n, along0_nm=along0, along1_nm=along1);

wide_pos = narrow_port.position_value() + along0 * narrow_port.ori;
pref = narrow_port.pos.prefactor;
wide_spec = routing.PortSpec( ...
    widths={opts.sig_wide_nm, opts.gap_wide_nm}, ...
    offsets={0, 0}, ...
    layers=s.layers(1:2), ...
    subnames=s.subnames(1:2));
wide_port = routing.PortRef( ...
    name=string(opts.name) + "_wide", ...
    pos=types.Vertices(wide_pos / pref.value, pref), ...
    ori=narrow_port.ori, ...
    spec=wide_spec);

out = struct( ...
    "narrow_port", narrow_port, ...
    "wide_port", wide_port, ...
    "features", {{f_sig, f_gap}});
end
