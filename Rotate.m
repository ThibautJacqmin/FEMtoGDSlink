classdef Rotate < GeomFeature
    % Rotate operation on a feature.
    properties (Dependent)
        target
        angle
        origin
    end
    methods
        function obj = Rotate(varargin)
            [ctx, target, args] = Rotate.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@GeomFeature(ctx, layer);
            obj.output = args.output;
            obj.add_input(target);
            obj.angle = args.angle;
            obj.origin = args.origin;
            obj.finalize();
        end

        function set.angle(obj, val)
            obj.set_param("angle", GeomFeature.coerce_parameter(val, "angle", unit=""));
        end

        function val = get.angle(obj)
            val = obj.get_param("angle");
        end

        function set.origin(obj, val)
            obj.set_param("origin", GeomFeature.coerce_vertices(val));
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
            [ctx, target, nv] = GeomFeature.parse_target_context("Rotate", varargin{:});
            args = Rotate.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.angle = 0
                args.origin = [0, 0]
                args.layer = []
                args.output logical = true
            end
            parsed = args;
        end
    end
end
