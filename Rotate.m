classdef Rotate < GeomFeature
    % Rotate operation on a feature.
    properties (Dependent)
        target
        angle
        origin
    end
    methods
        function obj = Rotate(ctx, target, args)
            arguments
                ctx GeometrySession
                target GeomFeature
                args.angle = 0
                args.origin = [0, 0]
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
            obj.angle = args.angle;
            obj.origin = args.origin;
        end

        function set.angle(obj, val)
            obj.set_param("angle", obj.to_parameter(val, "angle"));
        end

        function val = get.angle(obj)
            val = obj.get_param("angle");
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
    methods (Access=private)
        function p = to_parameter(obj, val, default_name)
            if isa(val, 'Parameter')
                p = val;
                return;
            end
            p = Parameter(val, default_name);
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
