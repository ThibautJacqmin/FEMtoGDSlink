classdef Thicken < femtogds.core.GeomFeature
    % Thicken operation on a curve-like feature.
    properties (Dependent)
        target
        offset
        totalthick
        upthick
        downthick
        ends
        convexcorner
        keep
        propagatesel
    end
    methods
        function obj = Thicken(varargin)
            [ctx, target, args] = femtogds.ops.Thicken.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@femtogds.core.GeomFeature(ctx, layer);
            obj.output = args.output;
            obj.add_input(target);
            obj.offset = args.offset;
            obj.totalthick = args.totalthick;
            obj.upthick = args.upthick;
            obj.downthick = args.downthick;
            obj.ends = args.ends;
            obj.convexcorner = args.convexcorner;
            obj.keep = args.keep;
            obj.propagatesel = args.propagatesel;
            obj.finalize();
        end

        function val = get.target(obj)
            val = obj.inputs{1};
        end

        function set.offset(obj, val)
            obj.set_param("offset", femtogds.ops.Thicken.normalize_offset(val));
        end

        function val = get.offset(obj)
            val = obj.get_param("offset", "symmetric");
        end

        function set.totalthick(obj, val)
            p = femtogds.core.GeomFeature.coerce_parameter(val, "totalthick");
            if ~(isscalar(p.value) && isfinite(p.value) && p.value > 0)
                error("Thicken totalthick must be a finite real scalar > 0.");
            end
            obj.set_param("totalthick", p);
        end

        function val = get.totalthick(obj)
            val = obj.get_param("totalthick", femtogds.types.Parameter(1, "", unit="nm"));
        end

        function set.upthick(obj, val)
            p = femtogds.core.GeomFeature.coerce_parameter(val, "upthick");
            if ~(isscalar(p.value) && isfinite(p.value) && p.value >= 0)
                error("Thicken upthick must be a finite real scalar >= 0.");
            end
            obj.set_param("upthick", p);
        end

        function val = get.upthick(obj)
            val = obj.get_param("upthick", femtogds.types.Parameter(0.5, "", unit="nm"));
        end

        function set.downthick(obj, val)
            p = femtogds.core.GeomFeature.coerce_parameter(val, "downthick");
            if ~(isscalar(p.value) && isfinite(p.value) && p.value >= 0)
                error("Thicken downthick must be a finite real scalar >= 0.");
            end
            obj.set_param("downthick", p);
        end

        function val = get.downthick(obj)
            val = obj.get_param("downthick", femtogds.types.Parameter(0.5, "", unit="nm"));
        end

        function set.ends(obj, val)
            obj.set_param("ends", femtogds.ops.Thicken.normalize_ends(val));
        end

        function val = get.ends(obj)
            val = obj.get_param("ends", "straight");
        end

        function set.convexcorner(obj, val)
            obj.set_param("convexcorner", femtogds.ops.Thicken.normalize_convexcorner(val));
        end

        function val = get.convexcorner(obj)
            val = obj.get_param("convexcorner", "fillet");
        end

        function set.keep(obj, val)
            obj.set_param("keep", logical(val));
        end

        function val = get.keep(obj)
            val = obj.get_param("keep", false);
        end

        function set.propagatesel(obj, val)
            obj.set_param("propagatesel", logical(val));
        end

        function val = get.propagatesel(obj)
            val = obj.get_param("propagatesel", false);
        end
    end
    methods (Static, Access=private)
        function [ctx, target, args] = parse_inputs(varargin)
            [ctx, target, nv] = femtogds.core.GeomFeature.parse_target_context("Thicken", varargin{:});
            args = femtogds.ops.Thicken.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.offset {mustBeTextScalar} = "symmetric"
                args.totalthick = 1
                args.upthick = 0.5
                args.downthick = 0.5
                args.ends {mustBeTextScalar} = "straight"
                args.convexcorner {mustBeTextScalar} = "fillet"
                args.keep logical = false
                args.propagatesel logical = false
                args.layer = []
                args.output logical = true
            end
            parsed = args;
        end

        function v = normalize_offset(val)
            v = lower(string(val));
            if ~any(v == ["symmetric", "asymmetric"])
                error("Thicken offset must be 'symmetric' or 'asymmetric'.");
            end
        end

        function v = normalize_ends(val)
            v = lower(string(val));
            if ~any(v == ["straight", "circular"])
                error("Thicken ends must be 'straight' or 'circular'.");
            end
        end

        function v = normalize_convexcorner(val)
            v = lower(string(val));
            if ~any(v == ["fillet", "tangent", "extend", "noconnection"])
                error("Thicken convexcorner must be 'fillet', 'tangent', 'extend', or 'noconnection'.");
            end
        end
    end
end


