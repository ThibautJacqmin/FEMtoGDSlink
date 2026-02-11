classdef Ellipse < GeomFeature
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
                ctx GeometrySession = GeometrySession.empty
                args.center = [0, 0]
                args.corner = []
                args.base {mustBeTextScalar} = "center"
                args.a = 1
                args.b = 1
                args.angle = 0
                args.npoints = 128
                args.layer = "default"
                args.output logical = true
            end
            if isempty(ctx)
                ctx = GeometrySession.require_current();
            end
            obj@GeomFeature(ctx, args.layer);
            obj.output = args.output;
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
            v = GeomFeature.coerce_vertices(val);
            if size(v.array, 1) ~= 1 || size(v.array, 2) ~= 2
                error("Ellipse position must be a single [x y] coordinate.");
            end
            obj.set_param("position", v);
        end

        function val = get.position(obj)
            val = obj.get_param("position");
        end

        function set.base(obj, val)
            new_base = Ellipse.normalize_base(val);
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
            obj.set_param("position", Vertices(pos));
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
                val = Vertices(pos);
            else
                val = Vertices(pos + [obj.a_value(), obj.b_value()]);
            end
        end

        function set.corner(obj, val)
            obj.base = "corner";
            obj.position = val;
        end

        function val = get.corner(obj)
            pos = obj.position_value();
            if obj.base == "corner"
                val = Vertices(pos);
            else
                val = Vertices(pos - [obj.a_value(), obj.b_value()]);
            end
        end

        function set.a(obj, val)
            obj.set_param("a", GeomFeature.coerce_parameter(val, "a"));
        end

        function val = get.a(obj)
            val = obj.get_param("a", Parameter(1, "a"));
        end

        function set.b(obj, val)
            obj.set_param("b", GeomFeature.coerce_parameter(val, "b"));
        end

        function val = get.b(obj)
            val = obj.get_param("b", Parameter(1, "b"));
        end

        function set.angle(obj, val)
            obj.set_param("angle", GeomFeature.coerce_parameter(val, "angle", unit=""));
        end

        function val = get.angle(obj)
            val = obj.get_param("angle", Parameter(0, "", unit=""));
        end

        function set.npoints(obj, val)
            obj.set_param("npoints", GeomFeature.coerce_parameter(val, "npoints", unit=""));
        end

        function val = get.npoints(obj)
            val = obj.get_param("npoints", Parameter(128, "", unit=""));
        end

        function y = a_value(obj)
            p = obj.a;
            if isa(p, 'Parameter')
                y = p.value;
            else
                y = p;
            end
        end

        function y = b_value(obj)
            p = obj.b;
            if isa(p, 'Parameter')
                y = p.value;
            else
                y = p;
            end
        end

        function p = position_value(obj)
            v = obj.position;
            if isa(v, 'Vertices')
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
