classdef Fillet < GeomFeature
    % Fillet operation on a feature.
    properties (Dependent)
        target
        radius
        npoints
        points
    end
    methods
        function obj = Fillet(varargin)
            [ctx, target, args] = Fillet.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@GeomFeature(ctx, layer);
            obj.output = args.output;
            obj.add_input(target);
            obj.radius = args.radius;
            obj.npoints = args.npoints;
            obj.points = args.points;
            obj.finalize();
        end

        function set.radius(obj, val)
            obj.set_param("radius", obj.to_parameter(val, "radius"));
        end

        function val = get.radius(obj)
            val = obj.get_param("radius");
        end

        function set.npoints(obj, val)
            obj.set_param("npoints", obj.to_parameter(val, "npoints"));
        end

        function val = get.npoints(obj)
            val = obj.get_param("npoints");
        end

        function set.points(obj, val)
            obj.set_param("points", val);
        end

        function val = get.points(obj)
            val = obj.get_param("points");
        end

        function val = get.target(obj)
            val = obj.inputs{1};
        end
    end
    methods (Static, Access=private)
        function [ctx, target, args] = parse_inputs(varargin)
            if nargin < 1
                error("Fillet requires a target feature.");
            end
            if isa(varargin{1}, 'GeometrySession')
                ctx = varargin{1};
                if numel(varargin) < 2
                    error("Fillet requires a target feature.");
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
                error("Fillet target must be a GeomFeature.");
            end
            p = inputParser;
            p.addParameter('radius', 1);
            p.addParameter('npoints', 8);
            p.addParameter('points', []);
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
            if default_name == "npoints"
                p = Parameter(val, default_name, unit="");
            else
                p = Parameter(val, default_name);
            end
        end
    end
end
