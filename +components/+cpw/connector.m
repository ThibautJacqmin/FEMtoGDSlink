function out = connector(ctx, p_edge, p_target, opts)
arguments
    ctx core.GeometryPipeline
    p_edge routing.PortRef
    p_target routing.PortRef
    opts.name {mustBeTextScalar} = "connector_0"
    opts.fillet = 0
end

out = routing.connect(ctx, p_edge, p_target, name=opts.name, fillet=opts.fillet);
end
