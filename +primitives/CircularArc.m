classdef CircularArc < core.GeomFeature
    % Circular arc defined by center, radius and start/end angles.
    properties (Dependent)
        center
        radius
        start_angle
        end_angle
        type
        npoints
        width
    end
    methods
        function obj = CircularArc(ctx, args)
            % Create a circular arc primitive.
            arguments
                ctx core.GeometrySession = core.GeometrySession.empty
                args.center = [0, 0]
                args.radius = 1
                args.start_angle = 0
                args.end_angle = 90
                args.type {mustBeTextScalar} = "open"
                args.npoints = 128
                args.width = 1
                args.layer = "default"
            end
            if isempty(ctx)
                ctx = core.GeometrySession.require_current();
            end
            obj@core.GeomFeature(ctx, args.layer);
            obj.center = args.center;
            obj.radius = args.radius;
            obj.start_angle = args.start_angle;
            obj.end_angle = args.end_angle;
            obj.type = args.type;
            obj.npoints = args.npoints;
            obj.width = args.width;
            obj.finalize();
        end

        function set.center(obj, val)
            v = core.GeomFeature.coerce_vertices(val);
            if size(v.array, 1) ~= 1 || size(v.array, 2) ~= 2
                error("CircularArc center must be a single [x y] coordinate.");
            end
            obj.set_param("center", v);
        end

        function val = get.center(obj)
            val = obj.get_param("center", types.Vertices([0, 0]));
        end

        function set.radius(obj, val)
            p = core.GeomFeature.coerce_parameter(val, "", unit="nm");
            if ~(isscalar(p.value) && isfinite(p.value) && p.value > 0)
                error("CircularArc radius must be a finite real scalar > 0.");
            end
            obj.set_param("radius", p);
        end

        function val = get.radius(obj)
            val = obj.get_param("radius", types.Parameter(1, "", unit="nm"));
        end

        function set.start_angle(obj, val)
            p = core.GeomFeature.coerce_parameter(val, "", unit="deg");
            if ~(isscalar(p.value) && isfinite(p.value))
                error("CircularArc start_angle must be a finite real scalar in degrees.");
            end
            obj.set_param("start_angle", p);
        end

        function val = get.start_angle(obj)
            val = obj.get_param("start_angle", types.Parameter(0, "", unit="deg"));
        end

        function set.end_angle(obj, val)
            p = core.GeomFeature.coerce_parameter(val, "", unit="deg");
            if ~(isscalar(p.value) && isfinite(p.value))
                error("CircularArc end_angle must be a finite real scalar in degrees.");
            end
            obj.set_param("end_angle", p);
        end

        function val = get.end_angle(obj)
            val = obj.get_param("end_angle", types.Parameter(90, "", unit="deg"));
        end

        function set.type(obj, val)
            t = primitives.CircularArc.normalize_type(val);
            obj.set_param("type", t);
        end

        function val = get.type(obj)
            val = obj.get_param("type", "open");
        end

        function set.npoints(obj, val)
            p = core.GeomFeature.coerce_parameter(val, "", unit="");
            n = round(double(p.value));
            if ~(isscalar(n) && isfinite(n) && n >= 8)
                error("CircularArc npoints must be a scalar integer >= 8.");
            end
            obj.set_param("npoints", types.Parameter(n, "", unit=""));
        end

        function val = get.npoints(obj)
            val = obj.get_param("npoints", types.Parameter(128, "", unit=""));
        end

        function set.width(obj, val)
            p = core.GeomFeature.coerce_parameter(val, "", unit="");
            if ~(isscalar(p.value) && isfinite(p.value) && p.value > 0)
                error("CircularArc width must be a finite real scalar > 0.");
            end
            obj.set_param("width", p);
        end

        function val = get.width(obj)
            val = obj.get_param("width", types.Parameter(1, "", unit=""));
        end

        function y = center_value(obj)
            y = obj.center.value;
        end

        function y = radius_value(obj)
            y = obj.radius.value;
        end

        function y = start_angle_value(obj)
            y = obj.start_angle.value;
        end

        function y = end_angle_value(obj)
            y = obj.end_angle.value;
        end

        function y = width_value(obj)
            y = obj.width.value;
        end

        function y = sampled_points(obj)
            n = obj.npoints.value;
            theta = linspace(obj.start_angle_value(), obj.end_angle_value(), n).';
            c = obj.center_value();
            r = obj.radius_value();
            y = [c(1) + r*cosd(theta), c(2) + r*sind(theta)];
        end

        function [ctrl, degree, weights] = bezier_segments(obj)
            % Return rational quadratic Bezier control data for this arc.
            a0 = obj.start_angle_value();
            a1 = obj.end_angle_value();
            delta = a1 - a0;
            nseg = max(1, ceil(abs(delta) / 90));
            da = delta / nseg;
            angles = a0 + (0:nseg) * da;

            c = obj.center_value();
            r = obj.radius_value();
            ctrl = zeros(2*nseg + 1, 2);
            ctrl(1, :) = c + r * [cosd(angles(1)), sind(angles(1))];
            weights = zeros(1, 3*nseg);
            degree = 2 * ones(1, nseg);

            for k = 1:nseg
                ta = angles(k);
                tb = angles(k + 1);
                tm = 0.5 * (ta + tb);
                alpha = 0.5 * (tb - ta);
                wmid = cosd(alpha);
                if abs(wmid) < 1e-12
                    error("CircularArc sweep too large for quadratic Bezier decomposition.");
                end

                ctrl_mid = c + (r / wmid) * [cosd(tm), sind(tm)];
                ctrl_end = c + r * [cosd(tb), sind(tb)];
                ctrl(2*k, :) = ctrl_mid;
                ctrl(2*k + 1, :) = ctrl_end;
                weights(3*(k-1) + (1:3)) = [1, wmid, 1];
            end
        end
    end
    methods (Static, Access=private)
        function t = normalize_type(val)
            t = lower(string(val));
            if ~any(t == ["open", "closed", "solid"])
                error("CircularArc type must be 'open', 'closed', or 'solid'.");
            end
        end
    end
end




