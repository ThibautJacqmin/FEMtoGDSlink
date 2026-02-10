classdef Difference < GeomFeature
    % Difference boolean operation (base minus tools).
    properties (Dependent)
        base
        tools
    end
    methods
        function obj = Difference(ctx, base, tools, args)
            arguments
                ctx GeometrySession
                base GeomFeature
                tools
                args.layer = []
                args.output logical = true
            end
            tool_list = Difference.normalize_inputs(tools);
            if isempty(args.layer)
                layer = base.layer;
            else
                layer = args.layer;
            end
            obj@GeomFeature(ctx, layer);
            obj.output = args.output;
            obj.add_input(base);
            for i = 1:numel(tool_list)
                obj.add_input(tool_list{i});
            end
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
        function inputs = normalize_inputs(members)
            if iscell(members)
                inputs = members;
            else
                inputs = num2cell(members);
            end
        end
    end
end
