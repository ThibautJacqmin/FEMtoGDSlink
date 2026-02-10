classdef Mirror < GeomFeature
    % Mirror operation on a feature (limited to horizontal/vertical axes).
    properties (Dependent)
        target
        point
        axis
    end
    methods
        function obj = Mirror(ctx, target, args)
            arguments
                ctx GeometrySession
                target GeomFeature
                args.point = [0, 0]
                args.axis = [1, 0]
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
            obj.point = args.point;
            obj.axis = args.axis;
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
