classdef Intersection < femtogds.core.GeomFeature
    % Intersection boolean operation on multiple features.
    properties (Dependent)
        members
    end
    methods
        function obj = Intersection(varargin)
            [ctx, members, args] = Intersection.parse_inputs(varargin{:});
            if isempty(args.layer) && ~isempty(members)
                layer = members{1}.layer;
            else
                layer = args.layer;
            end
            obj@femtogds.core.GeomFeature(ctx, layer);
            obj.output = args.output;
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
            [ctx, members, nv] = femtogds.core.GeomFeature.parse_members_context("Intersection", varargin{:});
            args = Intersection.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.layer = []
                args.output logical = true
            end
            parsed = args;
        end
    end
end

