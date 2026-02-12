classdef Extract < femtogds.core.GeomFeature
    % Extract selected input objects/entities.
    properties (Dependent)
        members
        inputhandling
    end
    methods
        function obj = Extract(varargin)
            [ctx, members, args] = Extract.parse_inputs(varargin{:});
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
            obj.inputhandling = args.inputhandling;
            obj.finalize();
        end

        function val = get.members(obj)
            val = obj.inputs;
        end

        function set.inputhandling(obj, val)
            h = Extract.normalize_inputhandling(val);
            obj.set_param("inputhandling", h);
        end

        function val = get.inputhandling(obj)
            val = obj.get_param("inputhandling", "keep");
        end
    end
    methods (Static, Access=private)
        function [ctx, members, args] = parse_inputs(varargin)
            [ctx, members, nv] = femtogds.core.GeomFeature.parse_members_context("Extract", varargin{:});
            args = Extract.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.inputhandling {mustBeTextScalar} = "keep"
                args.layer = []
                args.output logical = true
            end
            parsed = args;
        end

        function h = normalize_inputhandling(val)
            h = lower(string(val));
            if ~any(h == ["keep", "remainder", "remove"])
                error("Extract inputhandling must be 'keep', 'remainder', or 'remove'.");
            end
        end
    end
end

