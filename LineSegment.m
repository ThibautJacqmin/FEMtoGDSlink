classdef LineSegment < GeomFeature
    % Line segment primitive between two coordinates.
    properties (Dependent)
        p1
        p2
        width
    end
    methods
        function obj = LineSegment(ctx, args)
            % Create line segment from p1 to p2.
            arguments
                ctx GeometrySession = GeometrySession.empty
                args.p1 = [0, 0]
                args.p2 = [1, 0]
                args.width = 1
                args.layer = "default"
                args.output logical = true
            end
            if isempty(ctx)
                ctx = GeometrySession.require_current();
            end
            obj@GeomFeature(ctx, args.layer);
            obj.output = args.output;
            obj.p1 = args.p1;
            obj.p2 = args.p2;
            obj.width = args.width;
            obj.finalize();
        end

        function set.p1(obj, val)
            obj.set_param("p1", LineSegment.coerce_single_vertex(val, "p1"));
        end

        function val = get.p1(obj)
            val = obj.get_param("p1", Vertices([0, 0]));
        end

        function set.p2(obj, val)
            obj.set_param("p2", LineSegment.coerce_single_vertex(val, "p2"));
        end

        function val = get.p2(obj)
            val = obj.get_param("p2", Vertices([1, 0]));
        end

        function set.width(obj, val)
            prm = GeomFeature.coerce_parameter(val, "", unit="");
            if ~(isscalar(prm.value) && isfinite(prm.value) && prm.value > 0)
                error("LineSegment width must be a finite real scalar > 0.");
            end
            obj.set_param("width", prm);
        end

        function val = get.width(obj)
            val = obj.get_param("width", Parameter(1, "", unit=""));
        end

        function y = points_value(obj)
            pt1 = obj.p1;
            pt2 = obj.p2;
            y = [pt1.value; pt2.value];
        end

        function y = width_value(obj)
            prm = obj.width;
            if isa(prm, 'Parameter')
                y = prm.value;
            else
                y = prm;
            end
        end
    end
    methods (Static, Access=private)
        function v = coerce_single_vertex(val, name)
            v = GeomFeature.coerce_vertices(val);
            if size(v.array, 1) ~= 1 || size(v.array, 2) ~= 2
                error("LineSegment %s must be a single [x y] coordinate.", char(name));
            end
        end
    end
end
