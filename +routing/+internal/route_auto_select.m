function route = route_auto_select(port_in, port_out, opts)
% Select an auto-routed centerline from several Manhattan-style candidates.
arguments
    port_in routing.PortRef
    port_out routing.PortRef
    opts.start_straight = 0
    opts.end_straight = []
    opts.fillet = 0
    opts.bend {mustBeTextScalar} = "auto"
end

bend_mode = lower(string(opts.bend));
if bend_mode ~= "auto"
    route = routing.Route.manhattan( ...
        port_in, port_out, ...
        start_straight=opts.start_straight, ...
        end_straight=opts.end_straight, ...
        bend=bend_mode, ...
        fillet=opts.fillet);
    return;
end

s0 = local_scalar(opts.start_straight, "start_straight");
if isempty(opts.end_straight)
    s1 = s0;
else
    s1 = local_scalar(opts.end_straight, "end_straight");
end
if s0 < 0 || s1 < 0
    error("routing:route_auto:InvalidStraight", ...
        "Route straight distances must be >= 0.");
end

p0 = port_in.position_value();
p1 = port_out.position_value();
p_start = p0 + s0 * port_in.ori;
p_end = p1 - s1 * port_out.ori;
dx = p_end(1) - p_start(1);
dy = p_end(2) - p_start(2);

min_seg = max(5, 2 * local_scalar(opts.fillet, "fillet"));

candidate_pts = cell(0, 1);
candidate_pts{end + 1} = [p0; p_start; [p_end(1), p_start(2)]; p_end; p1]; %#ok<AGROW>
candidate_pts{end + 1} = [p0; p_start; [p_start(1), p_end(2)]; p_end; p1]; %#ok<AGROW>

candidate_pts{end + 1} = [ ...
    p0; p_start; ...
    [(p_start(1) + p_end(1)) / 2, p_start(2)]; ...
    [(p_start(1) + p_end(1)) / 2, p_end(2)]; ...
    p_end; p1]; %#ok<AGROW>
candidate_pts{end + 1} = [ ...
    p0; p_start; ...
    [p_start(1), (p_start(2) + p_end(2)) / 2]; ...
    [p_end(1), (p_start(2) + p_end(2)) / 2]; ...
    p_end; p1]; %#ok<AGROW>

detour_y = abs(dy) + min_seg;
detour_x = abs(dx) + min_seg;
for sgn = [-1, 1]
    yj = p_start(2) + sgn * detour_y;
    candidate_pts{end + 1} = [ ... %#ok<AGROW>
        p0; p_start; ...
        [p_start(1), yj]; ...
        [p_end(1), yj]; ...
        p_end; p1];

    xj = p_start(1) + sgn * detour_x;
    candidate_pts{end + 1} = [ ... %#ok<AGROW>
        p0; p_start; ...
        [xj, p_start(2)]; ...
        [xj, p_end(2)]; ...
        p_end; p1];
end

best_score = inf;
best_route = [];
for i = 1:numel(candidate_pts)
    pts = candidate_pts{i};
    try
        r = routing.Route(points=pts, fillet=opts.fillet);
    catch
        continue;
    end
    score = route_score(r, min_seg);
    if score < best_score
        best_score = score;
        best_route = r;
    end
end

if isempty(best_route)
    route = routing.Route.manhattan( ...
        port_in, port_out, ...
        start_straight=opts.start_straight, ...
        end_straight=opts.end_straight, ...
        bend="auto", ...
        fillet=opts.fillet);
else
    route = best_route;
end
end

function score = route_score(route, min_seg)
pts = route.points;
d = diff(pts, 1, 1);
seg = sqrt(sum(d.^2, 2));
len = sum(seg);
nturns = max(0, size(pts, 1) - 2);
short_deficit = max(0, min_seg - seg);
short_penalty = 1e3 * sum(short_deficit);
score = len + 20 * nturns + short_penalty;
end

function y = local_scalar(val, label)
if isa(val, 'types.Parameter')
    y = val.value;
else
    y = val;
end
if ~(isscalar(y) && isnumeric(y) && isfinite(y))
    error("routing:route_auto:InvalidScalar", ...
        "Option '%s' must resolve to a finite scalar.", char(string(label)));
end
y = double(y);
end
