classdef Array1D < femtogds.core.GeomFeature
    % Linear array of one geometry feature.
    properties (Dependent)
        target
        ncopies
        delta
    end
    methods
        function obj = Array1D(varargin)
            % Build a 1D array from a target feature and displacement vector.
            [ctx, target, args] = femtogds.ops.Array1D.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@femtogds.core.GeomFeature(ctx, layer);
            obj.add_input(target);
            obj.ncopies = args.ncopies;
            obj.delta = args.delta;
            obj.finalize();
        end

        function set.ncopies(obj, val)
            obj.set_param("ncopies", femtogds.core.GeomFeature.coerce_parameter(val, "ncopies", unit=""));
        end

        function val = get.ncopies(obj)
            val = obj.get_param("ncopies");
        end

        function set.delta(obj, val)
            obj.set_param("delta", femtogds.core.GeomFeature.coerce_vertices(val));
        end

        function val = get.delta(obj)
            val = obj.get_param("delta");
        end

        function val = get.target(obj)
            val = obj.inputs{1};
        end
    end
    methods (Static, Access=private)
        function [ctx, target, args] = parse_inputs(varargin)
            [ctx, target, nv] = femtogds.core.GeomFeature.parse_target_context("Array1D", varargin{:});
            args = femtogds.ops.Array1D.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.ncopies = 1
                args.delta = [1, 0]
                args.layer = []
            end
            parsed = args;
        end
    end
end

