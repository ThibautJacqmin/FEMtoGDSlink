classdef Union < core.GeomFeature
    % Union boolean operation on multiple features.
    properties (Dependent)
        members
    end
    methods
        function obj = Union(varargin)
            [ctx, members, args] = ops.Union.parse_inputs(varargin{:});
            if isempty(args.layer) && ~isempty(members)
                layer = members{1}.layer;
            else
                layer = args.layer;
            end
            obj@core.GeomFeature(ctx, layer);
            for i = 1:numel(members)
                obj.add_input(members{i});
            end
            obj.finalize();
        end

        function val = get.members(obj)
            val = obj.inputs;
        end
    end
    methods (Static, Access=private)
        function [ctx, members, args] = parse_inputs(varargin)
            [ctx, members, nv] = core.GeomFeature.parse_members_context("Union", varargin{:});
            args = ops.Union.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.layer = []
            end
            parsed = args;
        end
    end
end

