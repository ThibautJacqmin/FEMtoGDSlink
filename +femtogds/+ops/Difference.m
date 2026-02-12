classdef Difference < femtogds.core.GeomFeature
    % Difference boolean operation (base minus tools).
    properties (Dependent)
        base
        tools
    end
    methods
        function obj = Difference(varargin)
            [ctx, base, tools, args] = femtogds.ops.Difference.parse_inputs(varargin{:});
            tool_list = tools;
            if isempty(args.layer)
                layer = base.layer;
            else
                layer = args.layer;
            end
            obj@femtogds.core.GeomFeature(ctx, layer);
            obj.output = args.output;
            obj.add_input(base);
            for i = 1:numel(tool_list)
                obj.add_input(tool_list{i});
            end
            obj.finalize();
        end

        function val = get.base(obj)
            val = obj.inputs{1};
        end

        function val = get.tools(obj)
            if numel(obj.inputs) < 2
                val = {};
            else
                val = obj.inputs(2:end);
            end
        end
    end
    methods (Static, Access=private)
        function [ctx, base, tools, args] = parse_inputs(varargin)
            [ctx, base, tools, nv] = femtogds.core.GeomFeature.parse_base_tools_context("Difference", varargin{:});
            args = femtogds.ops.Difference.parse_options(nv{:});
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

