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
            obj.regions = containers.Map('KeyType', 'int32', 'ValueType', 'any');
            obj.emitted = containers.Map('KeyType', 'int32', 'ValueType', 'logical');
        end

        function emit_all(obj, nodes)
            for i = 1:numel(nodes)
                obj.emit(nodes{i});
            end
        end

        function emit(obj, node)
            region = obj.region_for(node);
            if ~node.output
                return;
            end
            id = int32(node.id);
            if isKey(obj.emitted, id)
                return;
            end
            layer = node.layer;
            layer_id = obj.modeler.create_layer(layer.gds_layer, layer.gds_datatype);
            poly = Polygon;
            poly.pgon_py = region;
            obj.modeler.add_to_layer(layer_id, poly);
            obj.emitted(id) = true;
        end

        function region = region_for(obj, node)
            id = int32(node.id);
            if isKey(obj.regions, id)
                region = obj.regions(id);
                return;
            end
            method = "build_" + class(node);
            if ismethod(obj, method)
                region = obj.(method)(node);
            else
                error("No GDS emitter for feature '" + class(node) + "'.");
            end
            obj.regions(id) = region;
        end

        function region = build_Rectangle(obj, node)
            verts = obj.session.gds_integer(node.vertices(), "Rectangle vertices");
            poly = obj.modeler.pya.Polygon.from_s(Utilities.vertices_to_klayout_string(verts));
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
            verts = obj.session.gds_integer(node.vertices_value(), "Polygon vertices");
            if size(verts, 1) < 3
                error("Polygon requires at least 3 vertices.");
            end
            poly = obj.modeler.pya.Polygon.from_s(Utilities.vertices_to_klayout_string(verts));
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

        function region = build_Point(obj, node)
            pts = obj.session.gds_integer(node.p_value(), "Point coordinates");
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
            pts = obj.session.gds_integer(node.points_value(), "LineSegment points");
            width = obj.gds_length_scalar(node.width, "LineSegment width");
            region = obj.curve_region_from_points(pts, "open", width, "LineSegment");
        end

        function region = build_InterpolationCurve(obj, node)
            pts = obj.session.gds_integer(node.points_value(), "InterpolationCurve points");
            width = obj.gds_length_scalar(node.width, "InterpolationCurve width");
            region = obj.curve_region_from_points(pts, node.type, width, "InterpolationCurve");
        end

        function region = build_QuadraticBezier(obj, node)
            pts = obj.session.gds_integer(node.sampled_points(), "QuadraticBezier points");
            width = obj.gds_length_scalar(node.width, "QuadraticBezier width");
            region = obj.curve_region_from_points(pts, node.type, width, "QuadraticBezier");
        end

        function region = build_CubicBezier(obj, node)
            pts = obj.session.gds_integer(node.sampled_points(), "CubicBezier points");
            width = obj.gds_length_scalar(node.width, "CubicBezier width");
            region = obj.curve_region_from_points(pts, node.type, width, "CubicBezier");
        end

        function region = build_CircularArc(obj, node)
            pts = obj.session.gds_integer(node.sampled_points(), "CircularArc points");
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
            if isa(val, 'Vertices')
                v = val.value;
            else
                v = val;
            end
        end

        function v = scalar_value(~, val)
            if isa(val, 'Parameter')
                v = val.value;
                return;
            end
            if isobject(val) && ismethod(val, 'value')
                v = val.value();
                return;
            end
            v = val;
        end

        function region = apply_translate(obj, region, dx, dy)
            t = obj.modeler.pya.Trans(obj.modeler.pya.Point(dx, dy));
            region = region.transformed(t);
        end

        function vec = gds_length_vector(obj, val, context)
            vec = obj.vector_value(val);
            vec = obj.session.gds_integer(vec, context);
        end

        function s = gds_length_scalar(obj, val, context)
            s = obj.scalar_value(val);
            s = obj.session.gds_integer(s, context);
        end

        function n = copy_count(obj, val, context)
            n = obj.scalar_value(val);
            n = obj.session.gds_integer(n, context);
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
            poly = obj.modeler.pya.Polygon.from_s(Utilities.vertices_to_klayout_string(pts));
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
                case 'LineSegment'
                    context = "Thicken(LineSegment)";
                    pts = obj.session.gds_integer(target.points_value(), context + " points");
                    is_curve = true;
                case 'InterpolationCurve'
                    if lower(string(target.type)) == "open"
                        context = "Thicken(InterpolationCurve)";
                        pts = obj.session.gds_integer(target.points_value(), context + " points");
                        is_curve = true;
                    end
                case 'QuadraticBezier'
                    if lower(string(target.type)) == "open"
                        context = "Thicken(QuadraticBezier)";
                        pts = obj.session.gds_integer(target.sampled_points(), context + " points");
                        is_curve = true;
                    end
                case 'CubicBezier'
                    if lower(string(target.type)) == "open"
                        context = "Thicken(CubicBezier)";
                        pts = obj.session.gds_integer(target.sampled_points(), context + " points");
                        is_curve = true;
                    end
                case 'CircularArc'
                    if lower(string(target.type)) == "open"
                        context = "Thicken(CircularArc)";
                        pts = obj.session.gds_integer(target.sampled_points(), context + " points");
                        is_curve = true;
                    end
                case 'ParametricCurve'
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
    end
end

function v = ThickenNormalizeVector(v)
% Return normalized 2D vector; leave zero vectors unchanged.
n = norm(v);
if n > 0
    v = v ./ n;
end
end
