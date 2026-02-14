classdef Array2D < core.GeomFeature
    % 2D array of one geometry feature from two displacement directions.
    properties (Dependent)
        target
        ncopies_x
        ncopies_y
        delta_x
        delta_y
    end
    methods
        function obj = Array2D(varargin)
            % Build a 2D array from a target feature and two lattice vectors.
            [ctx, target, args] = ops.Array2D.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@core.GeomFeature(ctx, layer);
            obj.add_input(target);
            obj.ncopies_x = args.ncopies_x;
            obj.ncopies_y = args.ncopies_y;
            obj.delta_x = args.delta_x;
            obj.delta_y = args.delta_y;
            obj.finalize();
        end

        function set.ncopies_x(obj, val)
            obj.set_param("ncopies_x", core.GeomFeature.coerce_parameter(val, "ncopies_x", unit=""));
        end

        function val = get.ncopies_x(obj)
            val = obj.get_param("ncopies_x");
        end

        function set.ncopies_y(obj, val)
            obj.set_param("ncopies_y", core.GeomFeature.coerce_parameter(val, "ncopies_y", unit=""));
        end

        function val = get.ncopies_y(obj)
            val = obj.get_param("ncopies_y");
        end

        function set.delta_x(obj, val)
            obj.set_param("delta_x", core.GeomFeature.coerce_vertices(val));
        end

        function val = get.delta_x(obj)
            val = obj.get_param("delta_x");
        end

        function set.delta_y(obj, val)
            obj.set_param("delta_y", core.GeomFeature.coerce_vertices(val));
        end

        function val = get.delta_y(obj)
            val = obj.get_param("delta_y");
        end

        function val = get.target(obj)
            val = obj.inputs{1};
        end
    end
    methods (Static, Access=private)
        function [ctx, target, args] = parse_inputs(varargin)
            [ctx, target, nv] = core.GeomFeature.parse_target_context("Array2D", varargin{:});
            args = ops.Array2D.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.ncopies_x = 1
                args.ncopies_y = 1
                args.delta_x = [1, 0]
                args.delta_y = [0, 1]
                args.layer = []
            end
            parsed = args;
        end
    end
end

