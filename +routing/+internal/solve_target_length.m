function result = solve_target_length(route_or_length, target_spec, meander_seed)
% Solve target-length routing by tuning serpentine meander parameters.
if nargin < 3 || isempty(meander_seed)
    meander_seed = routing.MeanderSpec.disabled();
end

if isa(route_or_length, 'routing.Route')
    result = solve_route_target(route_or_length, target_spec, meander_seed);
else
    current_len_nm = double(route_or_length);
    result = struct( ...
        "enabled", target_spec.enabled, ...
        "current_len_nm", current_len_nm, ...
        "target_len_nm", target_spec.length_nm, ...
        "tolerance_nm", target_spec.tolerance_nm, ...
        "delta_nm", target_spec.length_nm - current_len_nm);
end
end

function result = solve_route_target(base_route, target_spec, meander_seed)
base_len = base_route.path_length();
target_len = double(target_spec.length_nm);
tol = double(target_spec.tolerance_nm);
if ~(isfinite(tol) && tol >= 0)
    tol = 1.0;
end

best_route = base_route;
best_len = base_len;
best_err = abs(base_len - target_len);
best_meander = routing.MeanderSpec.disabled();
applied = false;

if ~target_spec.enabled || ~(isfinite(target_len) && target_len > 0)
    result = package_result( ...
        false, base_route, base_len, target_len, tol, ...
        best_route, best_len, best_meander, applied);
    return;
end

if target_len <= base_len + tol
    result = package_result( ...
        true, base_route, base_len, target_len, tol, ...
        best_route, best_len, best_meander, applied);
    return;
end

seed = normalize_seed(base_route, meander_seed);
seg_len = sqrt(sum(diff(base_route.points, 1, 1).^2, 2));
idx = seed.segment_indices;
idx = idx(idx >= 1 & idx <= numel(seg_len));
if isempty(idx)
    [~, kmax] = max(seg_len);
    idx = kmax;
end
sel_len = seg_len(idx);
max_seg = max(sel_len);

amp_seed = seed.amplitude_nm;
amp_hi = max(amp_seed, 0.45 * max_seg);
amp_lo = max(5, min(amp_seed, 0.10 * max_seg));
if ~(isfinite(amp_hi) && amp_hi > amp_lo)
    amp_hi = max(amp_lo + 5, amp_seed);
end
amp_grid = unique([linspace(amp_lo, amp_hi, 22), amp_seed, 1.5 * amp_seed, 2 * amp_seed]);
amp_grid = amp_grid(isfinite(amp_grid) & amp_grid > 0);

if isfinite(seed.pitch_nm) && seed.pitch_nm > 0
    max_count = floor(min(sel_len) / seed.pitch_nm);
    max_count = min(80, max(1, max_count));
else
    max_count = 80;
end
count_seed = max(1, round(seed.count));
count_grid = unique([1:min(max_count, 24), max(1, count_seed - 8):min(max_count, count_seed + 24), max_count]);
count_grid = count_grid(count_grid >= 1 & count_grid <= max_count);
if isempty(count_grid)
    count_grid = 1;
end

done = false;
for c = count_grid
    for a = amp_grid
        cand_meander = routing.MeanderSpec( ...
            enabled=true, ...
            segment_indices=seed.segment_indices, ...
            amplitude_nm=a, ...
            pitch_nm=seed.pitch_nm, ...
            count=c);
        cand_route = routing.internal.apply_meander_serpentine(base_route, cand_meander);
        cand_len = cand_route.path_length();
        cand_err = abs(cand_len - target_len);
        if cand_err < best_err - 1e-9 || ...
                (abs(cand_err - best_err) <= 1e-9 && cand_len < best_len)
            best_err = cand_err;
            best_len = cand_len;
            best_route = cand_route;
            best_meander = cand_meander;
            applied = true;
        end
        if cand_err <= tol
            done = true;
            break;
        end
    end
    if done
        break;
    end
end

result = package_result( ...
    true, base_route, base_len, target_len, tol, ...
    best_route, best_len, best_meander, applied);
end

function seed = normalize_seed(route, meander_seed)
seed = meander_seed;
seed.enabled = true;

seg_len = sqrt(sum(diff(route.points, 1, 1).^2, 2));
if isempty(seed.segment_indices) || all(~isfinite(seed.segment_indices))
    [~, kmax] = max(seg_len);
    seed.segment_indices = kmax;
else
    idx = unique(max(1, round(seed.segment_indices(:).')));
    idx = idx(idx <= numel(seg_len));
    if isempty(idx)
        [~, kmax] = max(seg_len);
        idx = kmax;
    end
    seed.segment_indices = idx;
end

if ~(isscalar(seed.count) && isfinite(seed.count) && seed.count >= 1)
    seed.count = 4;
end
seed.count = max(1, round(seed.count));

if ~(isscalar(seed.amplitude_nm) && isfinite(seed.amplitude_nm) && seed.amplitude_nm > 0)
    idx = seed.segment_indices;
    idx = idx(idx >= 1 & idx <= numel(seg_len));
    if isempty(idx)
        idx = 1;
    end
    ref_len = median(seg_len(idx));
    if ~(isfinite(ref_len) && ref_len > 0)
        ref_len = max(seg_len);
    end
    if ~(isfinite(ref_len) && ref_len > 0)
        ref_len = 200;
    end
    seed.amplitude_nm = max(40, 0.18 * ref_len);
end

if ~(isscalar(seed.pitch_nm) && isfinite(seed.pitch_nm) && seed.pitch_nm > 0)
    seed.pitch_nm = NaN;
end
end

function result = package_result(enabled, base_route, base_len, target_len, tol, best_route, best_len, best_meander, applied)
err = abs(best_len - target_len);
result = struct( ...
    "enabled", logical(enabled), ...
    "base_len_nm", base_len, ...
    "current_len_nm", best_len, ...
    "target_len_nm", target_len, ...
    "tolerance_nm", tol, ...
    "delta_nm", target_len - best_len, ...
    "achieved", err <= tol, ...
    "route", best_route, ...
    "meander", best_meander, ...
    "applied", logical(applied), ...
    "base_route", base_route);
end
