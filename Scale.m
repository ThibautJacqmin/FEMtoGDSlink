classdef Scale < GeomFeature
    % Scale operation on a feature.
    properties (Dependent)
        target
        factor
        origin
    end
    methods
        function obj = Scale(varargin)
            [ctx, target, args] = Scale.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@GeomFeature(ctx, layer);
            obj.output = args.output;
            obj.add_input(target);
            obj.factor = args.factor;
            obj.origin = args.origin;
            obj.finalize();
        end

        function set.factor(obj, val)
            obj.set_param("factor", obj.to_parameter(val, "factor"));
        end

        function val = get.factor(obj)
            val = obj.get_param("factor");
        end

        function set.origin(obj, val)
            obj.set_param("origin", obj.to_vertices(val));
        end

        function val = get.origin(obj)
            val = obj.get_param("origin");
        end

        function val = get.target(obj)
            val = obj.inputs{1};
        end
    end
    methods (Static, Access=private)
        function [ctx, target, args] = parse_inputs(varargin)
            if nargin < 1
                error("Scale requires a target feature.");
            end
            if isa(varargin{1}, 'GeometrySession')
                ctx = varargin{1};
                if numel(varargin) < 2
                    error("Scale requires a target feature.");
                end
                target = varargin{2};
                nv = varargin(3:end);
            else
                target = varargin{1};
                if isa(target, 'GeomFeature')
                    ctx = target.context();
                else
                    ctx = GeometrySession.require_current();
                end
                nv = varargin(2:end);
            end
            if ~isa(target, 'GeomFeature')
                error("Scale target must be a GeomFeature.");
            end
            p = inputParser;
            p.addParameter('factor', 1);
            p.addParameter('origin', [0, 0]);
            p.addParameter('layer', []);
            p.addParameter('output', true);
            p.parse(nv{:});
            args = p.Results;
        end
    end
    methods (Access=private)
        function p = to_parameter(obj, val, default_name)
            if isa(val, 'Parameter')
                p = val;
                return;
            end
            if default_name == "factor"
                p = Parameter(val, default_name, unit="");
            else
                p = Parameter(val, default_name);
            end
        end

        function v = to_vertices(obj, val)
            if isa(val, 'Vertices')
                v = val;
                return;
            end
            v = Vertices(val);
        end
    end
end
