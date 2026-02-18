function out = connect(ctx, port_in, port_out, opts)
arguments
    ctx core.GeometrySession
    port_in routing.PortRef
    port_out routing.PortRef
    opts.name {mustBeTextScalar} = "conn_0"
    opts.mode {mustBeTextScalar} = "manhattan" % "manhattan"|"auto"
    opts.fillet = 0
    opts.start_straight = 0
    opts.end_straight = []
    opts.bend {mustBeTextScalar} = "auto"
    opts.allow_mismatch logical = false
    opts.adaptor routing.AdaptorSpec = routing.AdaptorSpec()
    opts.meander routing.MeanderSpec = routing.MeanderSpec.disabled()
    opts.target routing.TargetLengthSpec = routing.TargetLengthSpec.disabled()
    opts.layer_override = []
    opts.merge_per_layer logical = true
    opts.ends {mustBeTextScalar} = "straight"
    opts.convexcorner {mustBeTextScalar} = "fillet"
end

spec_ok = port_in.spec.is_compatible(port_out.spec);
if ~spec_ok && ~opts.allow_mismatch
    error("routing:connect:SpecMismatch", ...
        "Port specs mismatch. Set allow_mismatch=true and provide adaptor strategy.");
end

route_port_in = port_in;
route_port_out = port_out;
adaptor_in = {};
adaptor_out = {};
if ~spec_ok && opts.allow_mismatch && opts.adaptor.enabled
    [adaptor_in, adaptor_out, route_port_in, route_port_out] = ...
        routing.internal.build_adaptor_linear(ctx, port_in, port_out, opts.adaptor);
end
fixed_adaptor_len_nm = adaptor_extra_length_nm( ...
    port_in, route_port_in, port_out, route_port_out);
fillet_eff = effective_fillet_nm(route_port_in.spec, opts.fillet, opts.convexcorner);

switch lower(string(opts.mode))
    case "manhattan"
        route_local = routing.Route.manhattan( ...
            route_port_in, route_port_out, ...
            start_straight=opts.start_straight, ...
            end_straight=opts.end_straight, ...
            bend=opts.bend, ...
            fillet=fillet_eff);
    case "auto"
        route_local = routing.internal.route_auto_select( ...
            route_port_in, route_port_out, ...
            start_straight=opts.start_straight, ...
            end_straight=opts.end_straight, ...
            bend=opts.bend, ...
            fillet=fillet_eff);
    otherwise
        error("routing:connect:InvalidMode", "Unknown mode '%s'.", string(opts.mode));
end

if opts.target.enabled
    target_local = opts.target;
    if isfinite(target_local.length_nm)
        target_local.length_nm = target_local.length_nm - fixed_adaptor_len_nm;
    end
    solve = routing.internal.solve_target_length(route_local, target_local, opts.meander);
    route_local = solve.route;
elseif opts.meander.enabled
    route_local = routing.internal.apply_meander_serpentine(route_local, opts.meander);
end

require_matching_specs = route_port_in.spec.is_compatible(route_port_out.spec);
cable = routing.Cable(ctx, route_port_in, route_port_out, ...
    route=route_local, ...
    name=opts.name, ...
    layer_override=opts.layer_override, ...
    merge_per_layer=opts.merge_per_layer, ...
    ends=opts.ends, ...
    convexcorner=opts.convexcorner, ...
    require_matching_specs=require_matching_specs);

len_nm = cable.length_nm() + fixed_adaptor_len_nm;
achieved = true;
if opts.target.enabled
    achieved = abs(len_nm - opts.target.length_nm) <= opts.target.tolerance_nm;
end

out = routing.ConnectionResult( ...
    route=route_local, ...
    cable=cable, ...
    adaptor_in=adaptor_in, ...
    adaptor_out=adaptor_out, ...
    length_nm=len_nm, ...
    achieved_target=achieved);
end

function y = adaptor_extra_length_nm(port_in, route_in, port_out, route_out)
y = 0;
if ~isempty(route_in)
    d_in = norm(route_in.position_value() - port_in.position_value());
    if d_in > 1e-12
        y = y + d_in;
    end
end
if ~isempty(route_out)
    d_out = norm(route_out.position_value() - port_out.position_value());
    if d_out > 1e-12
        y = y + d_out;
    end
end
end

function f = effective_fillet_nm(spec, fillet_raw, convexcorner)
f = local_scalar_value(fillet_raw, "fillet");
if f <= 0
    return;
end
if lower(string(convexcorner)) ~= "fillet"
    return;
end
min_f = 0.5 * max(spec.widths_value());
if f < min_f
    f = min_f;
end
end

function y = local_scalar_value(val, label)
if isa(val, 'types.Parameter')
    y = val.value;
else
    y = val;
end
if ~(isscalar(y) && isnumeric(y) && isfinite(y))
    error("routing:connect:InvalidScalar", ...
        "Option '%s' must resolve to a finite scalar.", char(string(label)));
end
y = double(y);
end
