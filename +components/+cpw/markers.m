function feats = markers(p, opts)
arguments
    p routing.PortRef
    opts.ctx core.GeometrySession = core.GeometrySession.empty
    opts.layer = "portmark"
    opts.tip_length = []
    opts.tip_scale double = 1/3
end

feats = p.draw_markers( ...
    ctx=opts.ctx, layer=opts.layer, ...
    tip_length=opts.tip_length, tip_scale=opts.tip_scale);
end
