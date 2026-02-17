function route_out = apply_meander_serpentine(route_in, spec)
% Insert simple serpentine meanders on selected centerline segments.
pts = route_in.points;
if size(pts, 1) < 2
    route_out = route_in;
    return;
end

seg_len = sqrt(sum(diff(pts, 1, 1).^2, 2));
sel = spec.segment_indices;
if isempty(sel) || all(~isfinite(sel))
    [~, kmax] = max(seg_len);
    sel = kmax;
else
    sel = unique(max(1, round(sel(:).')));
    sel = sel(sel <= size(pts, 1) - 1);
    if isempty(sel)
        [~, kmax] = max(seg_len);
        sel = kmax;
    end
end

amp = spec.amplitude_nm;
if ~(isscalar(amp) && isfinite(amp) && amp > 0)
    amp = max(40, 0.20 * median(seg_len));
end

count = spec.count;
if ~(isscalar(count) && isfinite(count) && count >= 1)
    count = 4;
end
count = max(1, round(count));

pitch = spec.pitch_nm;
if ~(isscalar(pitch) && isfinite(pitch) && pitch > 0)
    pitch = NaN;
end

for idx = sort(sel, 'descend')
    if idx < 1 || idx >= size(pts, 1)
        continue;
    end
    s = pts(idx, :);
    e = pts(idx + 1, :);
    v = e - s;
    L = norm(v);
    if L <= 1e-9
        continue;
    end
    u = v / L;
    n = [-u(2), u(1)];

    k = count;
    if isfinite(pitch)
        step = 0.5 * pitch;
        kmax = floor(L / (2 * step));
        if kmax < 1
            continue;
        end
        k = min(k, kmax);
        used = 2 * k * step;
        x0 = 0.5 * (L - used);
    else
        step = L / (2 * k + 1);
        x0 = 0;
    end

    amp_use = min(amp, 0.45 * L);
    if amp_use <= 1e-9
        continue;
    end

    loc = zeros(0, 2);
    loc(end + 1, :) = [0, 0]; %#ok<AGROW>
    if x0 > 1e-9
        loc(end + 1, :) = [x0, 0]; %#ok<AGROW>
    end
    sign0 = (-1)^(idx + 1);
    for j = 1:k
        x_peak = x0 + (2 * j - 1) * step;
        y_peak = sign0 * ((-1)^(j - 1)) * amp_use;
        loc(end + 1, :) = [x_peak, y_peak]; %#ok<AGROW>

        x_back = x0 + 2 * j * step;
        if x_back < L - 1e-9
            loc(end + 1, :) = [x_back, 0]; %#ok<AGROW>
        end
    end
    loc(end + 1, :) = [L, 0]; %#ok<AGROW>

    new_seg = [ ...
        s(1) + loc(:, 1) .* u(1) + loc(:, 2) .* n(1), ...
        s(2) + loc(:, 1) .* u(2) + loc(:, 2) .* n(2)];

    pts = [pts(1:(idx - 1), :); new_seg; pts((idx + 2):end, :)];
end

route_out = routing.Route(points=pts, fillet=route_in.fillet);
end
