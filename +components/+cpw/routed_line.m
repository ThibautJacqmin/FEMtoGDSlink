function out = routed_line(ctx, p1, p2, opts)
arguments
    ctx core.GeometryPipeline
    p1 routing.PortRef
    p2 routing.PortRef
    opts.name {mustBeTextScalar} = "cpw_line_0"
    opts.fillet = 0
    opts.start_straight = 0
    opts.end_straight = []
    opts.bend {mustBeTextScalar} = "auto"
end

out = routing.connect(ctx, p1, p2, ...
    name=opts.name, ...
    fillet=opts.fillet, ...
    start_straight=opts.start_straight, ...
    end_straight=opts.end_straight, ...
    bend=opts.bend);
end
