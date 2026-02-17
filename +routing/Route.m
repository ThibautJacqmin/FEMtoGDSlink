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
            d = diff(obj.points, 1, 1);
            y = sum(sqrt(sum(d.^2, 2)));
        end

        function out = shifted(obj, offset)
            pts = obj.shifted_points(offset);
            out = routing.Route(points=pts, fillet=obj.fillet);
        end

        function pts = shifted_points(obj, offset)
            off = routing.Route.scalar_value(offset, "offset");
            if abs(off) < 1e-15
                pts = obj.points;
                return;
            end
            pts = routing.Route.offset_polyline(obj.points, off);
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
    end
end

