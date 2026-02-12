classdef InterpolationCurve < femtogds.core.GeomFeature
    % Curve through provided points, with open/closed/solid modes.
    properties (Dependent)
        points
        type
        width
    end
    methods
        function obj = InterpolationCurve(ctx, args)
            % Create interpolation curve from a sequence of points.
            arguments
                ctx femtogds.core.GeometrySession = femtogds.core.GeometrySession.empty
                args.points = [0, 0; 1, 0; 1, 1]
                args.type {mustBeTextScalar} = "open"
                args.width = 1
                args.layer = "default"
                args.output logical = true
            end
            if isempty(ctx)
                ctx = femtogds.core.GeometrySession.require_current();
            end
            obj@femtogds.core.GeomFeature(ctx, args.layer);
            obj.output = args.output;
            obj.points = args.points;
            obj.type = args.type;
            obj.width = args.width;
            obj.finalize();
        end

        function set.points(obj, val)
            v = femtogds.core.GeomFeature.coerce_vertices(val);
            if size(v.array, 2) ~= 2 || v.nvertices < 2
                error("InterpolationCurve points must be an Nx2 array with N >= 2.");
            end
            obj.set_param("points", v);
        end

        function val = get.points(obj)
            val = obj.get_param("points", femtogds.types.Vertices([0, 0; 1, 0]));
        end

        function set.type(obj, val)
            t = InterpolationCurve.normalize_type(val);
            obj.set_param("type", t);
        end

        function val = get.type(obj)
            val = obj.get_param("type", "open");
        end

        function set.width(obj, val)
            p = femtogds.core.GeomFeature.coerce_parameter(val, "", unit="");
            if ~(isscalar(p.value) && isfinite(p.value) && p.value > 0)
                error("InterpolationCurve width must be a finite real scalar > 0.");
            end
            obj.set_param("width", p);
        end

        function val = get.width(obj)
            val = obj.get_param("width", femtogds.types.Parameter(1, "", unit=""));
        end

        function y = points_value(obj)
            v = obj.points;
            if isa(v, 'femtogds.types.Vertices')
                y = v.value;
            else
                y = v;
            end
        end

        function y = width_value(obj)
            p = obj.width;
            if isa(p, 'femtogds.types.Parameter')
                y = p.value;
            else
                y = p;
            end
        end
    end
    methods (Static, Access=private)
        function t = normalize_type(val)
            t = lower(string(val));
            if ~any(t == ["open", "closed", "solid"])
                error("InterpolationCurve type must be 'open', 'closed', or 'solid'.");
            end
        end
    end
end




