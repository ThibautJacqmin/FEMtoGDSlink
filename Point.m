classdef Point < GeomFeature
    % Point primitive that can represent one or several points.
    properties (Dependent)
        p
        marker_size
    end
    methods
        function obj = Point(ctx, args)
            % Create point primitive from one or more 2D coordinates.
            arguments
                ctx GeometrySession = GeometrySession.empty
                args.p = [0, 0]
                args.marker_size = 1
                args.layer = "default"
                args.output logical = true
            end
            if isempty(ctx)
                ctx = GeometrySession.require_current();
            end
            obj@GeomFeature(ctx, args.layer);
            obj.output = args.output;
            obj.p = args.p;
            obj.marker_size = args.marker_size;
            obj.finalize();
        end

        function set.p(obj, val)
            v = GeomFeature.coerce_vertices(val);
            if size(v.array, 2) ~= 2
                error("Point coordinates must be an Nx2 array.");
            end
            obj.set_param("p", v);
        end

        function val = get.p(obj)
            val = obj.get_param("p", Vertices([0, 0]));
        end

        function set.marker_size(obj, val)
            prm = GeomFeature.coerce_parameter(val, "", unit="");
            if ~(isscalar(prm.value) && isfinite(prm.value) && prm.value > 0)
                error("Point marker_size must be a finite real scalar > 0.");
            end
            obj.set_param("marker_size", prm);
        end

        function val = get.marker_size(obj)
            val = obj.get_param("marker_size", Parameter(1, "", unit=""));
        end

        function y = p_value(obj)
            v = obj.p;
            if isa(v, 'Vertices')
                y = v.value;
            else
                y = v;
            end
        end

        function y = marker_size_value(obj)
            prm = obj.marker_size;
            if isa(prm, 'Parameter')
                y = prm.value;
            else
                y = prm;
            end
        end
    end
end
