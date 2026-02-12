classdef Circle < femtogds.core.GeomFeature
    % Circle primitive (disk) with optional COMSOL sector angle metadata.
    properties (Dependent)
        position
        center
        corner
        base
        radius
        angle
        rotation
        npoints
    end
    methods
        function obj = Circle(ctx, args)
            % Create a circle from center/corner, radius, and layer settings.
            arguments
                ctx femtogds.core.GeometrySession = femtogds.core.GeometrySession.empty
                args.center = [0, 0]
                args.corner = []
                args.base {mustBeTextScalar} = "center"
                args.radius = 1
                args.angle = 360
                args.rotation = 0
                args.npoints = 128
                args.layer = "default"
                args.output logical = true
            end
            if isempty(ctx)
                ctx = femtogds.core.GeometrySession.require_current();
            end
            obj@femtogds.core.GeomFeature(ctx, args.layer);
            obj.output = args.output;
            obj.radius = args.radius;
            obj.angle = args.angle;
            obj.rotation = args.rotation;
            obj.npoints = args.npoints;
            obj.base = args.base;
            if ~isempty(args.corner)
                if obj.base ~= "corner"
                    error("Circle corner argument requires base='corner'.");
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
            v = femtogds.core.GeomFeature.coerce_vertices(val);
            if size(v.array, 1) ~= 1 || size(v.array, 2) ~= 2
                error("Circle position must be a single [x y] coordinate.");
            end
            obj.set_param("position", v);
        end

        function val = get.position(obj)
            val = obj.get_param("position");
        end

        function set.base(obj, val)
            new_base = Circle.normalize_base(val);
            old_base = obj.get_param("base", new_base);
            if old_base == new_base
                obj.set_param("base", new_base);
                return;
            end

            pos = obj.position_value();
            r = obj.radius_value();
            if old_base == "center" && new_base == "corner"
                pos = pos - [r, r];
            elseif old_base == "corner" && new_base == "center"
                pos = pos + [r, r];
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
                r = obj.radius_value();
                val = femtogds.types.Vertices(pos + [r, r]);
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
                r = obj.radius_value();
                val = femtogds.types.Vertices(pos - [r, r]);
            end
        end

        function set.radius(obj, val)
            obj.set_param("radius", femtogds.core.GeomFeature.coerce_parameter(val, "radius"));
        end

        function val = get.radius(obj)
            val = obj.get_param("radius", femtogds.types.Parameter(1, "radius"));
        end

        function set.angle(obj, val)
            p = femtogds.core.GeomFeature.coerce_parameter(val, "", unit="deg");
            a = p.value;
            if ~(isscalar(a) && isfinite(a) && a > 0)
                error("Circle angle must be a finite real scalar > 0 degrees.");
            end
            obj.set_param("angle", p);
        end

        function val = get.angle(obj)
            val = obj.get_param("angle", femtogds.types.Parameter(360, "", unit="deg"));
        end

        function set.rotation(obj, val)
            obj.set_param("rotation", femtogds.core.GeomFeature.coerce_parameter(val, "", unit="deg"));
        end

        function val = get.rotation(obj)
            val = obj.get_param("rotation", femtogds.types.Parameter(0, "", unit="deg"));
        end

        function set.npoints(obj, val)
            obj.set_param("npoints", femtogds.core.GeomFeature.coerce_parameter(val, "npoints", unit=""));
        end

        function val = get.npoints(obj)
            val = obj.get_param("npoints", femtogds.types.Parameter(128, "", unit=""));
        end

        function r = radius_value(obj)
            p = obj.radius;
            if isa(p, 'femtogds.types.Parameter')
                r = p.value;
            else
                r = p;
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
                error("Circle base must be 'center' or 'corner'.");
            end
        end
    end
end




