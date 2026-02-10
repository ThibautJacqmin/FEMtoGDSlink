classdef Move < GeomFeature
    % Move operation on a feature.
    properties (Dependent)
        target
        delta
    end
    methods
        function obj = Move(varargin)
            [ctx, target, args] = Move.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@GeomFeature(ctx, layer);
            obj.output = args.output;
            obj.add_input(target);
            obj.delta = args.delta;
        end

        function set.delta(obj, val)
            obj.set_param("delta", obj.to_vertices(val));
        end

        function val = get.delta(obj)
            val = obj.get_param("delta");
        end

        function val = get.target(obj)
            val = obj.inputs{1};
        end
    end
    methods (Static, Access=private)
        function [ctx, target, args] = parse_inputs(varargin)
            if nargin < 1
                error("Move requires a target feature.");
            end
            if isa(varargin{1}, 'GeometrySession')
                ctx = varargin{1};
                if numel(varargin) < 2
                    error("Move requires a target feature.");
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
                error("Move target must be a GeomFeature.");
            end
            p = inputParser;
            p.addParameter('delta', [0, 0]);
            p.addParameter('layer', []);
            p.addParameter('output', true);
            p.parse(nv{:});
            args = p.Results;
        end

    end
    methods (Access=private)
        function v = to_vertices(obj, val)
            if isa(val, 'Vertices')
                v = val;
                return;
            end
            v = Vertices(val);
        end
    end
end
