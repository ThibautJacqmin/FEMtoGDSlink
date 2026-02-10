classdef Mirror < GeomFeature
    % Mirror operation on a feature (limited to horizontal/vertical axes).
    properties (Dependent)
        target
        point
        axis
    end
    methods
        function obj = Mirror(varargin)
            [ctx, target, args] = Mirror.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@GeomFeature(ctx, layer);
            obj.output = args.output;
            obj.add_input(target);
            obj.point = args.point;
            obj.axis = args.axis;
            obj.finalize();
        end

        function set.point(obj, val)
            obj.set_param("point", obj.to_vertices(val));
        end

        function val = get.point(obj)
            val = obj.get_param("point");
        end

        function set.axis(obj, val)
            obj.set_param("axis", obj.to_vertices(val));
        end

        function val = get.axis(obj)
            val = obj.get_param("axis");
        end

        function val = get.target(obj)
            val = obj.inputs{1};
        end
    end
    methods (Static, Access=private)
        function [ctx, target, args] = parse_inputs(varargin)
            if nargin < 1
                error("Mirror requires a target feature.");
            end
            if isa(varargin{1}, 'GeometrySession')
                ctx = varargin{1};
                if numel(varargin) < 2
                    error("Mirror requires a target feature.");
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
                error("Mirror target must be a GeomFeature.");
            end
            p = inputParser;
            p.addParameter('point', [0, 0]);
            p.addParameter('axis', [1, 0]);
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
