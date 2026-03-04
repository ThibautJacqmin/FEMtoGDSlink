function wafer = two_inch(ctx, opts)
arguments
    ctx core.GeometryPipeline = core.GeometryPipeline.empty
    opts.layer = "default"
end

if isempty(ctx)
    ctx = core.GeometryPipeline.require_current();
end

filename = fullfile(core.GdsModeler.get_repo_root(), "Library", "two_inch_wafer.mat");
if ~isfile(filename)
    error("components:wafer:TwoInchFileMissing", ...
        "Wafer file not found: %s", char(filename));
end

data = load(filename);
if ~isfield(data, "wafer_edge")
    error("components:wafer:TwoInchMissingField", ...
        "Missing 'wafer_edge' in %s.", char(filename));
end

verts = data.wafer_edge;
if ~(isnumeric(verts) && ismatrix(verts) && size(verts, 2) == 2 && size(verts, 1) >= 3)
    error("components:wafer:TwoInchInvalidField", ...
        "'wafer_edge' must be an Nx2 numeric array in %s.", char(filename));
end

wafer = primitives.Polygon(ctx, ...
    vertices=types.Vertices(double(verts) * 1e3), ...
    layer=opts.layer);
end

