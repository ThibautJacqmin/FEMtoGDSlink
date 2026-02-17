function [adaptor_in, adaptor_out, route_port_in, route_port_out] = ...
    build_adaptor_linear(ctx, port_in, port_out, adaptor_spec)
% Build linear transition polygons and shifted route-side ports.
arguments
    ctx core.GeometrySession
    port_in routing.PortRef
    port_out routing.PortRef
    adaptor_spec routing.AdaptorSpec
end

style = lower(string(adaptor_spec.style));
if style ~= "linear"
    error("routing:adaptor:UnsupportedStyle", ...
        "Unsupported adaptor style '%s'.", char(style));
end

nin = port_in.spec.ntracks;
nout = port_out.spec.ntracks;
if nin ~= nout
    error("routing:adaptor:TrackCountMismatch", ...
        "Linear adaptor requires same number of tracks (in=%d, out=%d).", nin, nout);
end

pref_in = port_in.pos.prefactor;
pref_out = port_out.pos.prefactor;
if abs(pref_in.value - pref_out.value) > 1e-12 || string(pref_in.unit) ~= string(pref_out.unit)
    error("routing:adaptor:InconsistentUnits", ...
        "Port prefactors must match for adaptor generation.");
end

w_in = port_in.spec.widths_value();
w_out = port_out.spec.widths_value();
o_in = port_in.spec.offsets_value();
o_out = port_out.spec.offsets_value();

if isfinite(adaptor_spec.length_nm) && adaptor_spec.length_nm > 0
    len_nm = double(adaptor_spec.length_nm);
else
    slope = max(1e-3, double(adaptor_spec.slope));
    delta = max([abs(w_out - w_in), abs(o_out - o_in), 1]);
    len_nm = max(60, max(delta) / slope);
end

alpha = 0.5;
w_mid = (1 - alpha) * w_in + alpha * w_out;
o_mid = (1 - alpha) * o_in + alpha * o_out;
layers_mid = port_in.spec.layers;
subnames_mid = port_in.spec.subnames;
if any(string(port_in.spec.layers) ~= string(port_out.spec.layers))
    warning("routing:adaptor:LayerMismatch", ...
        "Port layers differ across mismatch; using input port layers for route core.");
end

mid_spec = routing.PortSpec( ...
    widths=num2cell(w_mid), ...
    offsets=num2cell(o_mid), ...
    layers=layers_mid, ...
    subnames=subnames_mid);

pos_in_route = port_in.position_value() + len_nm * port_in.ori;
pos_out_route = port_out.position_value() - len_nm * port_out.ori;

route_port_in = routing.PortRef( ...
    name=port_in.name + "_adp", ...
    pos=types.Vertices(pos_in_route / pref_in.value, pref_in), ...
    ori=port_in.ori, ...
    spec=mid_spec);
route_port_out = routing.PortRef( ...
    name=port_out.name + "_adp", ...
    pos=types.Vertices(pos_out_route / pref_out.value, pref_out), ...
    ori=port_out.ori, ...
    spec=mid_spec);

adaptor_in = build_linear_set(ctx, port_in, ...
    width_start=w_in, offset_start=o_in, ...
    width_end=w_mid, offset_end=o_mid, ...
    layers=layers_mid, ...
    along0_nm=0, along1_nm=len_nm);

adaptor_out = build_linear_set(ctx, port_out, ...
    width_start=w_mid, offset_start=o_mid, ...
    width_end=w_out, offset_end=o_out, ...
    layers=layers_mid, ...
    along0_nm=-len_nm, along1_nm=0);
end

function feats = build_linear_set(ctx, port, args)
arguments
    ctx core.GeometrySession
    port routing.PortRef
    args.width_start (1, :) double
    args.offset_start (1, :) double
    args.width_end (1, :) double
    args.offset_end (1, :) double
    args.layers (1, :) string
    args.along0_nm (1, 1) double
    args.along1_nm (1, 1) double
end

n = numel(args.width_start);
feats = cell(1, n);
u = port.ori;
nrm = port.normal();
pref = port.pos.prefactor;
p0_base = port.position_value() + args.along0_nm * u;
p1_base = port.position_value() + args.along1_nm * u;

for i = 1:n
    c0 = p0_base + args.offset_start(i) * nrm;
    c1 = p1_base + args.offset_end(i) * nrm;
    w0 = args.width_start(i);
    w1 = args.width_end(i);
    verts = [ ...
        c0 + 0.5 * w0 * nrm; ...
        c0 - 0.5 * w0 * nrm; ...
        c1 - 0.5 * w1 * nrm; ...
        c1 + 0.5 * w1 * nrm];
    feats{i} = primitives.Polygon(ctx, ...
        vertices=types.Vertices(verts / pref.value, pref), ...
        layer=args.layers(i));
end
end
