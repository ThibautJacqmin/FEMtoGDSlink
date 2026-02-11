classdef Fillet < GeomFeature
    % Fillet operation on a feature.
    properties (Dependent)
        target
        radius
        npoints
        points
    end
    methods
        function obj = Fillet(varargin)
            [ctx, target, args] = Fillet.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@GeomFeature(ctx, layer);
            obj.output = args.output;
            obj.add_input(target);
            obj.radius = args.radius;
            obj.npoints = args.npoints;
            obj.points = args.points;
            obj.finalize();
        end

        function set.radius(obj, val)
            obj.set_param("radius", GeomFeature.coerce_parameter(val, "radius"));
        end

        function val = get.radius(obj)
            val = obj.get_param("radius");
        end

        function set.npoints(obj, val)
            obj.set_param("npoints", GeomFeature.coerce_parameter(val, "npoints", unit=""));
        end

        function val = get.npoints(obj)
            val = obj.get_param("npoints");
        end

        function set.points(obj, val)
            obj.set_param("points", val);
        end

        function val = get.points(obj)
            val = obj.get_param("points");
        end

        function val = get.target(obj)
            val = obj.inputs{1};
        end
    end
    methods (Static, Access=private)
        function [ctx, target, args] = parse_inputs(varargin)
            [ctx, target, nv] = GeomFeature.parse_target_context("Fillet", varargin{:});
            args = Fillet.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.radius = 1
                args.npoints = 8
                args.points = []
                args.layer = []
                args.output logical = true
            end
            parsed = args;
        end
    end
end
