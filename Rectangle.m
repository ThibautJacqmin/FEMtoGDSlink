classdef Rectangle < GeomFeature
    % Rectangle feature with COMSOL and GDS backends.
    properties (Dependent)
        center
        width
        height
    end
    methods
        function obj = Rectangle(ctx, args)
            arguments
                ctx GeometrySession = GeometrySession.empty
                args.center = [0, 0]
                args.width = 1
                args.height = 1
                args.layer = "default"
                args.output logical = true
            end
            if isempty(ctx)
                ctx = GeometrySession.require_current();
            end
            obj@GeomFeature(ctx, args.layer);
            obj.output = args.output;
            obj.center = args.center;
            obj.width = args.width;
            obj.height = args.height;
            obj.finalize();
        end

        function set.center(obj, val)
            obj.set_param("center", obj.to_vertices(val));
        end

        function val = get.center(obj)
            val = obj.get_param("center");
        end

        function set.width(obj, val)
            obj.set_param("width", obj.to_parameter(val, "width"));
        end

        function val = get.width(obj)
            val = obj.get_param("width");
        end

        function set.height(obj, val)
            obj.set_param("height", obj.to_parameter(val, "height"));
        end

        function val = get.height(obj)
            val = obj.get_param("height");
        end

        function verts = vertices(obj)
            c = obj.center_value();
            w = obj.width_value();
            h = obj.height_value();
            l = c(1) - w/2;
            r = c(1) + w/2;
            b = c(2) - h/2;
            t = c(2) + h/2;
            verts = [l, b; l, t; r, t; r, b];
        end

        function c = center_value(obj)
            v = obj.center;
            if isa(v, 'Vertices')
                c = v.value;
            else
                c = v;
            end
        end

        function w = width_value(obj)
            p = obj.width;
            if isa(p, 'Parameter')
                w = p.value;
            else
                w = p;
            end
        end

        function h = height_value(obj)
            p = obj.height;
            if isa(p, 'Parameter')
                h = p.value;
            else
                h = p;
            end
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
