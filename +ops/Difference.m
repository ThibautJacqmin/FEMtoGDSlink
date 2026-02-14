classdef Difference < core.GeomFeature
    % Difference boolean operation (base minus tools).
    properties (Dependent)
        base
        tools
        keep_input_objects
    end
    methods
        function obj = Difference(varargin)
            [ctx, base, tools, args] = ops.Difference.parse_inputs(varargin{:});
            tool_list = tools;
            if isempty(args.layer)
                layer = base.layer;
            else
                layer = args.layer;
            end
            obj@core.GeomFeature(ctx, layer);
            obj.add_input(base);
            for i = 1:numel(tool_list)
                obj.add_input(tool_list{i});
            end
            obj.keep_input_objects = logical(args.keep_input_objects) || logical(args.keep);
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

        function set.keep_input_objects(obj, val)
            obj.set_param("keep_input_objects", logical(val));
        end

        function val = get.keep_input_objects(obj)
            val = obj.get_param("keep_input_objects", false);
        end
    end
    methods (Static, Access=private)
        function [ctx, base, tools, args] = parse_inputs(varargin)
            [ctx, base, tools, nv] = core.GeomFeature.parse_base_tools_context("Difference", varargin{:});
            args = ops.Difference.parse_options(nv{:});
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

