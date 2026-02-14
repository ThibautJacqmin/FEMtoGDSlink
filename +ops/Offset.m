classdef Offset < core.GeomFeature
    % Offset operation on curve or solid geometry.
    properties (Dependent)
        target
        distance
        reverse
        convexcorner
        trim
        keep
    end
    methods
        function obj = Offset(varargin)
            [ctx, target, args] = ops.Offset.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@core.GeomFeature(ctx, layer);
            obj.add_input(target);
            obj.distance = args.distance;
            obj.reverse = args.reverse;
            obj.convexcorner = args.convexcorner;
            obj.trim = args.trim;
            obj.keep = args.keep;
            obj.finalize();
        end

        function val = get.target(obj)
            val = obj.inputs{1};
        end

        function set.distance(obj, val)
            p = core.GeomFeature.coerce_parameter(val, "distance");
            if ~(isscalar(p.value) && isfinite(p.value) && p.value >= 0)
                error("Offset distance must be a finite real scalar >= 0.");
            end
            obj.set_param("distance", p);
        end

        function val = get.distance(obj)
            val = obj.get_param("distance", types.Parameter(0, "", unit="nm"));
        end

        function set.reverse(obj, val)
            obj.set_param("reverse", logical(val));
        end

        function val = get.reverse(obj)
            val = obj.get_param("reverse", false);
        end

        function set.convexcorner(obj, val)
            c = ops.Offset.normalize_convexcorner(val);
            obj.set_param("convexcorner", c);
        end

        function val = get.convexcorner(obj)
            val = obj.get_param("convexcorner", "tangent");
        end

        function set.trim(obj, val)
            obj.set_param("trim", logical(val));
        end

        function val = get.trim(obj)
            val = obj.get_param("trim", true);
        end

        function set.keep(obj, val)
            obj.set_param("keep", logical(val));
        end

        function val = get.keep(obj)
            val = obj.get_param("keep", false);
        end
    end
    methods (Static, Access=private)
        function [ctx, target, args] = parse_inputs(varargin)
            [ctx, target, nv] = core.GeomFeature.parse_target_context("Offset", varargin{:});
            args = ops.Offset.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.distance = 0
                args.reverse logical = false
                args.convexcorner {mustBeTextScalar} = "tangent"
                args.trim logical = true
                args.keep logical = false
                args.layer = []
            end
            parsed = args;
        end

        function c = normalize_convexcorner(val)
            c = lower(string(val));
            if ~any(c == ["tangent", "fillet", "extend", "noconnection"])
                error("Offset convexcorner must be 'tangent', 'fillet', 'extend', or 'noconnection'.");
            end
        end
    end
end


