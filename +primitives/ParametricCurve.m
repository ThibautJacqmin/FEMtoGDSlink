classdef ParametricCurve < core.GeomFeature
    % Parametric 2D curve defined by x(parname), y(parname).
    properties (Dependent)
        coord
        parname
        parmin
        parmax
        npoints
        type
        width
        sample_points
    end
    methods
        function obj = ParametricCurve(ctx, args)
            % Create a parametric curve from coordinate expressions.
            arguments
                ctx core.GeometryPipeline = core.GeometryPipeline.empty
                args.coord = {"cos(s)", "sin(s)"}
                args.parname {mustBeTextScalar} = "s"
                args.parmin = 0
                args.parmax = 1
                args.npoints = 128
                args.type {mustBeTextScalar} = "open"
                args.width = 1
                args.sample_points = []
                args.layer = "default"
            end
            if isempty(ctx)
                ctx = core.GeometryPipeline.require_current();
            end
            obj@core.GeomFeature(ctx, args.layer);
            obj.coord = args.coord;
            obj.parname = args.parname;
            obj.parmin = args.parmin;
            obj.parmax = args.parmax;
            obj.npoints = args.npoints;
            obj.type = args.type;
            obj.width = args.width;
            obj.sample_points = args.sample_points;
            obj.finalize();
        end

        function set.coord(obj, val)
            c = string(val);
            c = c(:).';
            if numel(c) ~= 2
                error("ParametricCurve coord must contain exactly two expressions: {x(s), y(s)}.");
            end
            if any(strlength(c) == 0)
                error("ParametricCurve coord expressions must be non-empty.");
            end
            obj.set_param("coord", c);
        end

        function val = get.coord(obj)
            val = obj.get_param("coord", ["cos(s)", "sin(s)"]);
        end

        function set.parname(obj, val)
            s = string(val);
            if strlength(s) == 0
                error("ParametricCurve parname must be non-empty.");
            end
            obj.set_param("parname", s);
        end

        function val = get.parname(obj)
            val = obj.get_param("parname", "s");
        end

        function set.parmin(obj, val)
            p = core.GeomFeature.coerce_parameter(val, "", unit="");
            if ~(isscalar(p.value) && isfinite(p.value))
                error("ParametricCurve parmin must be a finite real scalar.");
            end
            obj.set_param("parmin", p);
        end

        function val = get.parmin(obj)
            val = obj.get_param("parmin", types.Parameter(0, "", unit=""));
        end

        function set.parmax(obj, val)
            p = core.GeomFeature.coerce_parameter(val, "", unit="");
            if ~(isscalar(p.value) && isfinite(p.value))
                error("ParametricCurve parmax must be a finite real scalar.");
            end
            obj.set_param("parmax", p);
        end

        function val = get.parmax(obj)
            val = obj.get_param("parmax", types.Parameter(1, "", unit=""));
        end

        function set.npoints(obj, val)
            p = core.GeomFeature.coerce_parameter(val, "", unit="");
            n = round(double(p.value));
            if ~(isscalar(n) && isfinite(n) && n >= 8)
                error("ParametricCurve npoints must be a scalar integer >= 8.");
            end
            obj.set_param("npoints", types.Parameter(n, "", unit=""));
        end

        function val = get.npoints(obj)
            val = obj.get_param("npoints", types.Parameter(128, "", unit=""));
        end

        function set.type(obj, val)
            t = primitives.ParametricCurve.normalize_type(val);
            obj.set_param("type", t);
        end

        function val = get.type(obj)
            val = obj.get_param("type", "open");
        end

        function set.width(obj, val)
            p = core.GeomFeature.coerce_parameter(val, "", unit="");
            if ~(isscalar(p.value) && isfinite(p.value) && p.value > 0)
                error("ParametricCurve width must be a finite real scalar > 0.");
            end
            obj.set_param("width", p);
        end

        function val = get.width(obj)
            val = obj.get_param("width", types.Parameter(1, "", unit=""));
        end

        function set.sample_points(obj, val)
            if isempty(val)
                obj.set_param("sample_points", zeros(0, 2));
                return;
            end
            pts = double(val);
            if size(pts, 2) ~= 2 || size(pts, 1) < 2
                error("ParametricCurve sample_points must be an Nx2 array with N >= 2.");
            end
            obj.set_param("sample_points", pts);
        end

        function val = get.sample_points(obj)
            val = obj.get_param("sample_points", zeros(0, 2));
        end

        function y = parmin_value(obj)
            y = obj.parmin.value;
        end

        function y = parmax_value(obj)
            y = obj.parmax.value;
        end

        function y = width_value(obj)
            y = obj.width.value;
        end

        function c = coord_strings(obj)
            c = string(obj.coord);
            c = c(:).';
        end

        function y = sampled_points(obj)
            pts = obj.sample_points;
            if ~isempty(pts)
                y = pts;
                return;
            end

            n = obj.npoints.value;
            t = linspace(obj.parmin_value(), obj.parmax_value(), n).';
            var = char(obj.parname);
            c = obj.coord_strings();
            fx = str2func("@(" + var + ") " + c(1));
            fy = str2func("@(" + var + ") " + c(2));

            try
                x = fx(t);
                yv = fy(t);
            catch ex
                error("ParametricCurve:EvalFailed", ...
                    "Failed to evaluate coord expressions for GDS sampling: %s. " + ...
                    "Provide sample_points for non-MATLAB-compatible expressions.", ...
                    ex.message);
            end

            x = double(x(:));
            yv = double(yv(:));
            if numel(x) ~= numel(yv) || numel(x) < 2
                error("ParametricCurve evaluated coordinates must produce matching vectors with at least two points.");
            end
            y = [x, yv];
        end
    end
    methods (Static, Access=private)
        function t = normalize_type(val)
            t = lower(string(val));
            if ~any(t == ["open", "closed", "solid"])
                error("ParametricCurve type must be 'open', 'closed', or 'solid'.");
            end
        end
    end
end



