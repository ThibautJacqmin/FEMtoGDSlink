classdef Difference < GeomFeature
    % Difference boolean operation (base minus tools).
    properties (Dependent)
        base
        tools
    end
    methods
        function obj = Difference(varargin)
            [ctx, base, tools, args] = Difference.parse_inputs(varargin{:});
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
            if nargin < 2
                error("Difference requires base and tool features.");
            end
            if isa(varargin{1}, 'GeometrySession')
                ctx = varargin{1};
                base = varargin{2};
                if numel(varargin) < 3
                    error("Difference requires tool features.");
                end
                tools = varargin{3};
                nv = varargin(4:end);
            else
                base = varargin{1};
                tools = varargin{2};
                if isa(base, 'GeomFeature')
                    ctx = base.context();
                else
                    ctx = GeometrySession.require_current();
                end
                nv = varargin(3:end);
            end
            if ~isa(base, 'GeomFeature')
                error("Difference base must be a GeomFeature.");
            end
            p = inputParser;
            p.addParameter('layer', []);
            p.addParameter('output', true);
            p.parse(nv{:});
            args = p.Results;
        end

        function inputs = normalize_inputs(members)
            if iscell(members)
                inputs = members;
            else
                inputs = num2cell(members);
            end
        end
    end
end
