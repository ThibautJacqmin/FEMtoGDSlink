classdef Rectangle < femtogds.core.GeomFeature
    % Rectangle primitive with COMSOL-compatible base/angle definition.
    properties (Dependent)
        position
        base
        center
        corner
        width
        height
        angle
    end
    methods
        function obj = Rectangle(ctx, args)
            % Create a rectangle from center/corner, size, and optional rotation.
            arguments
                ctx femtogds.core.GeometrySession = femtogds.core.GeometrySession.empty
                args.center = [0, 0]
                args.corner = []
                args.base {mustBeTextScalar} = "center"
                args.width = 1
                args.height = 1
                args.angle = 0
                args.layer = "default"
                args.output logical = true
            end
            if isempty(ctx)
                ctx = femtogds.core.GeometrySession.require_current();
            end
            obj@femtogds.core.GeomFeature(ctx, args.layer);
            obj.output = args.output;
            obj.width = args.width;
            obj.height = args.height;
            obj.angle = args.angle;
            obj.base = args.base;
            if ~isempty(args.corner)
                if obj.base ~= "corner"
                    error("Rectangle corner argument requires base='corner'.");
                end
                obj.corner = args.corner;
            else
                if obj.base == "corner"
                    % Backward-compatible behavior: interpret center argument as position.
                    obj.corner = args.center;
                else
                    obj.center = args.center;
                end
            end
            obj.finalize();
        end

        function set.position(obj, val)
            obj.set_param("position", femtogds.core.GeomFeature.coerce_vertices(val));
        end

        function val = get.position(obj)
            val = obj.get_param("position");
        end

        function set.base(obj, val)
            new_base = Rectangle.normalize_base(val);
            old_base = obj.get_param("base", new_base);
            if old_base == new_base
                obj.set_param("base", new_base);
                return;
            end

            pos = obj.position_value();
            w = obj.width_value();
            h = obj.height_value();
            if old_base == "center" && new_base == "corner"
                pos = pos - [w/2, h/2];
            elseif old_base == "corner" && new_base == "center"
                pos = pos + [w/2, h/2];
            end
            obj.set_param("position", femtogds.types.Vertices(pos));
            obj.set_param("base", new_base);
        end

        function val = get.base(obj)
            val = obj.get_param("base", "center");
        end

        function set.center(obj, val)
            obj.base = "center";
            obj.position = val;
        end

        function val = get.center(obj)
            pos = obj.position_value();
            if obj.base == "center"
                val = femtogds.types.Vertices(pos);
            else
                val = femtogds.types.Vertices(pos + [obj.width_value()/2, obj.height_value()/2]);
            end
        end

        function set.corner(obj, val)
            obj.base = "corner";
            obj.position = val;
        end

        function val = get.corner(obj)
            pos = obj.position_value();
            if obj.base == "corner"
                val = femtogds.types.Vertices(pos);
            else
                val = femtogds.types.Vertices(pos - [obj.width_value()/2, obj.height_value()/2]);
            end
        end

        function set.width(obj, val)
            obj.set_param("width", femtogds.core.GeomFeature.coerce_parameter(val, "width"));
        end

        function val = get.width(obj)
            val = obj.get_param("width");
        end

        function set.height(obj, val)
            obj.set_param("height", femtogds.core.GeomFeature.coerce_parameter(val, "height"));
        end

        function val = get.height(obj)
            val = obj.get_param("height");
        end

        function set.angle(obj, val)
            obj.set_param("angle", femtogds.core.GeomFeature.coerce_parameter(val, "angle", unit=""));
        end

        function val = get.angle(obj)
            val = obj.get_param("angle", femtogds.types.Parameter(0, "", unit=""));
        end

        function verts = vertices(obj)
            % Return rectangle polygon vertices after base-positioned rotation.
            p = obj.position_value();
            w = obj.width_value();
            h = obj.height_value();
            if obj.base == "center"
                pivot = p;
                origin_corner = p - [w/2, h/2];
            else
                pivot = p;
                origin_corner = p;
            end

            l = origin_corner(1);
            r = origin_corner(1) + w;
            b = origin_corner(2);
            t = origin_corner(2) + h;
            verts = [l, b; l, t; r, t; r, b];

            a = obj.angle_value();
            if abs(a) < 1e-12
                return;
            end
            c = cosd(a);
            s = sind(a);
            rot = [c, -s; s, c];
            verts = (verts - pivot) * rot.' + pivot;
        end

        function c = center_value(obj)
            if obj.base == "center"
                c = obj.position_value();
            else
                c = obj.position_value() + [obj.width_value()/2, obj.height_value()/2];
            end
        end

        function w = width_value(obj)
            p = obj.width;
            if isa(p, 'femtogds.types.Parameter')
                w = p.value;
            else
                w = p;
            end
        end

        function h = height_value(obj)
            p = obj.height;
            if isa(p, 'femtogds.types.Parameter')
                h = p.value;
            else
                h = p;
            end
        end

        function a = angle_value(obj)
            p = obj.angle;
            if isa(p, 'femtogds.types.Parameter')
                a = p.value;
            else
                a = p;
            end
        end

        function p = position_value(obj)
            v = obj.position;
            if isa(v, 'femtogds.types.Vertices')
                p = v.value;
            else
                p = v;
            end
        end
    end
    methods (Static, Access=private)
        function b = normalize_base(val)
            b = lower(string(val));
            if ~any(b == ["center", "corner"])
                error("Rectangle base must be 'center' or 'corner'.");
            end
        end
    end
end




