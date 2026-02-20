classdef Rectangle < core.GeomFeature
    % Rectangle primitive with COMSOL-compatible base/angle definition.
    properties (Dependent)
        position
        base
        center
        corner
        width
        height
        angle
        left
        right
        top
        bottom
        top_right
        top_left
        bottom_right
        bottom_left
        fillet_width
        fillet_height
    end
    methods
        function obj = Rectangle(ctx, args)
            % Create a rectangle from center/corner, size, and optional rotation.
            arguments
                ctx core.GeometryPipeline = core.GeometryPipeline.empty
                args.center = [0, 0]
                args.corner = []
                args.base {mustBeTextScalar} = "center"
                args.width = 1
                args.height = 1
                args.angle = 0
                args.layer = "default"
                args.fillet_width = 1
                args.fillet_height = 1
            end
            if isempty(ctx)
                ctx = core.GeometryPipeline.require_current();
            end
            obj@core.GeomFeature(ctx, args.layer);
            obj.width = args.width;
            obj.height = args.height;
            obj.angle = args.angle;
            obj.fillet_width = args.fillet_width;
            obj.fillet_height = args.fillet_height;
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
            v = core.GeomFeature.coerce_vertices(val);
            if size(v.array, 1) ~= 1 || size(v.array, 2) ~= 2
                error("Rectangle position must be a single [x y] coordinate.");
            end
            obj.set_param("position", v);
        end

        function val = get.position(obj)
            val = obj.get_param("position");
        end

        function set.base(obj, val)
            new_base = primitives.Rectangle.normalize_base(val);
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
            obj.set_param("position", types.Vertices(pos));
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
                val = types.Vertices(pos);
            else
                val = types.Vertices(pos + [obj.width_value()/2, obj.height_value()/2]);
            end
        end

        function set.corner(obj, val)
            obj.base = "corner";
            obj.position = val;
        end

        function val = get.corner(obj)
            pos = obj.position_value();
            if obj.base == "corner"
                val = types.Vertices(pos);
            else
                val = types.Vertices(pos - [obj.width_value()/2, obj.height_value()/2]);
            end
        end

        function set.width(obj, val)
            obj.set_param("width", core.GeomFeature.coerce_parameter(val, "width"));
        end

        function val = get.width(obj)
            val = obj.get_param("width");
        end

        function set.height(obj, val)
            obj.set_param("height", core.GeomFeature.coerce_parameter(val, "height"));
        end

        function val = get.height(obj)
            val = obj.get_param("height");
        end

        function set.angle(obj, val)
            obj.set_param("angle", core.GeomFeature.coerce_parameter(val, "angle", unit=""));
        end

        function val = get.angle(obj)
            val = obj.get_param("angle", types.Parameter(0, "", unit=""));
        end

        function val = get.left(obj)
            [l, ~, ~, ~] = obj.unrotated_bounds_value();
            val = types.Parameter(l, "", auto_register=false);
        end

        function val = get.right(obj)
            [~, r, ~, ~] = obj.unrotated_bounds_value();
            val = types.Parameter(r, "", auto_register=false);
        end

        function val = get.bottom(obj)
            [~, ~, b, ~] = obj.unrotated_bounds_value();
            val = types.Parameter(b, "", auto_register=false);
        end

        function val = get.top(obj)
            [~, ~, ~, t] = obj.unrotated_bounds_value();
            val = types.Parameter(t, "", auto_register=false);
        end

        function val = get.top_left(obj)
            [l, ~, ~, t] = obj.unrotated_bounds_value();
            val = types.Vertices([l, t]);
        end

        function val = get.top_right(obj)
            [~, r, ~, t] = obj.unrotated_bounds_value();
            val = types.Vertices([r, t]);
        end

        function val = get.bottom_left(obj)
            [l, ~, b, ~] = obj.unrotated_bounds_value();
            val = types.Vertices([l, b]);
        end

        function val = get.bottom_right(obj)
            [~, r, b, ~] = obj.unrotated_bounds_value();
            val = types.Vertices([r, b]);
        end

        function set.fillet_width(obj, val)
            obj.set_param("fillet_width", core.GeomFeature.coerce_parameter(val, "fillet_width"));
        end

        function val = get.fillet_width(obj)
            val = obj.get_param("fillet_width", types.Parameter(1, "", auto_register=false));
        end

        function set.fillet_height(obj, val)
            obj.set_param("fillet_height", core.GeomFeature.coerce_parameter(val, "fillet_height"));
        end

        function val = get.fillet_height(obj)
            val = obj.get_param("fillet_height", types.Parameter(1, "", auto_register=false));
        end

        function verts = vertices(obj)
            % Return rectangle polygon vertices after base-positioned rotation.
            [l, r, b, t] = obj.unrotated_bounds_value();
            verts = [l, b; l, t; r, t; r, b];

            a = obj.angle_value();
            if abs(a) < 1e-12
                return;
            end
            pivot = obj.rotation_pivot_value();
            verts = primitives.Rectangle.rotate_points(verts, pivot, a);
        end

        function fillet_polygons = get_fillets(obj, args)
            % Build 4 Bezier-corner fillet polygons around the rectangle.
            arguments
                obj
                args.fillet_width = []
                args.fillet_height = []
                args.npoints (1,1) double {mustBeInteger, mustBeGreaterThanOrEqual(args.npoints, 2)} = 16
                args.layer = []
            end

            if isempty(args.fillet_width)
                fw = obj.fillet_width_value();
            else
                fw = obj.scalar_value(args.fillet_width, "fillet_width");
            end
            if isempty(args.fillet_height)
                fh = obj.fillet_height_value();
            else
                fh = obj.scalar_value(args.fillet_height, "fillet_height");
            end
            if fw < 0 || fh < 0
                error("Rectangle fillet_width/fillet_height must be >= 0.");
            end

            [l, r, b, t] = obj.unrotated_bounds_value();
            cx = (l + r) / 2;
            cy = (b + t) / 2;

            p0 = [r, b];
            p1 = [r + fw, b];
            p2 = [r, b + fh];
            base_pts = Utilities.bezier_fillet(p0, p1, p2, args.npoints);
            base_pts(end+1, :) = p2;
            base_pts(end+1, :) = p0;
            base_pts(end+1, :) = p1;

            pts = cell(1, 4);
            pts{1} = base_pts;
            pts{2} = base_pts;
            pts{2}(:, 1) = 2 * cx - pts{2}(:, 1);
            pts{3} = base_pts;
            pts{3}(:, 2) = 2 * cy - pts{3}(:, 2);
            pts{4} = pts{3};
            pts{4}(:, 1) = 2 * cx - pts{4}(:, 1);

            a = obj.angle_value();
            if abs(a) > 1e-12
                pivot = obj.rotation_pivot_value();
                for i = 1:numel(pts)
                    pts{i} = primitives.Rectangle.rotate_points(pts{i}, pivot, a);
                end
            end

            target_layer = obj.layer;
            if ~isempty(args.layer)
                target_layer = args.layer;
            end

            fillet_polygons = cell(1, 4);
            ctx = obj.context();
            for i = 1:4
                fillet_polygons{i} = primitives.Polygon(ctx, ...
                    vertices=types.Vertices(pts{i}), ...
                    layer=target_layer);
            end
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
            if isa(p, 'types.Parameter')
                w = p.value;
            else
                w = p;
            end
        end

        function h = height_value(obj)
            p = obj.height;
            if isa(p, 'types.Parameter')
                h = p.value;
            else
                h = p;
            end
        end

        function a = angle_value(obj)
            p = obj.angle;
            if isa(p, 'types.Parameter')
                a = p.value;
            else
                a = p;
            end
        end

        function p = position_value(obj)
            v = obj.position;
            if isa(v, 'types.Vertices')
                p = v.value;
            else
                p = v;
            end
        end

        function y = fillet_width_value(obj)
            y = obj.scalar_value(obj.fillet_width, "fillet_width");
        end

        function y = fillet_height_value(obj)
            y = obj.scalar_value(obj.fillet_height, "fillet_height");
        end
    end
    methods (Static, Access=private)
        function b = normalize_base(val)
            b = lower(string(val));
            if ~any(b == ["center", "corner"])
                error("Rectangle base must be 'center' or 'corner'.");
            end
        end

        function verts = rotate_points(verts, pivot, angle_deg)
            c = cosd(angle_deg);
            s = sind(angle_deg);
            rot = [c, -s; s, c];
            verts = (verts - pivot) * rot.' + pivot;
        end
    end
    methods (Access=protected)
        function [l, r, b, t] = unrotated_bounds_value(obj)
            p = obj.position_value();
            w = obj.width_value();
            h = obj.height_value();
            if obj.base == "center"
                l = p(1) - w / 2;
                r = p(1) + w / 2;
                b = p(2) - h / 2;
                t = p(2) + h / 2;
            else
                l = p(1);
                r = p(1) + w;
                b = p(2);
                t = p(2) + h;
            end
        end

        function p = rotation_pivot_value(obj)
            p = obj.position_value();
        end

        function y = scalar_value(~, val, context)
            if isa(val, 'types.Parameter')
                y = val.value;
            else
                y = val;
            end
            if ~(isscalar(y) && isnumeric(y) && isfinite(y))
                error("%s must resolve to a finite scalar.", char(string(context)));
            end
            y = double(y);
        end
    end
end




