classdef Array1D < core.GeomFeature
    % Linear array of one geometry feature.
    properties (Dependent)
        target
        ncopies
        delta
        unwanted_indices
        keep_input_objects
    end
    methods
        function obj = Array1D(varargin)
            % Build a 1D array from a target feature and displacement vector.
            [ctx, target, args] = ops.Array1D.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@core.GeomFeature(ctx, layer);
            obj.add_input(target);
            obj.ncopies = args.ncopies;
            obj.delta = args.delta;
            obj.unwanted_indices = args.unwanted_indices;
            obj.keep_input_objects = logical(args.keep_input_objects) || logical(args.keep);
            obj.finalize();
        end

        function set.ncopies(obj, val)
            obj.set_param("ncopies", core.GeomFeature.coerce_parameter(val, "ncopies", unit=""));
        end

        function val = get.ncopies(obj)
            val = obj.get_param("ncopies");
        end

        function set.delta(obj, val)
            obj.set_param("delta", core.GeomFeature.coerce_vertices(val));
        end

        function val = get.delta(obj)
            val = obj.get_param("delta");
        end

        function set.unwanted_indices(obj, val)
            obj.set_param("unwanted_indices", ops.Array1D.normalize_unwanted_indices(val));
        end

        function val = get.unwanted_indices(obj)
            val = obj.get_param("unwanted_indices", zeros(1, 0));
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
            [ctx, target, nv] = core.GeomFeature.parse_target_context("Array1D", varargin{:});
            args = ops.Array1D.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.ncopies = 1
                args.delta = [1, 0]
                args.unwanted_indices = []
                args.keep_input_objects logical = false
                args.keep logical = false
                args.layer = []
            end
            parsed = args;
        end

        function idx = normalize_unwanted_indices(val)
            if isempty(val)
                idx = zeros(1, 0);
                return;
            end
            if ~(isnumeric(val) && isvector(val))
                error("Array1D unwanted_indices must be a numeric vector of 1-based indices.");
            end
            idx = double(val(:).');
            if any(~isfinite(idx)) || any(abs(idx - round(idx)) > 1e-12) || any(idx < 1)
                error("Array1D unwanted_indices must contain finite integers >= 1.");
            end
            idx = unique(round(idx), "stable");
        end
    end
end

