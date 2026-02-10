classdef Fillet < GeomFeature
    % Fillet operation on a feature.
    properties (Dependent)
        target
        radius
        npoints
        points
    end
    methods
        function obj = Fillet(ctx, target, args)
            arguments
                ctx GeometrySession
                target GeomFeature
                args.radius = 1
                args.npoints = 8
                args.points double = []
                args.layer = []
                args.output logical = true
            end
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
    methods (Access=private)
        function p = to_parameter(obj, val, default_name)
            if isa(val, 'Parameter')
                p = val;
                return;
            end
            p = Parameter(val, default_name);
        end
    end
end
