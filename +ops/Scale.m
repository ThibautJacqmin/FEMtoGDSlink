classdef Scale < core.GeomFeature
    % Scale operation on a feature.
    properties (Dependent)
        target
        factor
        origin
    end
    methods
        function obj = Scale(varargin)
            [ctx, target, args] = ops.Scale.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@core.GeomFeature(ctx, layer);
            obj.add_input(target);
            obj.factor = args.factor;
            obj.origin = args.origin;
            obj.finalize();
        end

        function set.factor(obj, val)
            obj.set_param("factor", core.GeomFeature.coerce_parameter(val, "factor", unit=""));
        end

        function val = get.factor(obj)
            val = obj.get_param("factor");
        end

        function set.origin(obj, val)
            obj.set_param("origin", core.GeomFeature.coerce_vertices(val));
        end

        function val = get.origin(obj)
            val = obj.get_param("origin");
        end

        function val = get.target(obj)
            val = obj.inputs{1};
        end
    end
    methods (Static, Access=private)
        function [ctx, target, args] = parse_inputs(varargin)
            [ctx, target, nv] = core.GeomFeature.parse_target_context("Scale", varargin{:});
            args = ops.Scale.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.factor = 1
                args.origin = [0, 0]
                args.layer = []
            end
            parsed = args;
        end
    end
end

