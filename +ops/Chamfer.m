classdef Chamfer < core.GeomFeature
    % Chamfer operation on 2D corners.
    properties (Dependent)
        target
        dist
        points
    end
    methods
        function obj = Chamfer(varargin)
            [ctx, target, args] = ops.Chamfer.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@core.GeomFeature(ctx, layer);
            obj.add_input(target);
            obj.dist = args.dist;
            obj.points = args.points;
            obj.finalize();
        end

        function set.dist(obj, val)
            p = core.GeomFeature.coerce_parameter(val, "dist");
            if ~(isscalar(p.value) && isfinite(p.value) && p.value >= 0)
                error("Chamfer dist must be a finite real scalar >= 0.");
            end
            obj.set_param("dist", p);
        end

        function val = get.dist(obj)
            val = obj.get_param("dist", types.Parameter(0, "", unit="nm"));
        end

        function set.points(obj, val)
            obj.set_param("points", val);
        end

        function val = get.points(obj)
            val = obj.get_param("points", []);
        end

        function val = get.target(obj)
            val = obj.inputs{1};
        end
    end
    methods (Static, Access=private)
        function [ctx, target, args] = parse_inputs(varargin)
            [ctx, target, nv] = core.GeomFeature.parse_target_context("Chamfer", varargin{:});
            args = ops.Chamfer.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.dist = 0
                args.points = []
                args.layer = []
            end
            parsed = args;
        end
    end
end


