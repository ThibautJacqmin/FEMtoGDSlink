classdef Move < GeomFeature
    % Move operation on a feature.
    properties (Dependent)
        target
        delta
    end
    methods
        function obj = Move(ctx, target, args)
            arguments
                ctx GeometrySession
                target GeomFeature
                args.delta = [0, 0]
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
