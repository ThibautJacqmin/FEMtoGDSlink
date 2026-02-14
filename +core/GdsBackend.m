classdef GdsBackend < handle
    % GDS backend for emitting feature graph into a GDS layout.
    properties
        session
        modeler
        regions
        emitted
    end
    methods
        function obj = GdsBackend(session)
            obj.session = session;
            obj.modeler = session.gds;
            obj.regions = dictionary(int32.empty(0,1), cell(0,1));
            obj.emitted = dictionary(int32.empty(0,1), false(0,1));
        end

        function emit_all(obj, nodes)
            for i = 1:numel(nodes)
                obj.emit(nodes{i});
            end
        end

        function emit(obj, node)
            region = obj.region_for(node);
            id = int32(node.id);
            if isKey(obj.emitted, id)
                return;
            end
            layer = node.layer;
            layer_id = obj.modeler.create_layer(layer.gds_layer, layer.gds_datatype);
            poly = primitives.Polygon;
            poly.pgon_py = region;
            obj.modeler.add_to_layer(layer_id, poly);
            obj.emitted(id) = true;
        end

        function region = region_for(obj, node)
            id = int32(node.id);
            if isKey(obj.regions, id)
                cached = obj.regions(id);
                region = cached{1};
                return;
            end
            method = "build_" + obj.class_short_name(node);
            if ismethod(obj, method)
                region = obj.(method)(node);
            else
                error("No GDS emitter for feature '" + class(node) + "'.");
            end
            obj.regions(id) = {region};
        end

        function region = build_Rectangle(obj, node)
            pos = obj.gds_length_vector(node.position, "Rectangle position");
            w = double(obj.gds_length_scalar(node.width, "Rectangle width"));
            h = double(obj.gds_length_scalar(node.height, "Rectangle height"));
            base = lower(string(node.base));

            if base == "center"
                pivot = pos;
                origin_corner = pos - [w / 2, h / 2];
            else
                pivot = pos;
                origin_corner = pos;
            end

            l = origin_corner(1);
            r = origin_corner(1) + w;
            b = origin_corner(2);
            t = origin_corner(2) + h;
            verts = [l, b; l, t; r, t; r, b];

            angle = double(obj.scalar_value(node.angle));
            if abs(angle) > 1e-12
                c = cosd(angle);
                s = sind(angle);
                rot = [c, -s; s, c];
                verts = (verts - pivot) * rot.' + pivot;
            end

            verts = round(verts);
            poly = obj.modeler.pya.Polygon.from_s(core.KlayoutCodec.vertices_to_klayout_string(verts));
            region = obj.modeler.pya.Region();
            region.insert(poly);
            region.merge();
        end

        function region = build_Circle(obj, node)
            angle = obj.scalar_value(node.angle);
            if abs(double(angle) - 360) > 1e-9
                error("GDS backend currently supports only full circles (angle=360).");
            end

            pos = obj.gds_length_vector(node.position, "Circle position");
            r = obj.gds_length_scalar(node.radius, "Circle radius");
            n = obj.point_count(node.npoints, "Circle npoints");
            base = lower(string(node.base));

            if base == "center"
                corner = pos - [r, r];
            else
                corner = pos;
            end
            upper = corner + [2*r, 2*r];

            box = obj.modeler.pya.Box(int32(corner(1)), int32(corner(2)), ...
                int32(upper(1)), int32(upper(2)));
            poly = obj.modeler.pya.Polygon.ellipse(box, int32(n));
            region = obj.modeler.pya.Region();
            region.insert(poly);
            region.merge();
        end

        function region = build_Ellipse(obj, node)
            pos = obj.gds_length_vector(node.position, "Ellipse position");
            a = obj.gds_length_scalar(node.a, "Ellipse semiaxis a");
            b = obj.gds_length_scalar(node.b, "Ellipse semiaxis b");
            n = obj.point_count(node.npoints, "Ellipse npoints");
            base = lower(string(node.base));

            if base == "center"
                corner = pos - [a, b];
                pivot = pos;
            else
                corner = pos;
                pivot = pos;
            end
            upper = corner + [2*a, 2*b];

            box = obj.modeler.pya.Box(int32(corner(1)), int32(corner(2)), ...
                int32(upper(1)), int32(upper(2)));
            poly = obj.modeler.pya.Polygon.ellipse(box, int32(n));
            region = obj.modeler.pya.Region();
            region.insert(poly);

            angle = obj.scalar_value(node.angle);
            if abs(double(angle)) > 1e-12
                region = obj.apply_translate(region, -pivot(1), -pivot(2));
                rot = obj.modeler.pya.CplxTrans(1, angle, py.bool(0), 0, 0);
                region = region.transformed(rot);
                region = obj.apply_translate(region, pivot(1), pivot(2));
            end
            region.merge();
        end

        function region = build_Polygon(obj, node)
            verts = obj.gds_length_points(node.vertices, "Polygon vertices");
            if size(verts, 1) < 3
                error("Polygon requires at least 3 vertices.");
            end
            poly = obj.modeler.pya.Polygon.from_s(core.KlayoutCodec.vertices_to_klayout_string(verts));
            region = obj.modeler.pya.Region();
            region.insert(poly);
            region.merge();
        end

        function region = build_Move(obj, node)
            base = obj.region_for(node.target);
            delta = obj.gds_length_vector(node.delta, "Move delta");
            t = obj.modeler.pya.Trans(obj.modeler.pya.Point(delta(1), delta(2)));
            region = base.transformed(t);
        end

        function region = build_Rotate(obj, node)
            base = obj.region_for(node.target);
            origin = obj.gds_length_vector(node.origin, "Rotate origin");
            angle = obj.scalar_value(node.angle);
            region = obj.apply_translate(base, -origin(1), -origin(2));
            rot = obj.modeler.pya.CplxTrans(1, angle, py.bool(0), 0, 0);
            region = region.transformed(rot);
            region = obj.apply_translate(region, origin(1), origin(2));
        end

        function region = build_Scale(obj, node)
            base = obj.region_for(node.target);
            origin = obj.gds_length_vector(node.origin, "Scale origin");
            factor = obj.scalar_value(node.factor);
            region = obj.apply_translate(base, -origin(1), -origin(2));
            sca = obj.modeler.pya.CplxTrans(factor);
            region = region.transformed(sca);
            region = obj.apply_translate(region, origin(1), origin(2));
        end

        function region = build_Mirror(obj, node)
            base = obj.region_for(node.target);
            point = obj.gds_length_vector(node.point, "Mirror point");
            axis = obj.vector_value(node.axis);
            if numel(axis) ~= 2
                error("Mirror axis must be a 2D vector.");
            end
            if axis(1) ~= 0 && axis(2) ~= 0
                error("Mirror supports only horizontal or vertical axes.");
            end
            if axis(1) ~= 0
                region = obj.apply_translate(base, -point(1), 0);
                region = region.transformed(obj.modeler.pya.Trans.M90);
                region = obj.apply_translate(region, point(1), 0);
            else
                region = obj.apply_translate(base, 0, -point(2));
                region = region.transformed(obj.modeler.pya.Trans.M0);
                region = obj.apply_translate(region, 0, point(2));
            end
        end

        function region = build_Union(obj, node)
            if isempty(node.inputs)
                region = obj.modeler.pya.Region();
                return;
            end
            region = obj.region_for(node.inputs{1});
            for i = 2:numel(node.inputs)
                region = region + obj.region_for(node.inputs{i});
            end
            region.merge();
        end

        function region = build_Difference(obj, node)
            base = obj.region_for(node.base);
            region = base;
            tools = node.tools;
            for i = 1:numel(tools)
                region = region - obj.region_for(tools{i});
            end
            region.merge();
        end

        function region = build_Intersection(obj, node)
            if isempty(node.inputs)
                region = obj.modeler.pya.Region();
                return;
            end
            region = obj.region_for(node.inputs{1});
            for i = 2:numel(node.inputs)
                region = region.and_(obj.region_for(node.inputs{i}));
            end
            region.merge();
        end

        function region = build_Array1D(obj, node)
            base = obj.region_for(node.target);
            n = obj.copy_count(node.ncopies, "Array1D ncopies");
            delta = obj.gds_length_vector(node.delta, "Array1D delta");
            region = obj.modeler.pya.Region();
            for i = 0:(n-1)
                shifted = obj.apply_translate(base, i*delta(1), i*delta(2));
                region = region + shifted;
            end
            region.merge();
        end

        function region = build_Array2D(obj, node)
            base = obj.region_for(node.target);
            nx = obj.copy_count(node.ncopies_x, "Array2D ncopies_x");
            ny = obj.copy_count(node.ncopies_y, "Array2D ncopies_y");
            dx = obj.gds_length_vector(node.delta_x, "Array2D delta_x");
            dy = obj.gds_length_vector(node.delta_y, "Array2D delta_y");
            region = obj.modeler.pya.Region();
            for ix = 0:(nx-1)
                for iy = 0:(ny-1)
                    shift = ix*dx + iy*dy;
                    shifted = obj.apply_translate(base, shift(1), shift(2));
                    region = region + shifted;
                end
            end
            region.merge();
        end

        function region = build_Fillet(obj, node)
            base = obj.region_for(node.target);
            radius = obj.gds_length_scalar(node.radius, "Fillet radius");
            npoints = obj.scalar_value(node.npoints);
            region = base;
            if py.hasattr(region, "round_corners")
                region = region.round_corners(radius, radius, npoints);
            else
                warning("GDS fillet not supported by this KLayout build; skipping.");
            end
        end

        function region = build_Chamfer(obj, node)
            base = obj.region_for(node.target);
            dist = obj.gds_length_scalar(node.dist, "Chamfer distance");
            dist = round(double(dist));
            if dist <= 0
                region = base;
                return;
            end

            region = base;
            if py.hasattr(region, "round_corners")
                region = region.round_corners(dist, dist, 2);
            else
                warning("GDS chamfer not supported by this KLayout build; skipping.");
            end
            region.merge();
        end

        function region = build_Offset(obj, node)
            base = obj.region_for(node.target);
            step = double(obj.gds_length_scalar(node.distance, "Offset distance"));
            if node.reverse
                step = -step;
            end
            step = round(step);
            if step == 0
                region = base;
                return;
            end

            if py.hasattr(base, "sized")
                region = base.sized(int32(step));
            elseif py.hasattr(base, "size")
                region = base.dup();
                region.size(int32(step));
            else
                warning("GDS offset not supported by this KLayout build; passing target through.");
                region = base;
            end

            corner = lower(string(node.convexcorner));
            if corner == "fillet" && py.hasattr(region, "round_corners")
                rad = abs(step);
                if rad > 0
                    region = region.round_corners(rad, rad, 16);
                end
            elseif corner == "noconnection"
                warning("GDS offset convexcorner='noconnection' is approximated.");
            end
            if ~node.trim
                warning("GDS offset trim='off' is approximated.");
            end

            region.merge();
        end

        function region = build_Tangent(obj, node)
            mode = lower(string(node.type));
            width = obj.gds_length_scalar(node.width, "Tangent width");

            if mode == "coord"
                p = obj.gds_length_vector(node.coord, "Tangent coordinate");
                pts = obj.tangent_points_from_target(node.target, p, node.start, "Tangent");
            elseif mode == "point"
                if isempty(node.point_target)
                    error("Tangent type='point' requires point_target for GDS build.");
                end
                idx = round(double(obj.scalar_value(node.point_index)));
                p = obj.point_coordinate_from_feature(node.point_target, idx, "Tangent point_target");
                pts = obj.tangent_points_from_target(node.target, p, node.start, "Tangent");
            elseif mode == "edge"
                if isempty(node.edge2)
                    error("Tangent type='edge' requires edge2 for GDS build.");
                end
                pts = obj.tangent_points_between_targets(node.target, node.edge2, node.start, ...
                    "Tangent(edge)");
            else
                error("Unsupported Tangent type '%s'.", char(mode));
            end

            region = obj.region_from_polyline(pts, width, "Tangent");
        end

        function region = build_Point(obj, node)
            pts = obj.gds_length_points(node.p, "Point coordinates");
            size_nm = obj.gds_length_scalar(node.marker_size, "Point marker size");
            size_nm = round(double(size_nm));
            if size_nm < 1
                size_nm = 1;
            end

            region = obj.modeler.pya.Region();
            for i = 1:size(pts, 1)
                x = int32(pts(i, 1));
                y = int32(pts(i, 2));
                box = obj.modeler.pya.Box(x, y, int32(x + size_nm), int32(y + size_nm));
                region.insert(box);
            end
            region.merge();
        end

        function region = build_LineSegment(obj, node)
            p1 = obj.gds_length_vector(node.p1, "LineSegment p1");
            p2 = obj.gds_length_vector(node.p2, "LineSegment p2");
            pts = [p1; p2];
            width = obj.gds_length_scalar(node.width, "LineSegment width");
            region = obj.curve_region_from_points(pts, "open", width, "LineSegment");
        end

        function region = build_InterpolationCurve(obj, node)
            pts = obj.gds_length_points(node.points, "InterpolationCurve points");
            width = obj.gds_length_scalar(node.width, "InterpolationCurve width");
            region = obj.curve_region_from_points(pts, node.type, width, "InterpolationCurve");
        end

        function region = build_QuadraticBezier(obj, node)
            p0 = double(obj.gds_length_vector(node.p0, "QuadraticBezier p0"));
            p1 = double(obj.gds_length_vector(node.p1, "QuadraticBezier p1"));
            p2 = double(obj.gds_length_vector(node.p2, "QuadraticBezier p2"));
            n = obj.point_count(node.npoints, "QuadraticBezier npoints");
            pts = obj.sample_quadratic_bezier_points(p0, p1, p2, n);
            width = obj.gds_length_scalar(node.width, "QuadraticBezier width");
            region = obj.curve_region_from_points(pts, node.type, width, "QuadraticBezier");
        end

        function region = build_CubicBezier(obj, node)
            p0 = double(obj.gds_length_vector(node.p0, "CubicBezier p0"));
            p1 = double(obj.gds_length_vector(node.p1, "CubicBezier p1"));
            p2 = double(obj.gds_length_vector(node.p2, "CubicBezier p2"));
            p3 = double(obj.gds_length_vector(node.p3, "CubicBezier p3"));
            n = obj.point_count(node.npoints, "CubicBezier npoints");
            pts = obj.sample_cubic_bezier_points(p0, p1, p2, p3, n);
            width = obj.gds_length_scalar(node.width, "CubicBezier width");
            region = obj.curve_region_from_points(pts, node.type, width, "CubicBezier");
        end

        function region = build_CircularArc(obj, node)
            center = double(obj.gds_length_vector(node.center, "CircularArc center"));
            radius = double(obj.gds_length_scalar(node.radius, "CircularArc radius"));
            n = obj.point_count(node.npoints, "CircularArc npoints");
            a0 = double(obj.scalar_value(node.start_angle));
            a1 = double(obj.scalar_value(node.end_angle));
            pts = obj.sample_circular_arc_points(center, radius, a0, a1, n);
            width = obj.gds_length_scalar(node.width, "CircularArc width");
            region = obj.curve_region_from_points(pts, node.type, width, "CircularArc");
        end

        function region = build_ParametricCurve(obj, node)
            pts = obj.session.gds_integer(node.sampled_points(), "ParametricCurve points");
            width = obj.gds_length_scalar(node.width, "ParametricCurve width");
            region = obj.curve_region_from_points(pts, node.type, width, "ParametricCurve");
        end

        function region = build_Thicken(obj, node)
            [pts, is_curve, context] = obj.curve_points_for_thicken(node.target);
            if is_curve
                region = obj.thicken_curve_region(pts, node, context);
                return;
            end

            base = obj.region_for(node.target);
            region = obj.thicken_region_fallback(base, node);
        end
    end
    methods (Access=private)
        function v = vector_value(~, val)
            if isa(val, 'types.Vertices')
                v = val.value;
            else
                v = val;
            end
        end

        function v = scalar_value(~, val)
            if isa(val, 'types.Parameter')
                v = val.value;
                return;
            end
            if isobject(val) && ismethod(val, 'value')
                v = val.value();
                return;
            end
            v = val;
        end
        function name = class_short_name(~, obj_or_node)
            % Return unqualified class name from a potentially packaged class.
            cname = string(class(obj_or_node));
            parts = split(cname, ".");
            name = parts(end);
        end
        function region = apply_translate(obj, region, dx, dy)
            t = obj.modeler.pya.Trans(obj.modeler.pya.Point(dx, dy));
            region = region.transformed(t);
        end

        function value_nm = parameter_length_nm(~, p, context)
            % Resolve one types.Parameter length value into nm.
            [scale_nm, is_length] = core.GeometrySession.unit_scale_to_nm(string(p.unit));
            if ~is_length
                error("%s expects a length parameter; unsupported unit '%s'.", ...
                    char(string(context)), char(string(p.unit)));
            end
            value_nm = double(p.value) * scale_nm;
            if ~(isscalar(value_nm) && isfinite(value_nm))
                error("%s must resolve to a finite scalar length.", char(string(context)));
            end
        end

        function vec_nm = length_points_nm(obj, val, context)
            % Resolve Nx2 points into nm using Vertices prefactor unit when available.
            if isa(val, 'types.Vertices')
                scale_nm = obj.parameter_length_nm(val.prefactor, string(context) + " prefactor");
                vec_nm = double(val.array) .* scale_nm;
            else
                vec_nm = double(val);
            end
            if size(vec_nm, 2) ~= 2
                error("%s points must be an Nx2 array.", char(string(context)));
            end
        end

        function pts = gds_length_points(obj, val, context)
            pts = obj.length_points_nm(val, context);
            pts = obj.session.gds_integer(pts, context);
        end

        function vec = gds_length_vector(obj, val, context)
            if isa(val, 'types.Vertices')
                if val.nvertices ~= 1
                    error("%s must resolve to a single [x y] coordinate.", char(string(context)));
                end
                vec_nm = obj.length_points_nm(val, context);
                vec_nm = vec_nm(1, :);
            else
                vec_nm = obj.vector_value(val);
            end
            vec = obj.session.gds_integer(vec_nm, context);
        end

        function s = gds_length_scalar(obj, val, context)
            if isa(val, 'types.Parameter')
                s_nm = obj.parameter_length_nm(val, context);
            else
                s_nm = obj.scalar_value(val);
            end
            s = obj.session.gds_integer(s_nm, context);
        end

        function n = copy_count(obj, val, context)
            n = obj.scalar_value(val);
            n = round(double(n));
            if ~(isscalar(n) && isfinite(n) && n >= 1)
                error("%s must be a scalar >= 1.", char(string(context)));
            end
        end

        function n = point_count(obj, val, context)
            n = obj.scalar_value(val);
            n = round(double(n));
            if ~(isscalar(n) && isfinite(n) && n >= 8)
                error("%s must be a scalar integer >= 8.", char(string(context)));
            end
        end

        function pts = sample_quadratic_bezier_points(~, p0, p1, p2, n)
            t = linspace(0, 1, n).';
            omt = 1 - t;
            pts = (omt.^2) .* p0 + ...
                (2 .* omt .* t) .* p1 + ...
                (t.^2) .* p2;
            pts = round(pts);
        end

        function pts = sample_cubic_bezier_points(~, p0, p1, p2, p3, n)
            t = linspace(0, 1, n).';
            omt = 1 - t;
            pts = (omt.^3) .* p0 + ...
                (3 .* omt.^2 .* t) .* p1 + ...
                (3 .* omt .* t.^2) .* p2 + ...
                (t.^3) .* p3;
            pts = round(pts);
        end

        function pts = sample_circular_arc_points(~, center, radius, a0, a1, n)
            theta = linspace(a0, a1, n).';
            pts = [center(1) + radius .* cosd(theta), center(2) + radius .* sind(theta)];
            pts = round(pts);
        end

        function region = curve_region_from_points(obj, pts, type, width, context)
            % Build region from sampled points based on open/closed/solid mode.
            if size(pts, 2) ~= 2
                error("%s points must be an Nx2 array.", char(string(context)));
            end

            mode = lower(string(type));
            if mode == "open"
                region = obj.region_from_polyline(pts, width, context);
            elseif any(mode == ["closed", "solid"])
                if size(pts, 1) < 3
                    error("%s closed/solid mode requires at least 3 points.", ...
                        char(string(context)));
                end
                if any(pts(1, :) ~= pts(end, :))
                    pts(end+1, :) = pts(1, :);
                end
                region = obj.region_from_polygon(pts);
            else
                error("%s type must be 'open', 'closed', or 'solid'.", char(string(context)));
            end
        end

        function region = region_from_polygon(obj, pts)
            % Create region from polygon vertices.
            poly = obj.modeler.pya.Polygon.from_s(core.KlayoutCodec.vertices_to_klayout_string(pts));
            region = obj.modeler.pya.Region();
            region.insert(poly);
            region.merge();
        end

        function region = region_from_polyline(obj, pts, width, context)
            % Stroke a polyline with KLayout Path and convert to region polygon.
            if size(pts, 1) < 2
                error("%s open mode requires at least 2 points.", char(string(context)));
            end

            width = round(double(width));
            if ~(isscalar(width) && isfinite(width) && width >= 1)
                error("%s width must be a scalar >= 1 nm for open-curve GDS emission.", ...
                    char(string(context)));
            end

            py_points = cell(1, size(pts, 1));
            for i = 1:size(pts, 1)
                py_points{i} = obj.modeler.pya.Point(int32(pts(i, 1)), int32(pts(i, 2)));
            end
            path = obj.modeler.pya.Path(py.list(py_points), int32(width));
            poly = path.polygon();
            region = obj.modeler.pya.Region();
            region.insert(poly);
            region.merge();
        end

        function [pts, is_curve, context] = curve_points_for_thicken(obj, target)
            % Return centerline points when target is an open curve primitive.
            pts = zeros(0, 2);
            is_curve = false;
            context = "Thicken";

            switch class(target)
                case 'primitives.LineSegment'
                    context = "Thicken(LineSegment)";
                    p1 = obj.gds_length_vector(target.p1, context + " p1");
                    p2 = obj.gds_length_vector(target.p2, context + " p2");
                    pts = [p1; p2];
                    is_curve = true;
                case 'primitives.InterpolationCurve'
                    if lower(string(target.type)) == "open"
                        context = "Thicken(InterpolationCurve)";
                        pts = obj.gds_length_points(target.points, context + " points");
                        is_curve = true;
                    end
                case 'primitives.QuadraticBezier'
                    if lower(string(target.type)) == "open"
                        context = "Thicken(QuadraticBezier)";
                        p0 = double(obj.gds_length_vector(target.p0, context + " p0"));
                        p1 = double(obj.gds_length_vector(target.p1, context + " p1"));
                        p2 = double(obj.gds_length_vector(target.p2, context + " p2"));
                        n = obj.point_count(target.npoints, context + " npoints");
                        pts = obj.sample_quadratic_bezier_points(p0, p1, p2, n);
                        is_curve = true;
                    end
                case 'primitives.CubicBezier'
                    if lower(string(target.type)) == "open"
                        context = "Thicken(CubicBezier)";
                        p0 = double(obj.gds_length_vector(target.p0, context + " p0"));
                        p1 = double(obj.gds_length_vector(target.p1, context + " p1"));
                        p2 = double(obj.gds_length_vector(target.p2, context + " p2"));
                        p3 = double(obj.gds_length_vector(target.p3, context + " p3"));
                        n = obj.point_count(target.npoints, context + " npoints");
                        pts = obj.sample_cubic_bezier_points(p0, p1, p2, p3, n);
                        is_curve = true;
                    end
                case 'primitives.CircularArc'
                    if lower(string(target.type)) == "open"
                        context = "Thicken(CircularArc)";
                        center = double(obj.gds_length_vector(target.center, context + " center"));
                        radius = double(obj.gds_length_scalar(target.radius, context + " radius"));
                        n = obj.point_count(target.npoints, context + " npoints");
                        a0 = double(obj.scalar_value(target.start_angle));
                        a1 = double(obj.scalar_value(target.end_angle));
                        pts = obj.sample_circular_arc_points(center, radius, a0, a1, n);
                        is_curve = true;
                    end
                case 'primitives.ParametricCurve'
                    if lower(string(target.type)) == "open"
                        context = "Thicken(ParametricCurve)";
                        pts = obj.session.gds_integer(target.sampled_points(), context + " points");
                        is_curve = true;
                    end
            end
        end

        function region = thicken_curve_region(obj, pts, node, context)
            % Thicken an open centerline curve with path-based stroking.
            mode = lower(string(node.offset));
            if mode == "symmetric"
                total = obj.gds_length_scalar(node.totalthick, context + " total thickness");
                up = 0.5 * double(total);
                down = up;
            else
                up = double(obj.gds_length_scalar(node.upthick, context + " upper thickness"));
                down = double(obj.gds_length_scalar(node.downthick, context + " lower thickness"));
                total = up + down;
            end

            width = round(double(total));
            if ~(isscalar(width) && isfinite(width) && width >= 1)
                error("%s total thickness must be >= 1 nm.", char(context));
            end

            shift = 0.5 * (up - down);
            if abs(shift) > 1e-9
                pts = obj.shift_polyline_by_normal(pts, shift, context);
            end

            ends = lower(string(node.ends));
            corner = lower(string(node.convexcorner));
            if corner == "noconnection" || (ends == "circular" && corner ~= "fillet")
                region = obj.stroke_polyline_segments(pts, width, ends, context);
                return;
            end

            use_round = corner == "fillet";
            region = obj.path_region_from_points(pts, width, ends, use_round, context);
        end

        function region = thicken_region_fallback(obj, base, node)
            % Fallback thickening for non-open-curve targets.
            mode = lower(string(node.offset));
            if mode == "symmetric"
                total = double(obj.gds_length_scalar(node.totalthick, "Thicken total thickness"));
                grow = round(0.5 * total);
            else
                up = double(obj.gds_length_scalar(node.upthick, "Thicken upper thickness"));
                down = double(obj.gds_length_scalar(node.downthick, "Thicken lower thickness"));
                grow = round(0.5 * (up + down));
                if abs(up - down) > 1e-9
                    warning("GDS Thicken asymmetric offset on non-curve target is approximated as symmetric.");
                end
            end

            if grow < 1
                region = base;
                return;
            end

            if py.hasattr(base, "sized")
                region = base.sized(int32(grow));
            elseif py.hasattr(base, "size")
                region = base.dup();
                region.size(int32(grow));
            else
                warning("GDS Thicken fallback unavailable in this KLayout build; passing target through.");
                region = base;
            end
            region.merge();
        end

        function region = stroke_polyline_segments(obj, pts, width, ends, context)
            % Stroke each segment independently, then merge the result.
            if size(pts, 1) < 2
                error("%s requires at least 2 points.", char(string(context)));
            end

            region = obj.modeler.pya.Region();
            for i = 1:(size(pts, 1)-1)
                if all(pts(i, :) == pts(i+1, :))
                    continue;
                end
                seg = [pts(i, :); pts(i+1, :)];
                seg_region = obj.path_region_from_points(seg, width, ends, false, context);
                region = region + seg_region;
            end
            region.merge();
        end

        function region = path_region_from_points(obj, pts, width, ends, use_round, context)
            % Build region from one polyline using KLayout Path options.
            if size(pts, 1) < 2
                error("%s requires at least 2 points.", char(string(context)));
            end

            width = round(double(width));
            if ~(isscalar(width) && isfinite(width) && width >= 1)
                error("%s width must be a scalar >= 1 nm.", char(string(context)));
            end

            py_points = cell(1, size(pts, 1));
            for i = 1:size(pts, 1)
                py_points{i} = obj.modeler.pya.Point(int32(pts(i, 1)), int32(pts(i, 2)));
            end
            path = obj.modeler.pya.Path(py.list(py_points), int32(width));

            if ends == "circular"
                path.round = py.True;
                ext = int32(round(width / 2));
                path.bgn_ext = ext;
                path.end_ext = ext;
            else
                if use_round
                    path.round = py.True;
                else
                    path.round = py.False;
                end
                path.bgn_ext = int32(0);
                path.end_ext = int32(0);
            end

            poly = path.polygon();
            region = obj.modeler.pya.Region();
            region.insert(poly);
            region.merge();
        end

        function shifted = shift_polyline_by_normal(~, pts, shift, context)
            % Shift polyline points by signed local normal.
            if size(pts, 1) < 2
                error("%s requires at least 2 points to shift.", char(string(context)));
            end

            p = double(pts);
            shifted = zeros(size(p));
            n = size(p, 1);
            for i = 1:n
                if i == 1
                    t = p(2, :) - p(1, :);
                elseif i == n
                    t = p(n, :) - p(n-1, :);
                else
                    t_prev = p(i, :) - p(i-1, :);
                    t_next = p(i+1, :) - p(i, :);
                    t_prev = ThickenNormalizeVector(t_prev);
                    t_next = ThickenNormalizeVector(t_next);
                    t = t_prev + t_next;
                    if norm(t) < 1e-12
                        t = t_next;
                    end
                end

                if norm(t) < 1e-12
                    t = [1, 0];
                end
                t = t ./ norm(t);
                nrm = [-t(2), t(1)];
                shifted(i, :) = p(i, :) + shift * nrm;
            end

            shifted = round(shifted);
            keep = true(size(shifted, 1), 1);
            for i = 2:size(shifted, 1)
                if all(shifted(i, :) == shifted(i-1, :))
                    keep(i) = false;
                end
            end
            shifted = shifted(keep, :);
            if size(shifted, 1) < 2
                error("%s shift collapsed the polyline.", char(string(context)));
            end
        end

        function p = point_coordinate_from_feature(obj, feature, index, context)
            % Extract one coordinate from a Point feature for Tangent mode='point'.
            if ~isa(feature, 'primitives.Point')
                error("%s currently supports only Point features.", char(string(context)));
            end
            pts = obj.gds_length_points(feature.p, context + " coordinates");
            if ~(isscalar(index) && isfinite(index) && index >= 1 && index <= size(pts, 1))
                error("%s index must be between 1 and %d.", char(string(context)), size(pts, 1));
            end
            p = pts(round(index), :);
        end

        function pts = tangent_points_from_target(obj, target, external_point, start_guess, context)
            % Build one tangent segment from target to an external point.
            [center, radius, is_arc, a0, a1] = obj.circle_like_geometry(target, context);
            [t1, t2] = obj.circle_tangent_candidates(center, radius, external_point, context);

            candidates = [t1; t2];
            valid = true(2, 1);
            if is_arc
                valid(1) = obj.angle_on_arc(obj.angle_of_point(center, t1), a0, a1);
                valid(2) = obj.angle_on_arc(obj.angle_of_point(center, t2), a0, a1);
            end

            if ~any(valid)
                error("%s found no tangent point on the selected arc.", char(string(context)));
            end
            pick = obj.pick_candidate_index(valid, start_guess);
            tangency = candidates(pick, :);
            pts = [external_point; tangency];
        end

        function pts = tangent_points_between_targets(obj, target1, target2, start_guess, context)
            % Build one common tangent segment between two circle-like targets.
            [c1, r1, is_arc1, a01, a11] = obj.circle_like_geometry(target1, context + " first");
            [c2, r2, is_arc2, a02, a12] = obj.circle_like_geometry(target2, context + " second");

            c = c2 - c1;
            z = dot(c, c);
            r = r1 - r2;
            d = z - r * r;
            if ~(z > 0 && d > 0)
                error("%s has no valid common tangent for selected targets.", char(string(context)));
            end

            s = sqrt(d);
            n1 = (c * r + [-c(2), c(1)] * s) / z;
            n2 = (c * r - [-c(2), c(1)] * s) / z;

            p11 = c1 + r1 * n1;
            p21 = c2 + r2 * n1;
            p12 = c1 + r1 * n2;
            p22 = c2 + r2 * n2;

            valid = true(2, 1);
            if is_arc1
                valid(1) = valid(1) && obj.angle_on_arc(obj.angle_of_point(c1, p11), a01, a11);
                valid(2) = valid(2) && obj.angle_on_arc(obj.angle_of_point(c1, p12), a01, a11);
            end
            if is_arc2
                valid(1) = valid(1) && obj.angle_on_arc(obj.angle_of_point(c2, p21), a02, a12);
                valid(2) = valid(2) && obj.angle_on_arc(obj.angle_of_point(c2, p22), a02, a12);
            end
            if ~any(valid)
                error("%s found no valid tangent touching both arcs.", char(string(context)));
            end

            pick = obj.pick_candidate_index(valid, start_guess);
            if pick == 1
                pts = [p11; p21];
            else
                pts = [p12; p22];
            end
        end

        function [center, radius, is_arc, a0, a1] = circle_like_geometry(obj, target, context)
            % Extract center/radius for Circle or CircularArc targets.
            if isa(target, 'primitives.Circle')
                pos = obj.gds_length_vector(target.position, context + " circle position");
                radius = double(obj.gds_length_scalar(target.radius, context + " circle radius"));
                base = lower(string(target.base));
                if base == "center"
                    center = pos;
                else
                    center = pos + [radius, radius];
                end
                is_arc = false;
                a0 = 0;
                a1 = 360;
                return;
            end

            if isa(target, 'primitives.CircularArc')
                center = obj.gds_length_vector(target.center, context + " arc center");
                radius = double(obj.gds_length_scalar(target.radius, context + " arc radius"));
                a0 = double(obj.scalar_value(target.start_angle));
                a1 = double(obj.scalar_value(target.end_angle));
                is_arc = true;
                return;
            end

            error("%s currently supports Circle or CircularArc targets.", char(string(context)));
        end

        function [t1, t2] = circle_tangent_candidates(~, center, radius, point, context)
            % Compute two tangency points from external point to a circle.
            v = point - center;
            d2 = dot(v, v);
            d = sqrt(d2);
            if d <= radius
                error("%s coordinate must be outside the target circle/arc.", char(string(context)));
            end
            coef1 = (radius * radius) / d2;
            coef2 = radius * sqrt(d2 - radius * radius) / d2;
            perp = [-v(2), v(1)];
            t1 = center + coef1 * v + coef2 * perp;
            t2 = center + coef1 * v - coef2 * perp;
        end

        function idx = pick_candidate_index(obj, valid, start_guess)
            % Pick one of two tangent candidates from start_guess in [0,1].
            guess = obj.scalar_value(start_guess);
            guess = double(guess);
            if ~(isscalar(guess) && isfinite(guess))
                guess = 0.5;
            end
            pref = 1;
            if guess > 0.5
                pref = 2;
            end
            if valid(pref)
                idx = pref;
            elseif valid(3 - pref)
                idx = 3 - pref;
            else
                error("No valid tangent candidate available.");
            end
        end

        function ang = angle_of_point(~, center, p)
            % Return point angle around center in degrees in [0,360).
            ang = atan2d(p(2) - center(2), p(1) - center(1));
            ang = mod(ang, 360);
        end

        function tf = angle_on_arc(~, ang, a0, a1)
            % Return true if angle is on directed sweep a0->a1.
            delta = a1 - a0;
            tol = 1e-8;
            if delta >= 0
                tf = mod(ang - a0, 360) <= (delta + tol);
            else
                tf = mod(a0 - ang, 360) <= (-delta + tol);
            end
        end
    end
end

function v = ThickenNormalizeVector(v)
% Return normalized 2D vector; leave zero vectors unchanged.
n = norm(v);
if n > 0
    v = v ./ n;
end
end




