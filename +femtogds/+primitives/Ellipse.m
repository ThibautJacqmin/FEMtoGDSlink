classdef Ellipse < femtogds.core.GeomFeature
    % Ellipse primitive with COMSOL-compatible base/rotation definition.
    properties (Dependent)
        position
        center
        corner
        base
        a
        b
        angle
        npoints
    end
    methods
        function obj = Ellipse(ctx, args)
            % Create an ellipse from center/corner, semiaxes, and rotation.
            arguments
                ctx femtogds.core.GeometrySession = femtogds.core.GeometrySession.empty
                args.center = [0, 0]
                args.corner = []
                args.base {mustBeTextScalar} = "center"
                args.a = 1
                args.b = 1
                args.angle = 0
                args.npoints = 128
                args.layer = "default"
            end
            if isempty(ctx)
                ctx = femtogds.core.GeometrySession.require_current();
            end
            obj@femtogds.core.GeomFeature(ctx, args.layer);
            obj.a = args.a;
            obj.b = args.b;
            obj.angle = args.angle;
            obj.npoints = args.npoints;
            obj.base = args.base;
            if ~isempty(args.corner)
                if obj.base ~= "corner"
                    error("Ellipse corner argument requires base='corner'.");
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
                error("Ellipse position must be a single [x y] coordinate.");
            end
            obj.set_param("position", v);
        end

        function val = get.position(obj)
            val = obj.get_param("position");
        end

        function set.base(obj, val)
            new_base = femtogds.primitives.Ellipse.normalize_base(val);
            old_base = obj.get_param("base", new_base);
            if old_base == new_base
                obj.set_param("base", new_base);
                return;
            end

            pos = obj.position_value();
            a_val = obj.a_value();
            b_val = obj.b_value();
            if old_base == "center" && new_base == "corner"
                pos = pos - [a_val, b_val];
            elseif old_base == "corner" && new_base == "center"
                pos = pos + [a_val, b_val];
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
                val = femtogds.types.Vertices(pos + [obj.a_value(), obj.b_value()]);
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
                val = femtogds.types.Vertices(pos - [obj.a_value(), obj.b_value()]);
            end
        end

        function set.a(obj, val)
            obj.set_param("a", femtogds.core.GeomFeature.coerce_parameter(val, "a"));
        end

        function val = get.a(obj)
            val = obj.get_param("a", femtogds.types.Parameter(1, "a"));
        end

        function set.b(obj, val)
            obj.set_param("b", femtogds.core.GeomFeature.coerce_parameter(val, "b"));
        end

        function val = get.b(obj)
            val = obj.get_param("b", femtogds.types.Parameter(1, "b"));
        end

        function set.angle(obj, val)
            p = femtogds.core.GeomFeature.coerce_parameter(val, "", unit="deg");
            a = p.value;
            if ~(isscalar(a) && isfinite(a))
                error("Ellipse angle must be a finite real scalar in degrees.");
            end
            obj.set_param("angle", p);
        end

        function val = get.angle(obj)
            val = obj.get_param("angle", femtogds.types.Parameter(0, "", unit="deg"));
        end

        function set.npoints(obj, val)
            obj.set_param("npoints", femtogds.core.GeomFeature.coerce_parameter(val, "npoints", unit=""));
        end

        function val = get.npoints(obj)
            val = obj.get_param("npoints", femtogds.types.Parameter(128, "", unit=""));
        end

        function y = a_value(obj)
            p = obj.a;
            if isa(p, 'femtogds.types.Parameter')
                y = p.value;
            else
                y = p;
            end
        end

        function y = b_value(obj)
            p = obj.b;
            if isa(p, 'femtogds.types.Parameter')
                y = p.value;
            else
                y = p;
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
                error("Ellipse base must be 'center' or 'corner'.");
            end
        end
    end
end




