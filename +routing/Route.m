classdef Route
    % Polyline route with optional fillet metadata.
    properties
        points double
        fillet double
    end
    methods
        function obj = Route(args)
            arguments
                args.points double
                args.fillet = 0
            end
            pts = double(args.points);
            if size(pts, 2) ~= 2 || size(pts, 1) < 2
                error("Route points must be an Nx2 array with N >= 2.");
            end
            pts = routing.Route.clean_points(pts);
            if size(pts, 1) < 2
                error("Route points collapse to fewer than 2 points.");
            end

            f = routing.Route.scalar_value(args.fillet, "fillet");
            if f < 0
                error("Route fillet must be >= 0.");
            end

            obj.points = pts;
            obj.fillet = f;
        end

        function y = path_length(obj)
            pts = obj.shifted_points(0);
            d = diff(pts, 1, 1);
            y = sum(sqrt(sum(d.^2, 2)));
        end

        function out = shifted(obj, offset)
            off = routing.Route.scalar_value(offset, "offset");
            if abs(off) < 1e-15
                pts = obj.points;
            else
                pts = routing.Route.offset_polyline(obj.points, off);
            end
            out = routing.Route(points=pts, fillet=obj.fillet);
        end

        function pts = shifted_points(obj, offset)
            off = routing.Route.scalar_value(offset, "offset");
            if abs(off) < 1e-15
                pts = obj.points;
            else
                pts = routing.Route.offset_polyline(obj.points, off);
            end

            if obj.fillet > 1e-15
                pts = routing.Route.apply_circular_fillets(pts, obj.fillet);
            end
        end
    end
    methods (Static)
        function obj = manhattan(port_in, port_out, args)
            arguments
                port_in routing.PortRef
                port_out routing.PortRef
                args.start_straight = 0
                args.end_straight = []
                args.bend {mustBeTextScalar} = "auto"
                args.fillet = 0
            end

            s0 = routing.Route.scalar_value(args.start_straight, "start_straight");
            if isempty(args.end_straight)
                s1 = s0;
            else
                s1 = routing.Route.scalar_value(args.end_straight, "end_straight");
            end
            if s0 < 0 || s1 < 0
                error("Route straight distances must be >= 0.");
            end

            p0 = port_in.position_value();
            p1 = port_out.position_value();
            p_start = p0 + s0 * port_in.ori;
            p_end = p1 - s1 * port_out.ori;

            bend = lower(string(args.bend));
            if abs(p_start(1) - p_end(1)) < 1e-12 || abs(p_start(2) - p_end(2)) < 1e-12
                mids = zeros(0, 2);
            else
                if bend == "x_first"
                    mids = [p_end(1), p_start(2)];
                elseif bend == "y_first"
                    mids = [p_start(1), p_end(2)];
                elseif bend == "auto"
                    dx = abs(p_end(1) - p_start(1));
                    dy = abs(p_end(2) - p_start(2));
                    if dx >= dy
                        mids = [p_end(1), p_start(2)];
                    else
                        mids = [p_start(1), p_end(2)];
                    end
                else
                    error("Route bend must be 'auto', 'x_first', or 'y_first'.");
                end
            end

            pts = [p0; p_start; mids; p_end; p1];
            pts = routing.Route.clean_points(pts);
            obj = routing.Route(points=pts, fillet=args.fillet);
        end
    end
    methods (Static, Access=private)
        function y = scalar_value(val, label)
            if isa(val, 'types.Parameter')
                y = val.value;
            else
                y = val;
            end
            if ~(isscalar(y) && isnumeric(y) && isfinite(y))
                error("Route %s must resolve to a finite scalar.", char(string(label)));
            end
            y = double(y);
        end

        function pts = clean_points(pts)
            if isempty(pts)
                return;
            end
            keep = true(size(pts, 1), 1);
            for i = 2:size(pts, 1)
                if norm(pts(i, :) - pts(i - 1, :)) <= 1e-12
                    keep(i) = false;
                end
            end
            pts = pts(keep, :);

            i = 2;
            while i <= size(pts, 1) - 1
                a = pts(i, :) - pts(i - 1, :);
                b = pts(i + 1, :) - pts(i, :);
                if norm(a) <= 1e-12 || norm(b) <= 1e-12
                    pts(i, :) = [];
                    continue;
                end
                cross_z = a(1) * b(2) - a(2) * b(1);
                if abs(cross_z) <= 1e-12
                    pts(i, :) = [];
                else
                    i = i + 1;
                end
            end
        end

        function pts = apply_circular_fillets(pts, radius)
            % Replace sharp interior corners by circular arcs of given radius.
            p = double(pts);
            n = size(p, 1);
            if n < 3 || radius <= 1e-15
                pts = routing.Route.clean_points(p);
                return;
            end

            tol = 1e-12;
            d = zeros(n, 1);
            phi = zeros(n, 1);
            turn = zeros(n, 1);

            for i = 2:(n-1)
                a = p(i, :) - p(i-1, :);
                b = p(i+1, :) - p(i, :);
                la = norm(a);
                lb = norm(b);
                if la <= tol || lb <= tol
                    continue;
                end

                u = a / la;
                v = b / lb;
                cross_z = u(1) * v(2) - u(2) * v(1);
                if abs(cross_z) <= tol
                    continue;
                end

                dot_uv = max(-1, min(1, dot(u, v)));
                ang = acos(dot_uv);
                if ang <= 1e-9 || abs(pi - ang) <= 1e-9
                    continue;
                end

                tan_half = tan(0.5 * ang);
                if abs(tan_half) <= tol
                    continue;
                end

                d(i) = radius * tan_half;
                phi(i) = ang;
                turn(i) = sign(cross_z);
            end

            if ~any(d > tol)
                pts = routing.Route.clean_points(p);
                return;
            end

            seg_len = sqrt(sum(diff(p, 1, 1).^2, 2));
            cap = 0.999;
            for pass = 1:4
                changed = false;
                for s = 1:(n-1)
                    total_trim = d(s) + d(s+1);
                    max_trim = cap * seg_len(s);
                    if total_trim > max_trim && total_trim > tol
                        scale = max_trim / total_trim;
                        if d(s) > 0
                            d(s) = d(s) * scale;
                        end
                        if d(s+1) > 0
                            d(s+1) = d(s+1) * scale;
                        end
                        changed = true;
                    end
                end
                if ~changed
                    break;
                end
            end

            out = zeros(0, 2);
            out = routing.Route.append_unique_point(out, p(1, :), tol);

            for i = 2:(n-1)
                if d(i) <= tol || phi(i) <= 1e-9 || turn(i) == 0
                    out = routing.Route.append_unique_point(out, p(i, :), tol);
                    continue;
                end

                a = p(i, :) - p(i-1, :);
                b = p(i+1, :) - p(i, :);
                la = norm(a);
                lb = norm(b);
                if la <= tol || lb <= tol
                    out = routing.Route.append_unique_point(out, p(i, :), tol);
                    continue;
                end
                u = a / la;
                v = b / lb;

                trim = min([d(i), 0.499 * la, 0.499 * lb]);
                if trim <= tol
                    out = routing.Route.append_unique_point(out, p(i, :), tol);
                    continue;
                end

                tan_half = tan(0.5 * phi(i));
                if abs(tan_half) <= tol
                    out = routing.Route.append_unique_point(out, p(i, :), tol);
                    continue;
                end
                r_use = trim / tan_half;

                t1 = p(i, :) - u * trim;
                t2 = p(i, :) + v * trim;
                n_u = [-u(2), u(1)];
                center = t1 + turn(i) * n_u * r_use;

                arc = routing.Route.sample_corner_arc(center, t1, t2, turn(i), r_use);
                out = routing.Route.append_unique_point(out, t1, tol);
                for k = 2:size(arc, 1)
                    out = routing.Route.append_unique_point(out, arc(k, :), tol);
                end
            end

            out = routing.Route.append_unique_point(out, p(end, :), tol);
            pts = routing.Route.clean_points(out);
        end

        function shifted = offset_polyline(pts, offset)
            if size(pts, 1) < 2
                error("Route offset requires at least 2 points.");
            end

            p = double(pts);
            shifted = zeros(size(p));
            n = size(p, 1);
            for i = 1:n
                if i == 1
                    t = p(2, :) - p(1, :);
                elseif i == n
                    t = p(n, :) - p(n - 1, :);
                else
                    t_prev = routing.Route.normalize_vector(p(i, :) - p(i - 1, :));
                    t_next = routing.Route.normalize_vector(p(i + 1, :) - p(i, :));
                    t = t_prev + t_next;
                    if norm(t) < 1e-12
                        t = t_next;
                    end
                end

                if norm(t) < 1e-12
                    t = [1, 0];
                end
                t = t / norm(t);
                nrm = [-t(2), t(1)];
                shifted(i, :) = p(i, :) + offset * nrm;
            end
            shifted = routing.Route.clean_points(shifted);
        end

        function v = normalize_vector(v)
            n = norm(v);
            if n > 0
                v = v / n;
            end
        end

        function arc = sample_corner_arc(center, t1, t2, turn_sign, radius)
            % Sample arc from tangent point t1 to t2 with oriented sweep.
            a1 = atan2(t1(2) - center(2), t1(1) - center(1));
            a2 = atan2(t2(2) - center(2), t2(1) - center(1));
            if turn_sign > 0
                while a2 <= a1
                    a2 = a2 + 2*pi;
                end
            else
                while a2 >= a1
                    a2 = a2 - 2*pi;
                end
            end

            sweep = abs(a2 - a1);
            npts = max(3, ceil(sweep / (pi / 18)) + 1); % about 10-degree steps
            ang = linspace(a1, a2, npts).';
            arc = [center(1) + radius .* cos(ang), center(2) + radius .* sin(ang)];
        end

        function pts = append_unique_point(pts, p, tol)
            % Append point when it is not a duplicate of the last vertex.
            if isempty(pts)
                pts = reshape(p, 1, 2);
                return;
            end
            if norm(pts(end, :) - p) > tol
                pts(end+1, :) = p; %#ok<AGROW>
            end
        end
    end
end
