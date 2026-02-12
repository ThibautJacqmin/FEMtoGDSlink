classdef Mirror < femtogds.core.GeomFeature
    % Mirror operation on a feature (limited to horizontal/vertical axes).
    properties (Dependent)
        target
        point
        axis
    end
    methods
        function obj = Mirror(varargin)
            [ctx, target, args] = Mirror.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@femtogds.core.GeomFeature(ctx, layer);
            obj.output = args.output;
            obj.add_input(target);
            obj.point = args.point;
            obj.axis = args.axis;
            obj.finalize();
        end

        function set.point(obj, val)
            obj.set_param("point", femtogds.core.GeomFeature.coerce_vertices(val));
        end

        function val = get.point(obj)
            val = obj.get_param("point");
        end

        function set.axis(obj, val)
            obj.set_param("axis", femtogds.core.GeomFeature.coerce_vertices(val));
        end

        function val = get.axis(obj)
            val = obj.get_param("axis");
        end

        function val = get.target(obj)
            val = obj.inputs{1};
        end
    end
    methods (Static, Access=private)
        function [ctx, target, args] = parse_inputs(varargin)
            [ctx, target, nv] = femtogds.core.GeomFeature.parse_target_context("Mirror", varargin{:});
            args = Mirror.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.point = [0, 0]
                args.axis = [1, 0]
                args.layer = []
                args.output logical = true
            end
            parsed = args;
        end
    end
end

