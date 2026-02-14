classdef Move < core.GeomFeature
    % Move operation on a feature.
    properties (Dependent)
        target
        delta
        keep_input_objects
    end
    methods
        function obj = Move(varargin)
            [ctx, target, args] = ops.Move.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@core.GeomFeature(ctx, layer);
            obj.add_input(target);
            obj.delta = args.delta;
            obj.keep_input_objects = logical(args.keep_input_objects) || logical(args.keep);
            obj.finalize();
        end

        function set.delta(obj, val)
            obj.set_param("delta", core.GeomFeature.coerce_vertices(val));
        end

        function val = get.delta(obj)
            val = obj.get_param("delta");
        end

        function set.keep_input_objects(obj, val)
            obj.set_param("keep_input_objects", logical(val));
        end

        function val = get.keep_input_objects(obj)
            val = obj.get_param("keep_input_objects", false);
        end

        function val = get.target(obj)
            val = obj.inputs{1};
        end
    end
    methods (Static, Access=private)
        function [ctx, target, args] = parse_inputs(varargin)
            [ctx, target, nv] = core.GeomFeature.parse_target_context("Move", varargin{:});
            args = ops.Move.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.delta = [0, 0]
                args.keep_input_objects logical = false
                args.keep logical = false
                args.layer = []
            end
            parsed = args;
        end
    end
end

