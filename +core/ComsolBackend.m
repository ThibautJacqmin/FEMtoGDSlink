classdef ComsolBackend < handle
    % COMSOL backend for emitting feature graph into a COMSOL model.
    properties
        % Owning geometry session with layers, nodes, and modeler handles.
        session
        % Active COMSOL modeler adapter (LiveLink or MPh proxy).
        modeler
        % Dictionary of already-defined COMSOL parameters by name.
        defined_params
        % Dictionary: graph node id -> emitted COMSOL feature tag.
        feature_tags
        % Dictionary for in-flight emission cycle detection.
        emitting
        % Dictionary: workplane|selection_name -> cumulative selection tag.
        selection_tags
        % Cache mapping raw length tokens to snapped COMSOL expression names.
        snapped_length_tokens
        % Usage count per source input node id (for copy-on-consume logic).
        input_use_counts
        % Remaining usage count per source input node id during one emit pass.
        input_remaining_counts
    end
    methods
        function obj = ComsolBackend(session)
            % Initialize a COMSOL emitter bound to one core.GeometrySession.
            obj.session = session;
            obj.modeler = session.comsol;
            obj.defined_params = dictionary(string.empty(0,1), false(0,1));
            obj.feature_tags = dictionary(int32.empty(0,1), strings(0,1));
            obj.emitting = dictionary(int32.empty(0,1), false(0,1));
            obj.selection_tags = dictionary(string.empty(0,1), strings(0,1));
            obj.snapped_length_tokens = dictionary(string.empty(0,1), strings(0,1));
            obj.input_use_counts = dictionary(int32.empty(0,1), int32.empty(0,1));
            obj.input_remaining_counts = dictionary(int32.empty(0,1), int32.empty(0,1));
        end

        function emit_all(obj, nodes)
            % Emit all provided nodes; dependencies emit recursively.
            obj.prepare_input_usage_counts();
            for i = 1:numel(nodes)
                obj.tag_for(nodes{i});
            end
        end

        function p_out = register_parameter(obj, p, args)
            % Register one standalone Parameter in COMSOL parameter table.
            arguments
                obj
                p types.Parameter
                args.name {mustBeTextScalar} = ""
            end

            name_override = string(args.name);
            if strlength(name_override) > 0
                p = types.Parameter(p, name_override, ...
                    unit=p.unit, expression=p.expr, auto_register=false);
            end
            if ~p.is_named()
                error("ComsolBackend:UnnamedParameter", ...
                    "register_parameter requires a named Parameter or name override.");
            end

            obj.define_parameter_dependencies(p);
            obj.define_parameter(p);
            p_out = p;
        end

        function emit(obj, node)
            % Dispatch emission based on node class name.
            method = "emit_" + obj.class_short_name(node);
            if ismethod(obj, method)
                obj.(method)(node);
            else
                error("No COMSOL emitter for feature '" + class(node) + "'.");
            end
        end

        function tag = tag_for(obj, node)
            % Return or create the COMSOL tag associated with a graph node.
            id = int32(node.id);
            if isKey(obj.feature_tags, id)
                tag = obj.feature_tags(id);
                return;
            end
            if isa(node.layer, 'core.LayerSpec') && ~node.layer.comsol_emit
                error("Layer '%s' is not configured for COMSOL emission (no comsol_workplane), cannot emit '%s'.", ...
                    char(string(node.layer.name)), char(string(class(node))));
            end
            if isKey(obj.emitting, id)
                error("Cycle detected while emitting COMSOL feature graph.");
            end
            obj.emitting(id) = true;
            obj.emit(node);
            tag = obj.feature_tags(id);
            obj.build_selected(node, tag);
            obj.emitting = remove(obj.emitting, id);
            tag = obj.feature_tags(id);
        end

        function build_selected(obj, node, tag)
            % Build one emitted feature immediately (COMSOL "Build Selected").
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            geom2d = wp.geom;
            tag_char = char(string(tag));

            try
                geom2d.run(tag_char);
                return;
            catch run_tag_err
            end

            run_pre_msg = "none";
            try
                % runPre builds prerequisites only; follow with run(tag).
                geom2d.runPre(tag_char);
            catch ex
                run_pre_msg = string(ex.message);
            end

            try
                geom2d.run(tag_char);
                return;
            catch ex
                run_tag_after_pre_msg = string(ex.message);
            end

            try
                geom2d.run();
                return;
            catch run_all_err
                if ~exist('run_tag_after_pre_msg', 'var')
                    run_tag_after_pre_msg = "none";
                end
                msg = sprintf([ ...
                    'Failed to build selected COMSOL feature ''%s''. run(tag) error: %s. ' ...
                    'runPre(tag) error: %s. run(tag) after runPre error: %s. run() error: %s.'], ...
                    tag_char, ...
                    char(string(run_tag_err.message)), ...
                    char(run_pre_msg), ...
                    char(run_tag_after_pre_msg), ...
                    char(string(run_all_err.message)));
                error("femtogds:ComsolBuildSelectedFailed", "%s", msg);
            end
        end

        function emit_Rectangle(obj, node)
            % Emit a COMSOL Rectangle primitive from a Rectangle node.
            [layer, feature, tag] = obj.start_feature(node, "rect", "Rectangle");
            feature.set('base', char(node.base));
            pos = obj.length_vector(node.position, "Rectangle position");
            obj.set_pair(feature, 'pos', pos(1), pos(2));

            w = obj.length_component(node.width, "Rectangle width");
            h = obj.length_component(node.height, "Rectangle height");
            obj.set_pair(feature, 'size', w, h);
            try
                obj.set_scalar(feature, 'rot', obj.raw_component(node.angle));
            catch
                % Rotation is optional in COMSOL primitive API; ignore if unsupported.
            end
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Square(obj, node)
            % Emit a COMSOL Square primitive, with Rectangle fallback.
            [layer, feature, tag] = obj.start_feature_with_fallback( ...
                node, "squ", ["Square", "Rectangle"], "Square");
            feature.set('base', char(node.base));
            pos = obj.length_vector(node.position, "Square position");
            obj.set_pair(feature, 'pos', pos(1), pos(2));

            s = obj.length_component(node.side, "Square side");
            try
                obj.set_scalar(feature, 'size', s);
            catch
                % Older APIs may map square to rectangle-like size pair.
                obj.set_pair(feature, 'size', s, s);
            end
            try
                obj.set_scalar(feature, 'rot', obj.raw_component(node.angle));
            catch
                % Rotation is optional in COMSOL primitive API; ignore if unsupported.
            end
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Circle(obj, node)
            % Emit a COMSOL Circle primitive from a Circle node.
            [layer, feature, tag] = obj.start_feature(node, "cir", "Circle");
            feature.set('base', char(node.base));
            pos = obj.length_vector(node.position, "Circle position");
            obj.set_pair(feature, 'pos', pos(1), pos(2));
            obj.set_scalar(feature, 'r', obj.length_component(node.radius, "Circle radius"));
            obj.set_scalar(feature, 'angle', obj.raw_component(node.angle));
            obj.set_scalar(feature, 'rot', obj.raw_component(node.rotation));
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Ellipse(obj, node)
            % Emit a COMSOL Ellipse primitive from an Ellipse node.
            [layer, feature, tag] = obj.start_feature(node, "ell", "Ellipse");
            feature.set('base', char(node.base));
            pos = obj.length_vector(node.position, "Ellipse position");
            obj.set_pair(feature, 'pos', pos(1), pos(2));
            a_val = obj.length_component(node.a, "Ellipse semiaxis a");
            b_val = obj.length_component(node.b, "Ellipse semiaxis b");
            obj.set_pair(feature, 'semiaxes', a_val, b_val);
            obj.set_scalar(feature, 'rot', obj.raw_component(node.angle));
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Point(obj, node)
            % Emit one or several COMSOL Point coordinates.
            [layer, feature, tag] = obj.start_feature(node, "pt", "Point");
            pts = obj.session.snap_length(node.p_value(), "Point coordinates");
            feature.set('p', pts);
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_LineSegment(obj, node)
            % Emit a COMSOL LineSegment using coordinate endpoints.
            [layer, feature, tag] = obj.start_feature(node, "ls", "LineSegment");
            feature.set('specify1', 'coord');
            feature.set('specify2', 'coord');
            p1 = obj.length_vector(node.p1, "LineSegment p1");
            p2 = obj.length_vector(node.p2, "LineSegment p2");
            obj.set_pair(feature, 'coord1', p1(1), p1(2));
            obj.set_pair(feature, 'coord2', p2(1), p2(2));
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_InterpolationCurve(obj, node)
            % Emit InterpolationCurve. For open curves, emit a piecewise-linear
            % Polygon(type=open) so COMSOL thickening matches KLayout polyline behavior.
            mode = lower(string(node.type));
            if mode == "open"
                [layer, feature, tag] = obj.start_feature(node, "ic", "Polygon");
                try
                    feature.set('type', 'open');
                catch
                end

                pts_obj = node.points;
                if isa(pts_obj, 'types.Vertices')
                    [xvals, yvals] = obj.polygon_components(pts_obj, ...
                        "InterpolationCurve points");
                else
                    pts = obj.session.snap_length(node.points_value(), ...
                        "InterpolationCurve points");
                    n = size(pts, 1);
                    xvals = cell(1, n);
                    yvals = cell(1, n);
                    for i = 1:n
                        xvals{i} = obj.to_comsol_token(pts(i, 1));
                        yvals{i} = obj.to_comsol_token(pts(i, 2));
                    end
                end

                try
                    feature.set('source', 'vectors');
                catch
                end
                feature.set('x', xvals);
                feature.set('y', yvals);
                obj.finish_feature(node, layer, feature, tag);
                return;
            end

            % Closed/solid modes keep native COMSOL InterpolationCurve semantics.
            [layer, feature, tag] = obj.start_feature(node, "ic", "InterpolationCurve");
            set_from_vectors = false;
            pts_obj = node.points;
            if isa(pts_obj, 'types.Vertices')
                [xvals, yvals] = obj.polygon_components(pts_obj, ...
                    "InterpolationCurve points");
                try
                    feature.set('source', 'vectors');
                catch
                end
                try
                    feature.set('x', xvals);
                    feature.set('y', yvals);
                    set_from_vectors = true;
                catch
                    set_from_vectors = false;
                end
            end

            if ~set_from_vectors
                pts = obj.session.snap_length(node.points_value(), "InterpolationCurve table");
                feature.set('table', pts);
            end
            feature.set('type', char(node.type));
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_QuadraticBezier(obj, node)
            % Emit a COMSOL quadratic Bezier as a one-segment BezierPolygon.
            [layer, feature, tag] = obj.start_feature(node, "bez", "BezierPolygon");
            ctrl = obj.session.snap_length(node.control_points_value(), ...
                "QuadraticBezier control points");
            feature.set('degree', int32(2));
            feature.set('p', [ctrl(:, 1).'; ctrl(:, 2).']);
            feature.set('type', char(node.type));
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_CubicBezier(obj, node)
            % Emit a COMSOL cubic Bezier as a one-segment BezierPolygon.
            [layer, feature, tag] = obj.start_feature(node, "bez", "BezierPolygon");
            ctrl = obj.session.snap_length(node.control_points_value(), ...
                "CubicBezier control points");
            feature.set('degree', int32(3));
            feature.set('p', [ctrl(:, 1).'; ctrl(:, 2).']);
            feature.set('type', char(node.type));
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_CircularArc(obj, node)
            % Emit a CircularArc as rational quadratic BezierPolygon segments.
            [layer, feature, tag] = obj.start_feature(node, "bez", "BezierPolygon");
            [ctrl, degree, weights] = node.bezier_segments();
            ctrl = obj.session.snap_length(ctrl, "CircularArc control points");
            feature.set('degree', int32(degree));
            feature.set('p', [ctrl(:, 1).'; ctrl(:, 2).']);
            feature.set('w', weights);
            feature.set('type', char(node.type));
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_ParametricCurve(obj, node)
            % Emit a COMSOL ParametricCurve primitive.
            [layer, feature, tag] = obj.start_feature(node, "pc", "ParametricCurve");
            feature.set('parname', char(node.parname));
            obj.set_scalar(feature, 'parmin', obj.raw_component(node.parmin));
            obj.set_scalar(feature, 'parmax', obj.raw_component(node.parmax));
            coord = node.coord_strings();
            feature.set('coord', {char(coord(1)), char(coord(2))});
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Polygon(obj, node)
            % Emit a COMSOL Polygon primitive from a Polygon node.
            [layer, feature, tag] = obj.start_feature(node, "pol", "Polygon");

            verts = node.vertices;
            if isempty(verts) || verts.nvertices < 3
                error("Polygon requires at least 3 vertices.");
            end

            [xvals, yvals] = obj.polygon_components(verts, "Polygon vertices");
            feature.set('x', xvals);
            feature.set('y', yvals);
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Move(obj, node)
            % Emit a COMSOL Move operation.
            keep_input = core.GeometrySession.node_keeps_inputs(node);
            [layer, feature, tag, ~] = obj.start_unary_feature(node, "mov", "Move", keep_input);
            delta = obj.length_vector(node.delta, "Move delta");
            obj.set_scalar(feature, 'displx', delta(1));
            obj.set_scalar(feature, 'disply', delta(2));
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Rotate(obj, node)
            % Emit a COMSOL Rotate operation.
            keep_input = core.GeometrySession.node_keeps_inputs(node);
            [layer, feature, tag, ~] = obj.start_unary_feature(node, "rot", "Rotate", keep_input);
            obj.set_scalar(feature, 'rot', obj.raw_component(node.angle));
            origin = obj.length_vector(node.origin, "Rotate origin");
            obj.set_pair(feature, 'pos', origin(1), origin(2));
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Scale(obj, node)
            % Emit a COMSOL Scale operation.
            keep_input = core.GeometrySession.node_keeps_inputs(node);
            [layer, feature, tag, ~] = obj.start_unary_feature(node, "sca", "Scale", keep_input);
            obj.set_scalar(feature, 'factor', obj.raw_component(node.factor));
            origin = obj.length_vector(node.origin, "Scale origin");
            obj.set_pair(feature, 'pos', origin(1), origin(2));
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Mirror(obj, node)
            % Emit a COMSOL Mirror operation.
            keep_input = core.GeometrySession.node_keeps_inputs(node);
            [layer, feature, tag, ~] = obj.start_unary_feature(node, "mir", "Mirror", keep_input);
            point = obj.length_vector(node.point, "Mirror point");
            obj.set_pair(feature, 'pos', point(1), point(2));
            feature.set('axis', obj.vector_value(node.axis));
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Union(obj, node)
            % Emit a COMSOL Union operation.
            layer = node.layer;
            keep_input = core.GeometrySession.node_keeps_inputs(node);
            tags = strings(1, numel(node.inputs));
            for i = 1:numel(node.inputs)
                tags(i) = string(obj.resolve_input_tag(layer, node.inputs{i}, keep_input));
            end
            [layer, feature, tag] = obj.start_feature(node, "uni", "Union");
            obj.set_keep_input(feature, keep_input);

            feature.selection('input').set(tags);
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Difference(obj, node)
            % Emit a COMSOL Difference operation.
            layer = node.layer;
            keep_input = core.GeometrySession.node_keeps_inputs(node);
            base_tag = obj.resolve_input_tag(layer, node.base, keep_input);
            tool_tags = strings(1, numel(node.tools));
            for i = 1:numel(node.tools)
                tool_tags(i) = string(obj.resolve_input_tag(layer, node.tools{i}, keep_input));
            end
            [layer, feature, tag] = obj.start_feature(node, "dif", "Difference");
            obj.set_keep_input(feature, keep_input);

            feature.selection('input').set(base_tag);
            if ~isempty(tool_tags)
                feature.selection('input2').set(tool_tags);
            end
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Intersection(obj, node)
            % Emit a COMSOL Intersection operation.
            layer = node.layer;
            keep_input = core.GeometrySession.node_keeps_inputs(node);
            tags = strings(1, numel(node.inputs));
            for i = 1:numel(node.inputs)
                tags(i) = string(obj.resolve_input_tag(layer, node.inputs{i}, keep_input));
            end
            [layer, feature, tag] = obj.start_feature(node, "int", "Intersection");
            obj.set_keep_input(feature, keep_input);

            feature.selection('input').set(tags);
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Array1D(obj, node)
            % Emit a COMSOL 1D Array operation.
            layer = node.layer;
            keep_input = core.GeometrySession.node_keeps_inputs(node);
            source_tag = string(obj.tag_for(node.target));
            input_tag = obj.resolve_input_tag_from_source(layer, source_tag, int32(node.target.id), keep_input);
            [~, arr_feature, arr_tag] = obj.start_feature(node, "arr", "Array");
            obj.set_input_selection(arr_feature, input_tag);
            obj.set_keep_input(arr_feature, keep_input);
            n = obj.copy_count_token(node.ncopies, "Array1D ncopies");
            obj.set_scalar(arr_feature, 'size', n);
            disp_vec = obj.length_vector(node.delta, "Array1D delta");
            obj.set_pair(arr_feature, 'displ', disp_vec(1), disp_vec(2));

            unwanted = obj.array1d_unwanted_indices(node, n);
            if isempty(unwanted)
                obj.finish_feature(node, layer, arr_feature, arr_tag);
                return;
            end
            obj.finish_feature(node, layer, arr_feature, arr_tag);

            % COMSOL Delete in this workplane context is entity-based and does
            % not reliably accept array object tags (arr(i[,j])). Prune array
            % copies by subtracting a union of moved source clones instead.
            trim_source = obj.resolve_input_tag_from_source(layer, source_tag, int32(node.target.id), true);
            obj.finish_array_trim_difference_1d(node, layer, arr_tag, trim_source, disp_vec, unwanted);
        end

        function emit_Array2D(obj, node)
            % Emit a COMSOL 2D rectangular Array operation.
            layer = node.layer;
            keep_input = core.GeometrySession.node_keeps_inputs(node);
            source_tag = string(obj.tag_for(node.target));
            input_tag = obj.resolve_input_tag_from_source(layer, source_tag, int32(node.target.id), keep_input);
            [~, arr_feature, arr_tag] = obj.start_feature(node, "arr", "Array");
            obj.set_input_selection(arr_feature, input_tag);
            obj.set_keep_input(arr_feature, keep_input);
            nx = obj.copy_count_token(node.ncopies_x, "Array2D ncopies_x");
            ny = obj.copy_count_token(node.ncopies_y, "Array2D ncopies_y");
            obj.set_pair(arr_feature, 'size', nx, ny);

            disp_x = obj.length_vector(node.delta_x, "Array2D delta_x");
            disp_y = obj.length_vector(node.delta_y, "Array2D delta_y");
            if isnumeric(disp_x(2)) && abs(double(disp_x(2))) > 1e-12
                warning("Array2D delta_x y-component is ignored by COMSOL rectangular Array.");
            end
            if isnumeric(disp_y(1)) && abs(double(disp_y(1))) > 1e-12
                warning("Array2D delta_y x-component is ignored by COMSOL rectangular Array.");
            end
            % COMSOL rectangular Array displ is [dx, dy] along axis directions.
            obj.set_pair(arr_feature, 'displ', disp_x(1), disp_y(2));

            unwanted = obj.array2d_unwanted_indices(node, nx, ny);
            if isempty(unwanted)
                obj.finish_feature(node, layer, arr_feature, arr_tag);
                return;
            end
            obj.finish_feature(node, layer, arr_feature, arr_tag);

            % COMSOL Delete in this workplane context is entity-based and does
            % not reliably accept array object tags (arr(i[,j])). Prune array
            % copies by subtracting a union of moved source clones instead.
            trim_source = obj.resolve_input_tag_from_source(layer, source_tag, int32(node.target.id), true);
            obj.finish_array_trim_difference_2d(node, layer, arr_tag, trim_source, disp_x, disp_y, unwanted);
        end

        function emit_Fillet(obj, node)
            % Emit a COMSOL Fillet operation with explicit point selection.
            layer = node.layer;
            keep_input = core.GeometrySession.node_keeps_inputs(node);
            base_tag = obj.resolve_input_tag(layer, node.target, keep_input);
            [layer, feature, tag] = obj.start_feature(node, "fil", "Fillet");
            obj.set_keep_input(feature, keep_input);
            % Fillet input API differs across COMSOL versions/workplane contexts.
            try
                feature.selection('input').set(base_tag);
            catch
                % Some COMSOL versions only support selecting point entities
                % as feature input via selection('point').set(base_tag, ...).
            end
            obj.set_scalar(feature, 'radius', obj.length_component(node.radius, "Fillet radius"));
            points = node.points;
            if isempty(points) && isa(node.target, 'primitives.Rectangle')
                points = 1:4;
            end
            if ~isempty(points)
                if isa(points, 'types.Parameter')
                    points = points.value;
                end
                if isstring(points) || ischar(points)
                    mode = lower(string(points));
                    if mode == "all"
                        obj.select_all_fillet_points(feature, base_tag, node);
                    else
                        error("Unsupported fillet points mode '%s'. Use numeric indices or 'all'.", ...
                            char(mode));
                    end
                else
                    points = double(points);
                    points = points(:).';
                    points = round(points);
                    feature.selection('point').set(base_tag, points);
                end
            else
                obj.select_all_fillet_points(feature, base_tag, node);
            end
            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Chamfer(obj, node)
            % Emit a COMSOL Chamfer operation with explicit point selection.
            layer = node.layer;
            keep_input = core.GeometrySession.node_keeps_inputs(node);
            base_tag = obj.resolve_input_tag(layer, node.target, keep_input);
            [layer, feature, tag] = obj.start_feature(node, "cha", "Chamfer");
            obj.set_keep_input(feature, keep_input);
            try
                feature.selection('input').set(base_tag);
            catch
            end
            obj.set_scalar(feature, 'dist', obj.length_component(node.dist, "Chamfer distance"));

            points = node.points;
            if isempty(points) && isa(node.target, 'primitives.Rectangle')
                points = 1:4;
            end
            if ~isempty(points)
                if isa(points, 'types.Parameter')
                    points = points.value;
                end
                if isstring(points) || ischar(points)
                    mode = lower(string(points));
                    if mode == "all"
                        obj.select_all_fillet_points(feature, base_tag, node);
                    else
                        error("Unsupported chamfer points mode '%s'. Use numeric indices or 'all'.", ...
                            char(mode));
                    end
                else
                    points = double(points);
                    points = points(:).';
                    points = round(points);
                    feature.selection('point').set(base_tag, points);
                end
            else
                obj.select_all_fillet_points(feature, base_tag, node);
            end

            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Offset(obj, node)
            % Emit a COMSOL Offset operation.
            layer = node.layer;
            keep_input = core.GeometrySession.node_keeps_inputs(node);
            input_tag = obj.resolve_input_tag(layer, node.target, keep_input);
            [layer, feature, tag] = obj.start_feature_with_fallback( ...
                node, "off", ["Offset", "Offset2D"], "Offset");

            obj.set_keep_input(feature, keep_input);
            obj.set_input_selection(feature, input_tag);
            obj.set_scalar(feature, 'distance', obj.length_component(node.distance, "Offset distance"));
            try
                feature.set('reverse', obj.bool_token(node.reverse));
            catch
            end
            try
                feature.set('convexcorner', char(node.convexcorner));
            catch
            end
            try
                feature.set('trim', obj.bool_token(node.trim));
            catch
            end
            try
                feature.set('keep', obj.bool_token(keep_input));
            catch
            end

            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Tangent(obj, node)
            % Emit a COMSOL Tangent feature.
            layer = node.layer;
            keep_input = core.GeometrySession.node_keeps_inputs(node);
            edge_tag = obj.resolve_input_tag(layer, node.target, keep_input);
            if lower(string(node.type)) == "edge"
                if isempty(node.edge2)
                    error("Tangent type='edge' requires edge2.");
                end
                edge2_tag = obj.resolve_input_tag(layer, node.edge2, keep_input);
            else
                edge2_tag = "";
            end
            if lower(string(node.type)) == "point"
                if isempty(node.point_target)
                    error("Tangent type='point' requires point_target.");
                end
                point_tag = obj.resolve_input_tag(layer, node.point_target, keep_input);
            else
                point_tag = "";
            end
            [layer, feature, tag] = obj.start_feature(node, "tan", "Tangent");
            obj.set_keep_input(feature, keep_input);
            type = lower(string(node.type));
            feature.set('type', char(type));
            obj.set_scalar(feature, 'start', obj.raw_component(node.start));

            edge_index = obj.entity_index(node.edge_index, "Tangent edge index");
            feature.selection('edge').set(edge_tag, edge_index);

            if type == "edge"
                edge2_index = obj.entity_index(node.edge2_index, "Tangent edge2 index");
                feature.selection('edge2').set(edge2_tag, edge2_index);
                obj.set_scalar(feature, 'start2', obj.raw_component(node.start2));
            elseif type == "point"
                point_index = obj.entity_index(node.point_index, "Tangent point index");
                feature.selection('point').set(point_tag, point_index);
            else
                coord = obj.length_vector(node.coord, "Tangent coordinate");
                obj.set_pair(feature, 'coord', coord(1), coord(2));
            end

            obj.finish_feature(node, layer, feature, tag);
        end

        function emit_Thicken(obj, node)
            % Emit a COMSOL Thicken operation (2D) from a target curve/object.
            layer = node.layer;
            keep_input = core.GeometrySession.node_keeps_inputs(node);
            input_tag = obj.resolve_input_tag(layer, node.target, keep_input);
            [layer, feature, tag] = obj.start_feature_with_fallback( ...
                node, "thk", ["Thicken2D", "Thicken"], "Thicken");

            obj.set_keep_input(feature, keep_input);
            obj.set_input_selection(feature, input_tag);
            feature.set('offset', char(node.offset));

            mode = lower(string(node.offset));
            if mode == "symmetric"
                t = obj.length_component(node.totalthick, "Thicken total thickness");
                obj.set_scalar(feature, 'totalthick', t);
            else
                up = obj.length_component(node.upthick, "Thicken upper thickness");
                down = obj.length_component(node.downthick, "Thicken lower thickness");
                obj.set_scalar(feature, 'upthick', up);
                obj.set_scalar(feature, 'downthick', down);
            end

            try
                feature.set('ends', char(node.ends));
            catch
            end
            try
                feature.set('convexcorner', char(node.convexcorner));
            catch
            end
            try
                feature.set('keep', obj.bool_token(keep_input));
            catch
            end
            try
                feature.set('propagatesel', obj.bool_token(node.propagatesel));
            catch
            end

            obj.finish_feature(node, layer, feature, tag);
        end
    end
    methods (Access=private)
        function token = to_comsol_token(~, val)
            % Convert a MATLAB scalar/string into a COMSOL property token.
            if ischar(val)
                token = val;
            elseif isstring(val)
                token = char(val);
            else
                token = num2str(val);
            end
        end

        function token = bool_token(~, val)
            % Convert logical value to COMSOL on/off token.
            if logical(val)
                token = 'on';
            else
                token = 'off';
            end
        end

        function select_all_fillet_points(~, feature, base_tag, node)
            % Select all fillet/chamfer points with version-tolerant fallbacks.
            % Some COMSOL versions accept selection('point').set(objectTag),
            % others require selection('point').all(), and some accept a
            % property token for "all". For rectangles, explicit 1:4 remains
            % the most deterministic fallback.
            base = char(string(base_tag));
            tried = strings(0, 1);

            try
                feature.selection('point').set(base);
                return;
            catch ex
                tried(end+1, 1) = "selection('point').set(base): " + string(ex.message);
            end

            try
                feature.selection('point').all();
                return;
            catch ex
                tried(end+1, 1) = "selection('point').all(): " + string(ex.message);
            end

            try
                feature.set('point', 'all');
                return;
            catch ex
                tried(end+1, 1) = "feature.set('point','all'): " + string(ex.message);
            end

            if isa(node.target, 'primitives.Rectangle')
                try
                    feature.selection('point').set(base, 1:4);
                    return;
                catch ex
                    tried(end+1, 1) = "selection('point').set(base,1:4): " + string(ex.message);
                end
            end

            msg = "Could not select fillet/chamfer points='all' for input '" + string(base) + "'. " + ...
                strjoin(tried, " | ");
            error("femtogds:ComsolPointSelectionFailed", char(msg));
        end

        function define_parameter(obj, p)
            % Define a named types.Parameter once in COMSOL param table.
            if ~isa(p, 'types.Parameter') || ~p.is_named()
                return;
            end
            key = string(p.name);
            if isKey(obj.defined_params, key)
                return;
            end

            expr = string(p.expr);
            if strlength(expr) == 0 || expr == p.name
                unit = string(p.unit);
                if strlength(unit) ~= 0
                    val = string(p.value) + "[" + unit + "]";
                else
                    val = string(p.value);
                end
            else
                val = expr;
            end
            obj.modeler.model.param.set(p.name, val, "");
            obj.defined_params(key) = true;
        end

        function define_parameter_dependencies(obj, p)
            % Define all named dependencies carried by a types.Parameter object.
            if ~isa(p, 'types.Parameter')
                return;
            end
            records = p.dependency_records;
            for i = 1:numel(records)
                obj.define_parameter_record(records(i));
            end
        end

        function define_parameter_record(obj, rec)
            % Define one dependency record entry in COMSOL.
            name = string(rec.name);
            if strlength(name) == 0
                return;
            end

            key = string(name);
            if isKey(obj.defined_params, key)
                return;
            end

            expr = string(rec.expr);
            if strlength(expr) == 0 || expr == name
                unit = string(rec.unit);
                if strlength(unit) ~= 0
                    val = string(rec.value) + "[" + unit + "]";
                else
                    val = string(rec.value);
                end
            else
                val = expr;
            end

            obj.modeler.model.param.set(name, val, "");
            obj.defined_params(key) = true;
        end

        function [layer, feature, tag] = start_feature(obj, node, prefix, ftype)
            % Create a COMSOL feature with standard tag/workplane setup.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            tag = obj.session.next_comsol_tag(prefix);
            feature = wp.geom.create(tag, char(string(ftype)));
        end

        function [layer, feature, tag] = start_feature_with_fallback(obj, node, prefix, ftypes, context_name)
            % Create a COMSOL feature, trying multiple feature types in order.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            tag = obj.session.next_comsol_tag(prefix);

            msgs = strings(0, 1);
            for i = 1:numel(ftypes)
                ftype = string(ftypes(i));
                try
                    feature = wp.geom.create(tag, char(ftype));
                    return;
                catch ex
                    msgs(end+1, 1) = ftype + " error: " + string(ex.message); %#ok<AGROW>
                end
            end

            error("Failed to create COMSOL %s feature. %s", ...
                char(string(context_name)), char(strjoin(msgs, ". ")));
        end

        function [layer, feature, tag, input_tag] = start_unary_feature(obj, node, prefix, ftype, keep_input)
            % Create a unary operation feature and bind target input.
            layer = node.layer;
            input_tag = obj.resolve_input_tag(layer, node.target, keep_input);
            [layer, feature, tag] = obj.start_feature(node, prefix, ftype);
            obj.set_input_selection(feature, input_tag);
            obj.set_keep_input(feature, keep_input);
        end

        function finish_feature(obj, node, layer, feature, tag)
            % Apply layer selection and register feature tag for node.
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function set_pair(obj, feature, prop_name, v1, v2)
            % Set a two-component COMSOL property from numeric or tokens.
            if isnumeric(v1) && isnumeric(v2)
                feature.set(prop_name, [v1, v2]);
            else
                feature.set(prop_name, {obj.to_comsol_token(v1), obj.to_comsol_token(v2)});
            end
        end

        function set_scalar(obj, feature, prop_name, value)
            % Set a scalar COMSOL property from numeric or token value.
            if isnumeric(value)
                feature.set(prop_name, value);
            else
                feature.set(prop_name, obj.to_comsol_token(value));
            end
        end

        function set_input_selection(~, feature, tags)
            % Set input feature selection and fail loudly if nothing was applied.
            tok = string(tags);
            tok = tok(:).';
            tok = tok(strlength(tok) > 0);
            if isempty(tok)
                error("femtogds:ComsolInputSelectionFailed", ...
                    "Could not set COMSOL feature input selection: empty input tag list.");
            end
            many = cellstr(tok);
            ok = false;
            last_err = [];

            try
                feature.selection('input').set(tok);
                ok = true;
            catch ex
                last_err = ex;
            end
            if ok
                return;
            end

            try
                feature.selection('input').set(many);
                ok = true;
            catch ex
                last_err = ex;
            end
            if ok
                return;
            end

            if isscalar(many)
                one = many{1};
                one_str = tok(1);
                try
                    feature.selection('input').set(one_str);
                    ok = true;
                catch ex
                    last_err = ex;
                end
                if ok
                    return;
                end

                try
                    feature.selection('input').set(one);
                    ok = true;
                catch ex
                    last_err = ex;
                end
                if ok
                    return;
                end

            end

            if isempty(last_err)
                error("femtogds:ComsolInputSelectionFailed", ...
                    "Could not set COMSOL feature input selection.");
            else
                error("femtogds:ComsolInputSelectionFailed", ...
                    "Could not set COMSOL feature input selection: %s", ...
                    char(string(last_err.message)));
            end
        end

        function token = vector_token(obj, x, y)
            % Convert two components into COMSOL "x,y" token syntax.
            token = obj.to_comsol_token(x) + "," + obj.to_comsol_token(y);
        end

        function [xvals, yvals] = polygon_components(obj, verts, context)
            % Build COMSOL-ready x/y component token lists for Polygon.
            if isa(verts.prefactor, 'types.Parameter')
                obj.parameter_token(verts.prefactor);
            end

            xexpr = string(verts.comsol_string_x());
            yexpr = string(verts.comsol_string_y());
            if numel(xexpr) ~= numel(yexpr)
                error("Polygon x/y coordinate component counts must match.");
            end

            n = numel(xexpr);
            xvals = cell(1, n);
            yvals = cell(1, n);
            for i = 1:n
                x = obj.length_component(xexpr(i), string(context) + " x");
                y = obj.length_component(yexpr(i), string(context) + " y");
                xvals{i} = obj.to_comsol_token(x);
                yvals{i} = obj.to_comsol_token(y);
            end
        end

        function set_keep_input(obj, feature, keep_input)
            % Best effort: set COMSOL keep-input-style flags to on/off.
            token = obj.bool_token(keep_input);
            raw = logical(keep_input);
            props = ["keepinput", "keep", "keepinput2", "keeptool", "keepadd", "keepsubtract"];
            for i = 1:numel(props)
                prop = char(props(i));
                try
                    feature.set(prop, token);
                    continue;
                catch
                end
                try
                    feature.set(prop, raw);
                catch
                end
            end
        end

        function out = raw_component(obj, val)
            % Convert wrapper objects into raw numeric/token payloads.
            if isa(val, 'types.Parameter')
                out = obj.parameter_token(val);
                return;
            end
            if isobject(val) && ismethod(val, 'value')
                out = val.value();
                return;
            end
            if isobject(val) && isprop(val, 'name')
                out = char(val.name);
                return;
            end
            out = val;
        end

        function out = length_component(obj, val, context)
            % Resolve and optionally snap one length component.
            raw = obj.raw_component(val);
            if isnumeric(raw)
                out = obj.session.snap_length(raw, context);
                return;
            end
            if obj.session.snap_on_grid
                out = obj.snapped_length_token(raw);
            else
                out = raw;
            end
        end

        function out = copy_count_token(obj, val, context)
            % Resolve and validate copy count token for COMSOL Array features.
            raw = obj.raw_component(val);
            if isnumeric(raw)
                n = round(double(raw));
                if ~(isscalar(n) && isfinite(n) && n >= 1)
                    error("%s must be a scalar >= 1.", char(string(context)));
                end
                out = n;
                return;
            end
            out = raw;
        end

        function idx = array1d_unwanted_indices(~, node, n)
            idx = node.unwanted_indices;
            if isempty(idx)
                idx = zeros(1, 0);
                return;
            end
            idx = round(double(idx(:).'));
            if any(~isfinite(idx)) || any(idx < 1)
                error("Array1D unwanted_indices must contain finite integers >= 1.");
            end
            if isnumeric(n)
                nmax = round(double(n));
                if any(idx > nmax)
                    error("Array1D unwanted_indices must be within [1, %d].", nmax);
                end
            end
            idx = unique(idx, "stable");
        end

        function pairs = array2d_unwanted_indices(~, node, nx, ny)
            pairs = node.unwanted_array_elements;
            if isempty(pairs)
                pairs = zeros(0, 2);
                return;
            end
            pairs = round(double(pairs));
            if size(pairs, 2) ~= 2
                error("Array2D unwanted_array_elements must be Nx2.");
            end
            if any(~isfinite(pairs), "all") || any(pairs(:) < 1)
                error("Array2D unwanted_array_elements must contain finite integers >= 1.");
            end
            if isnumeric(nx)
                nxn = round(double(nx));
                if any(pairs(:, 1) > nxn)
                    error("Array2D unwanted_array_elements ix must be within [1, %d].", nxn);
                end
            end
            if isnumeric(ny)
                nyn = round(double(ny));
                if any(pairs(:, 2) > nyn)
                    error("Array2D unwanted_array_elements iy must be within [1, %d].", nyn);
                end
            end
            pairs = unique(pairs, "rows", "stable");
        end

        function finish_array_trim_difference_1d(obj, node, layer, arr_tag, trim_source_tag, disp_vec, unwanted)
            move_tags = strings(1, numel(unwanted));
            for i = 1:numel(unwanted)
                k = double(unwanted(i) - 1);
                dx = obj.scale_component(disp_vec(1), k);
                dy = obj.scale_component(disp_vec(2), k);
                [~, mv, mv_tag] = obj.start_feature(node, "mov", "Move");
                obj.set_input_selection(mv, trim_source_tag);
                obj.set_keep_input(mv, true);
                obj.set_pair(mv, 'displ', dx, dy);
                obj.finish_feature(node, layer, mv, mv_tag);
                move_tags(i) = string(mv_tag);
            end
            obj.finish_array_trim_difference_common(node, layer, arr_tag, move_tags);
        end

        function finish_array_trim_difference_2d(obj, node, layer, arr_tag, trim_source_tag, disp_x, disp_y, unwanted)
            move_tags = strings(1, size(unwanted, 1));
            for i = 1:size(unwanted, 1)
                kx = double(unwanted(i, 1) - 1);
                ky = double(unwanted(i, 2) - 1);
                dx = obj.sum_components( ...
                    obj.scale_component(disp_x(1), kx), ...
                    obj.scale_component(disp_y(1), ky));
                dy = obj.sum_components( ...
                    obj.scale_component(disp_x(2), kx), ...
                    obj.scale_component(disp_y(2), ky));

                [~, mv, mv_tag] = obj.start_feature(node, "mov", "Move");
                obj.set_input_selection(mv, trim_source_tag);
                obj.set_keep_input(mv, true);
                obj.set_pair(mv, 'displ', dx, dy);
                obj.finish_feature(node, layer, mv, mv_tag);
                move_tags(i) = string(mv_tag);
            end
            obj.finish_array_trim_difference_common(node, layer, arr_tag, move_tags);
        end

        function finish_array_trim_difference_common(obj, node, layer, arr_tag, move_tags)
            if isempty(move_tags)
                return;
            end
            if numel(move_tags) == 1
                tool_tag = string(move_tags(1));
            else
                [~, uni, uni_tag] = obj.start_feature(node, "uni", "Union");
                obj.set_keep_input(uni, false);
                obj.set_input_selection(uni, move_tags);
                obj.finish_feature(node, layer, uni, uni_tag);
                tool_tag = string(uni_tag);
            end

            [~, dif, dif_tag] = obj.start_feature(node, "dif", "Difference");
            obj.set_keep_input(dif, false);
            obj.set_input_selection(dif, arr_tag);
            dif.selection('input2').set(tool_tag);
            obj.finish_feature(node, layer, dif, dif_tag);
        end

        function out = scale_component(~, val, factor)
            f = round(double(factor));
            if f == 0
                out = 0;
                return;
            end
            if isnumeric(val)
                out = f * double(val);
                return;
            end
            if f == 1
                out = val;
            else
                out = "(" + string(f) + ")*(" + string(val) + ")";
            end
        end

        function out = sum_components(~, a, b)
            if isnumeric(a) && isnumeric(b)
                out = double(a) + double(b);
                return;
            end
            if isnumeric(a) && abs(double(a)) <= 1e-15
                out = b;
                return;
            end
            if isnumeric(b) && abs(double(b)) <= 1e-15
                out = a;
                return;
            end
            out = "(" + string(a) + ")+(" + string(b) + ")";
        end

        function idx = entity_index(obj, val, context)
            % Resolve and validate integer entity index for COMSOL selections.
            raw = obj.raw_component(val);
            if ~isnumeric(raw)
                error("%s must be numeric.", char(string(context)));
            end
            idx = round(double(raw));
            if ~(isscalar(idx) && isfinite(idx) && idx >= 1)
                error("%s must be a scalar integer >= 1.", char(string(context)));
            end
        end

        function vec = vector_value(~, val)
            % Extract numeric vector from types.Vertices or raw vector.
            if isa(val, 'types.Vertices')
                vec = val.value;
            else
                vec = val;
            end
        end

        function vec = vector_components(~, x, y)
            % Build a 2-component vector without char-token concatenation.
            if isnumeric(x) && isnumeric(y)
                vec = [x, y];
                return;
            end
            vec = strings(1, 2);
            vec(1) = string(x);
            vec(2) = string(y);
        end

        function vec = length_vector(obj, val, context)
            % Resolve and optionally snap a 2D length vector.
            if isa(val, 'types.Vertices')
                if val.nvertices ~= 1
                    error("Length vectors must resolve to a single [x y] pair.");
                end
                if isa(val.prefactor, 'types.Parameter')
                    obj.parameter_token(val.prefactor);
                end
                xexpr = string(val.comsol_string_x());
                yexpr = string(val.comsol_string_y());
                x = obj.length_component(xexpr(1), string(context) + " x");
                y = obj.length_component(yexpr(1), string(context) + " y");
                vec = obj.vector_components(x, y);
                return;
            else
                vec = val;
            end

            if isnumeric(vec)
                vec = obj.session.snap_length(vec, context);
                return;
            end

            tok = string(vec);
            if numel(tok) ~= 2
                error("Length vectors must resolve to exactly two components.");
            end
            x = obj.length_component(tok(1), string(context) + " x");
            y = obj.length_component(tok(2), string(context) + " y");
            vec = obj.vector_components(x, y);
        end

        function token = parameter_token(obj, p)
            % Convert types.Parameter to COMSOL token and register dependencies.
            obj.define_parameter_dependencies(p);
            if p.is_named()
                obj.define_parameter(p);
                token = char(p.name);
                return;
            end
            expr = string(p.expr);
            if strlength(expr) == 0
                token = p.value;
                return;
            end
            num = str2double(expr);
            if ~isnan(num)
                token = num;
            else
                token = char(expr);
            end
        end

        function token = snapped_length_token(obj, raw_token)
            % Create/reuse a named snapped expression parameter (snp*).
            key = string(raw_token) + "|" + string(obj.session.gds_resolution_nm);
            if isKey(obj.snapped_length_tokens, key)
                token = obj.snapped_length_tokens(key);
                return;
            end

            token = char(obj.session.next_comsol_tag("snp"));
            grid_expr = string(obj.session.gds_resolution_nm) + "[nm]";
            snap_expr = "round((" + string(raw_token) + ")/(" + grid_expr + "))*(" + grid_expr + ")";
            obj.modeler.model.param.set(token, snap_expr, "");
            obj.snapped_length_tokens(key) = string(token);
            if obj.session.warn_on_snap
                snap_msg = "Created snapped COMSOL expression '" + string(token) + ...
                    "' from '" + string(raw_token) + "'.";
                warning(char(snap_msg));
            end
        end
        function name = class_short_name(~, obj_or_node)
            % Return unqualified class name from a potentially packaged class.
            cname = string(class(obj_or_node));
            parts = split(cname, ".");
            name = parts(end);
        end

        function prepare_input_usage_counts(obj)
            % Count how many times each graph node is used as downstream input.
            counts = dictionary(int32.empty(0,1), int32.empty(0,1));
            nodes = obj.session.nodes;
            for i = 1:numel(nodes)
                node = nodes{i};
                if isa(node.layer, 'core.LayerSpec') && ~node.layer.comsol_emit
                    continue;
                end
                for j = 1:numel(node.inputs)
                    in = node.inputs{j};
                    if ~isa(in, 'core.GeomFeature') || isempty(in.id)
                        continue;
                    end
                    id = int32(in.id);
                    if isKey(counts, id)
                        counts(id) = counts(id) + 1;
                    else
                        counts(id) = int32(1);
                    end
                end
            end
            obj.input_use_counts = counts;
            obj.input_remaining_counts = counts;
        end

        function input_tag = resolve_input_tag(obj, layer, input_node, keep_input)
            % Resolve one input tag, inserting copy only when needed.
            source_tag = string(obj.tag_for(input_node));
            input_tag = obj.resolve_input_tag_from_source(layer, source_tag, int32(input_node.id), keep_input);
        end

        function input_tag = resolve_input_tag_from_source(obj, layer, source_tag, source_id, keep_input)
            % Resolve one input tag from source tag/id with keep-input semantics.
            source = string(source_tag);
            if strlength(source) == 0
                error("Cannot resolve COMSOL input selection from empty source tag.");
            end

            if numel(keys(obj.input_remaining_counts)) == 0
                obj.prepare_input_usage_counts();
            end

            remaining = int32(1);
            if isKey(obj.input_remaining_counts, source_id)
                remaining = obj.input_remaining_counts(source_id);
            end

            if keep_input
                input_tag = source;
            else
                if remaining > 1
                    input_tag = string(obj.copy_input_tag(layer, source));
                else
                    input_tag = source;
                end
            end

            obj.decrement_input_remaining(source_id, remaining);
        end

        function decrement_input_remaining(obj, source_id, current_remaining)
            % Consume one pending input use count for one source node id.
            if ~isKey(obj.input_remaining_counts, source_id)
                return;
            end
            remaining = int32(current_remaining) - 1;
            if remaining <= 0
                obj.input_remaining_counts = remove(obj.input_remaining_counts, source_id);
            else
                obj.input_remaining_counts(source_id) = remaining;
            end
        end

        function copied_tag = copy_input_tag(obj, layer, source_tag)
            % Clone one source object tag through a COMSOL Copy feature.
            source = string(source_tag);
            if strlength(source) == 0
                error("Cannot copy empty COMSOL input tag.");
            end
            wp = obj.session.get_workplane(layer);
            copied_tag = obj.session.next_comsol_tag("cpy");
            copy_feature = wp.geom.create(copied_tag, 'Copy');
            obj.set_input_selection(copy_feature, source);
            % In-place duplication keeps branch semantics without translation.
            obj.set_pair(copy_feature, 'displ', 0, 0);
            obj.set_keep_input(copy_feature, true);
            % Build the copy immediately so downstream input selections
            % resolve against existing geometry objects.
            try
                wp.geom.run(char(copied_tag));
            catch ex
                error("femtogds:ComsolCopyBuildFailed", ...
                    "Failed to build COMSOL copy feature '%s' from '%s': %s", ...
                    char(copied_tag), char(source), char(string(ex.message)));
            end
        end

        function apply_layer_selection(obj, layer, feature)
            % Attach generated geometry to configured cumulative selection.
            if ~layer.comsol_enable_selection
                return;
            end

            name = string(layer.comsol_selection);
            if strlength(name) == 0
                name = string(layer.name);
            end
            sel_tag = obj.selection_tag(layer, name);
            show_token = obj.selection_show_token(layer.comsol_selection_state);
            if show_token == "off"
                return;
            end

            try
                feature.set('selresult', true);
            catch
            end
            try
                feature.set('selresultshow', char(show_token));
            catch
            end
            try
                feature.set('contributeto', sel_tag);
            catch ex
                warning("Could not assign layer selection '%s': %s", ...
                    char(name), ex.message);
            end
        end

        function tag = selection_tag(obj, layer, name)
            % Create or retrieve cumulative selection tag for a layer.
            key = string(layer.comsol_workplane) + "|" + string(name);
            if isKey(obj.selection_tags, key)
                tag = char(obj.selection_tags(key));
                return;
            end

            tag = char(obj.session.next_comsol_tag("csel"));
            obj.selection_tags(key) = string(tag);

            wp = obj.session.get_workplane(layer);
            % Best-effort creation of a cumulative selection node in this workplane.
            try
                wp.geom.selection().create(tag, 'CumulativeSelection');
            catch
            end
            try
                wp.geom.selection(tag).label(char(name));
            catch
            end
        end

        function token = selection_show_token(~, state)
            % Map user-friendly selection state to COMSOL selresultshow token.
            s = lower(string(state));
            if s == "all"
                token = "all";
            elseif any(s == ["domain", "domains", "dom"])
                token = "dom";
            elseif any(s == ["boundary", "boundaries", "bnd"])
                token = "bnd";
            elseif any(s == ["edge", "edges", "edg"])
                token = "edg";
            elseif any(s == ["point", "points", "pnt"])
                token = "pnt";
            elseif any(s == ["off", "none"])
                token = "off";
            else
                error("Unknown selection_state '%s'.", char(s));
            end
        end
    end
end
