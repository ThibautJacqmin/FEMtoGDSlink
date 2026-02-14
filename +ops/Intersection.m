classdef Intersection < core.GeomFeature
    % Intersection boolean operation on multiple features.
    properties (Dependent)
        members
        keep_input_objects
    end
    methods
        function obj = Intersection(varargin)
            [ctx, members, args] = ops.Intersection.parse_inputs(varargin{:});
            if isempty(args.layer) && ~isempty(members)
                layer = members{1}.layer;
            else
                layer = args.layer;
            end
            obj@core.GeomFeature(ctx, layer);
            for i = 1:numel(members)
                obj.add_input(members{i});
            end
            obj.keep_input_objects = logical(args.keep_input_objects) || logical(args.keep);
            obj.finalize();
        end

        function val = get.members(obj)
            val = obj.inputs;
        end

        function set.keep_input_objects(obj, val)
            obj.set_param("keep_input_objects", logical(val));
        end

        function val = get.keep_input_objects(obj)
            val = obj.get_param("keep_input_objects", false);
        end
    end
    methods (Static, Access=private)
        function [ctx, members, args] = parse_inputs(varargin)
            [ctx, members, nv] = core.GeomFeature.parse_members_context("Intersection", varargin{:});
            args = ops.Intersection.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.keep_input_objects logical = false
                args.keep logical = false
                args.layer = []
            end
            parsed = args;
        end
    end
end

