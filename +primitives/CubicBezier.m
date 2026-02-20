classdef CubicBezier < core.GeomFeature
    % Single cubic Bezier segment.
    properties (Dependent)
        p0
        p1
        p2
        p3
        type
        npoints
        width
    end
    methods
        function obj = CubicBezier(ctx, args)
            % Create a cubic Bezier from four control points.
            arguments
                ctx core.GeometryPipeline = core.GeometryPipeline.empty
                args.p0 = [0, 0]
                args.p1 = [1/3, 1]
                args.p2 = [2/3, -1]
                args.p3 = [1, 0]
                args.type {mustBeTextScalar} = "open"
                args.npoints = 128
                args.width = 1
                args.layer = "default"
            end
            if isempty(ctx)
                ctx = core.GeometryPipeline.require_current();
            end
            obj@core.GeomFeature(ctx, args.layer);
            obj.p0 = args.p0;
            obj.p1 = args.p1;
            obj.p2 = args.p2;
            obj.p3 = args.p3;
            obj.type = args.type;
            obj.npoints = args.npoints;
            obj.width = args.width;
            obj.finalize();
        end

        function set.p0(obj, val)
            obj.set_param("p0", primitives.CubicBezier.coerce_single_vertex(val, "p0"));
        end

        function val = get.p0(obj)
            val = obj.get_param("p0", types.Vertices([0, 0]));
        end

        function set.p1(obj, val)
            obj.set_param("p1", primitives.CubicBezier.coerce_single_vertex(val, "p1"));
        end

        function val = get.p1(obj)
            val = obj.get_param("p1", types.Vertices([1/3, 1]));
        end

        function set.p2(obj, val)
            obj.set_param("p2", primitives.CubicBezier.coerce_single_vertex(val, "p2"));
        end

        function val = get.p2(obj)
            val = obj.get_param("p2", types.Vertices([2/3, -1]));
        end

        function set.p3(obj, val)
            obj.set_param("p3", primitives.CubicBezier.coerce_single_vertex(val, "p3"));
        end

        function val = get.p3(obj)
            val = obj.get_param("p3", types.Vertices([1, 0]));
        end

        function set.type(obj, val)
            t = primitives.CubicBezier.normalize_type(val);
            obj.set_param("type", t);
        end

        function val = get.type(obj)
            val = obj.get_param("type", "open");
        end

        function set.npoints(obj, val)
            p = core.GeomFeature.coerce_parameter(val, "", unit="");
            n = round(double(p.value));
            if ~(isscalar(n) && isfinite(n) && n >= 8)
                error("CubicBezier npoints must be a scalar integer >= 8.");
            end
            obj.set_param("npoints", types.Parameter(n, "", unit=""));
        end

        function val = get.npoints(obj)
            val = obj.get_param("npoints", types.Parameter(128, "", unit=""));
        end

        function set.width(obj, val)
            p = core.GeomFeature.coerce_parameter(val, "", unit="");
            if ~(isscalar(p.value) && isfinite(p.value) && p.value > 0)
                error("CubicBezier width must be a finite real scalar > 0.");
            end
            obj.set_param("width", p);
        end

        function val = get.width(obj)
            val = obj.get_param("width", types.Parameter(1, "", unit=""));
        end

        function y = control_points_value(obj)
            y = [obj.p0.value; obj.p1.value; obj.p2.value; obj.p3.value];
        end

        function y = sampled_points(obj)
            ctrl = obj.control_points_value();
            n = obj.npoints.value;
            t = linspace(0, 1, n).';
            omt = 1 - t;
            y = (omt.^3) .* ctrl(1, :) + ...
                (3 .* omt.^2 .* t) .* ctrl(2, :) + ...
                (3 .* omt .* t.^2) .* ctrl(3, :) + ...
                (t.^3) .* ctrl(4, :);
        end

        function y = width_value(obj)
            y = obj.width.value;
        end
    end
    methods (Static, Access=private)
        function v = coerce_single_vertex(val, name)
            v = core.GeomFeature.coerce_vertices(val);
            if size(v.array, 1) ~= 1 || size(v.array, 2) ~= 2
                error("CubicBezier %s must be a single [x y] coordinate.", char(name));
            end
        end

        function t = normalize_type(val)
            t = lower(string(val));
            if ~any(t == ["open", "closed", "solid"])
                error("CubicBezier type must be 'open', 'closed', or 'solid'.");
            end
        end
    end
end




