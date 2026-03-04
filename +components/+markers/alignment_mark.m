function mark = alignment_mark(ctx, opts)
arguments
    ctx core.GeometryPipeline = core.GeometryPipeline.empty
    opts.type (1,1) double {mustBeInteger, mustBePositive} = 1
    opts.layer = "default"
    opts.keep_input_objects logical = true
end

if isempty(ctx)
    ctx = core.GeometryPipeline.require_current();
end

filename = fullfile(core.GdsModeler.get_repo_root(), "Library", ...
    "alignment_mark_type_" + string(opts.type) + ".mat");
if ~isfile(filename)
    error("components:markers:AlignmentMarkFileMissing", ...
        "Alignment mark file not found: %s", char(filename));
end

data = load(filename);
fields = fieldnames(data);
members = cell(0, 1);

for i = 1:numel(fields)
    verts = data.(fields{i});
    if ~(isnumeric(verts) && ismatrix(verts) && size(verts, 2) == 2 && size(verts, 1) >= 3)
        continue;
    end
    verts_nm = double(verts) * 1e3;
    members{end+1, 1} = primitives.Polygon(ctx, ... %#ok<AGROW>
        vertices=types.Vertices(verts_nm), ...
        layer=opts.layer);
end

if isempty(members)
    error("components:markers:AlignmentMarkEmpty", ...
        "No valid polygon data found in %s.", char(filename));
end

if numel(members) == 1
    mark = members{1};
else
    mark = ops.Union(ctx, members, layer=opts.layer, ...
        keep_input_objects=opts.keep_input_objects);
end
end

