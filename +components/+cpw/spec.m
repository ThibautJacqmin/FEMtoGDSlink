function s = spec(sig_w, gap_w, opts)
arguments
    sig_w
    gap_w
    opts.layer_sig {mustBeTextScalar} = "metal1"
    opts.layer_gap {mustBeTextScalar} = "gap"
    opts.include_mask logical = false
    opts.mask_gap = 0
    opts.mask_layer {mustBeTextScalar} = "gap"
    opts.mask_subname {mustBeTextScalar} = "mask"
end

s = routing.PortSpec( ...
    widths={sig_w, gap_w}, ...
    offsets={0, 0}, ...
    layers=[string(opts.layer_sig), string(opts.layer_gap)], ...
    subnames=["sig", "gap"]);

if opts.include_mask
    s = s.with_mask(layer=opts.mask_layer, gap=opts.mask_gap, subname=opts.mask_subname);
end
end
