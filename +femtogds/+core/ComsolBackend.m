classdef ComsolBackend < handle
    % COMSOL backend for emitting feature graph into a COMSOL model.
    properties
        session
        modeler
        defined_params
        feature_tags
        emitting
        selection_tags
        snapped_length_tokens
    end
    methods
        function obj = ComsolBackend(session)
            % Initialize a COMSOL emitter bound to one femtogds.core.GeometrySession.
            obj.session = session;
            obj.modeler = session.comsol;
            obj.defined_params = dictionary(string.empty(0,1), false(0,1));
            obj.feature_tags = dictionary(int32.empty(0,1), strings(0,1));
            obj.emitting = dictionary(int32.empty(0,1), false(0,1));
            obj.selection_tags = dictionary(string.empty(0,1), strings(0,1));
            obj.snapped_length_tokens = dictionary(string.empty(0,1), strings(0,1));
        end

        function emit_all(obj, nodes)
            % Emit graph from output nodes only; dependencies emit recursively.
            for i = 1:numel(nodes)
                if nodes{i}.output
                    obj.tag_for(nodes{i});
                end
            end
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
            if isKey(obj.emitting, id)
                error("Cycle detected while emitting COMSOL feature graph.");
            end
            obj.emitting(id) = true;
            obj.emit(node);
            obj.emitting = remove(obj.emitting, id);
            tag = obj.feature_tags(id);
        end

        function emit_Rectangle(obj, node)
            % Emit a COMSOL Rectangle primitive from a Rectangle node.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);

            tag = obj.session.next_comsol_tag("rect");
            feature = wp.geom.create(tag, 'Rectangle');
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
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Circle(obj, node)
            % Emit a COMSOL Circle primitive from a Circle node.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);

            tag = obj.session.next_comsol_tag("cir");
            feature = wp.geom.create(tag, 'Circle');
            feature.set('base', char(node.base));
            pos = obj.length_vector(node.position, "Circle position");
            obj.set_pair(feature, 'pos', pos(1), pos(2));
            obj.set_scalar(feature, 'r', obj.length_component(node.radius, "Circle radius"));
            obj.set_scalar(feature, 'angle', obj.raw_component(node.angle));
            obj.set_scalar(feature, 'rot', obj.raw_component(node.rotation));
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Ellipse(obj, node)
            % Emit a COMSOL Ellipse primitive from an Ellipse node.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);

            tag = obj.session.next_comsol_tag("ell");
            feature = wp.geom.create(tag, 'Ellipse');
            feature.set('base', char(node.base));
            pos = obj.length_vector(node.position, "Ellipse position");
            obj.set_pair(feature, 'pos', pos(1), pos(2));
            a_val = obj.length_component(node.a, "Ellipse semiaxis a");
            b_val = obj.length_component(node.b, "Ellipse semiaxis b");
            obj.set_pair(feature, 'semiaxes', a_val, b_val);
            obj.set_scalar(feature, 'rot', obj.raw_component(node.angle));
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Point(obj, node)
            % Emit one or several COMSOL Point coordinates.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);

            tag = obj.session.next_comsol_tag("pt");
            feature = wp.geom.create(tag, 'Point');
            pts = obj.session.snap_length(node.p_value(), "Point coordinates");
            feature.set('p', pts);
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_LineSegment(obj, node)
            % Emit a COMSOL LineSegment using coordinate endpoints.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);

            tag = obj.session.next_comsol_tag("ls");
            feature = wp.geom.create(tag, 'LineSegment');
            feature.set('specify1', 'coord');
            feature.set('specify2', 'coord');
            p1 = obj.length_vector(node.p1, "LineSegment p1");
            p2 = obj.length_vector(node.p2, "LineSegment p2");
            obj.set_pair(feature, 'coord1', p1(1), p1(2));
            obj.set_pair(feature, 'coord2', p2(1), p2(2));
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_InterpolationCurve(obj, node)
            % Emit a COMSOL InterpolationCurve primitive.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);

            tag = obj.session.next_comsol_tag("ic");
            feature = wp.geom.create(tag, 'InterpolationCurve');
            pts = obj.session.snap_length(node.points_value(), "InterpolationCurve table");
            feature.set('table', pts);
            feature.set('type', char(node.type));
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_QuadraticBezier(obj, node)
            % Emit a COMSOL quadratic Bezier as a one-segment BezierPolygon.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);

            tag = obj.session.next_comsol_tag("bez");
            feature = wp.geom.create(tag, 'BezierPolygon');
            ctrl = obj.session.snap_length(node.control_points_value(), ...
                "QuadraticBezier control points");
            feature.set('degree', int32(2));
            feature.set('p', [ctrl(:, 1).'; ctrl(:, 2).']);
            feature.set('type', char(node.type));
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_CubicBezier(obj, node)
            % Emit a COMSOL cubic Bezier as a one-segment BezierPolygon.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);

            tag = obj.session.next_comsol_tag("bez");
            feature = wp.geom.create(tag, 'BezierPolygon');
            ctrl = obj.session.snap_length(node.control_points_value(), ...
                "CubicBezier control points");
            feature.set('degree', int32(3));
            feature.set('p', [ctrl(:, 1).'; ctrl(:, 2).']);
            feature.set('type', char(node.type));
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_CircularArc(obj, node)
            % Emit a CircularArc as rational quadratic BezierPolygon segments.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);

            tag = obj.session.next_comsol_tag("bez");
            feature = wp.geom.create(tag, 'BezierPolygon');
            [ctrl, degree, weights] = node.bezier_segments();
            ctrl = obj.session.snap_length(ctrl, "CircularArc control points");
            feature.set('degree', int32(degree));
            feature.set('p', [ctrl(:, 1).'; ctrl(:, 2).']);
            feature.set('w', weights);
            feature.set('type', char(node.type));
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_ParametricCurve(obj, node)
            % Emit a COMSOL ParametricCurve primitive.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);

            tag = obj.session.next_comsol_tag("pc");
            feature = wp.geom.create(tag, 'ParametricCurve');
            feature.set('parname', char(node.parname));
            obj.set_scalar(feature, 'parmin', obj.raw_component(node.parmin));
            obj.set_scalar(feature, 'parmax', obj.raw_component(node.parmax));
            coord = node.coord_strings();
            feature.set('coord', {char(coord(1)), char(coord(2))});
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Polygon(obj, node)
            % Emit a COMSOL Polygon primitive from a Polygon node.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);

            verts = node.vertices;
            if isempty(verts) || verts.nvertices < 3
                error("Polygon requires at least 3 vertices.");
            end

            tag = obj.session.next_comsol_tag("pol");
            feature = wp.geom.create(tag, 'Polygon');
            [xvals, yvals] = obj.polygon_components(verts, "Polygon vertices");
            feature.set('x', xvals);
            feature.set('y', yvals);
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Move(obj, node)
            % Emit a COMSOL Move operation.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            input_tag = obj.tag_for(node.target);

            tag = obj.session.next_comsol_tag("mov");
            feature = wp.geom.create(tag, 'Move');
            feature.selection('input').set(input_tag);
            delta = obj.length_vector(node.delta, "Move delta");
            obj.set_scalar(feature, 'displx', delta(1));
            obj.set_scalar(feature, 'disply', delta(2));
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Rotate(obj, node)
            % Emit a COMSOL Rotate operation.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            input_tag = obj.tag_for(node.target);

            tag = obj.session.next_comsol_tag("rot");
            feature = wp.geom.create(tag, 'Rotate');
            feature.selection('input').set(input_tag);
            obj.set_scalar(feature, 'rot', obj.raw_component(node.angle));
            origin = obj.length_vector(node.origin, "Rotate origin");
            obj.set_pair(feature, 'pos', origin(1), origin(2));
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Scale(obj, node)
            % Emit a COMSOL Scale operation.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            input_tag = obj.tag_for(node.target);

            tag = obj.session.next_comsol_tag("sca");
            feature = wp.geom.create(tag, 'Scale');
            feature.selection('input').set(input_tag);
            obj.set_scalar(feature, 'factor', obj.raw_component(node.factor));
            origin = obj.length_vector(node.origin, "Scale origin");
            obj.set_pair(feature, 'pos', origin(1), origin(2));
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Mirror(obj, node)
            % Emit a COMSOL Mirror operation.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            input_tag = obj.tag_for(node.target);

            tag = obj.session.next_comsol_tag("mir");
            feature = wp.geom.create(tag, 'Mirror');
            feature.selection('input').set(input_tag);
            point = obj.length_vector(node.point, "Mirror point");
            obj.set_pair(feature, 'pos', point(1), point(2));
            feature.set('axis', obj.vector_value(node.axis));
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Union(obj, node)
            % Emit a COMSOL Union operation.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            tags = obj.collect_tags(node.inputs);

            tag = obj.session.next_comsol_tag("uni");
            feature = wp.geom.create(tag, 'Union');
            feature.selection('input').set(tags);
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Difference(obj, node)
            % Emit a COMSOL Difference operation.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            base_tag = obj.tag_for(node.base);
            tool_tags = obj.collect_tags(node.tools);

            tag = obj.session.next_comsol_tag("dif");
            feature = wp.geom.create(tag, 'Difference');
            feature.selection('input').set(base_tag);
            if ~isempty(tool_tags)
                feature.selection('input2').set(tool_tags);
            end
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Intersection(obj, node)
            % Emit a COMSOL Intersection operation.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            tags = obj.collect_tags(node.inputs);

            tag = obj.session.next_comsol_tag("int");
            feature = wp.geom.create(tag, 'Intersection');
            feature.selection('input').set(tags);
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Array1D(obj, node)
            % Emit a COMSOL 1D Array operation.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            input_tag = obj.tag_for(node.target);

            tag = obj.session.next_comsol_tag("arr");
            feature = wp.geom.create(tag, 'Array');
            feature.set('type', 'linear');
            obj.enable_keep_input(feature);
            obj.set_scalar(feature, 'linearsize', obj.copy_count_token(node.ncopies, "Array1D ncopies"));
            disp_vec = obj.length_vector(node.delta, "Array1D delta");
            obj.set_scalar(feature, 'displ', obj.vector_token(disp_vec(1), disp_vec(2)));
            obj.set_input_selection(feature, input_tag);
            obj.set_input_selection(feature, input_tag);
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Array2D(obj, node)
            % Emit a COMSOL 2D array by chaining two linear arrays.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            input_tag = obj.tag_for(node.target);

            tag_x = obj.session.next_comsol_tag("arr");
            feature_x = wp.geom.create(tag_x, 'Array');
            feature_x.set('type', 'linear');
            obj.enable_keep_input(feature_x);
            obj.set_scalar(feature_x, 'linearsize', ...
                obj.copy_count_token(node.ncopies_x, "Array2D ncopies_x"));
            disp_x = obj.length_vector(node.delta_x, "Array2D delta_x");
            obj.set_scalar(feature_x, 'displ', obj.vector_token(disp_x(1), disp_x(2)));
            obj.set_input_selection(feature_x, input_tag);
            obj.set_input_selection(feature_x, input_tag);

            tag_y = obj.session.next_comsol_tag("arr");
            feature_y = wp.geom.create(tag_y, 'Array');
            feature_y.set('type', 'linear');
            obj.enable_keep_input(feature_y);
            obj.set_scalar(feature_y, 'linearsize', ...
                obj.copy_count_token(node.ncopies_y, "Array2D ncopies_y"));
            disp_y = obj.length_vector(node.delta_y, "Array2D delta_y");
            obj.set_scalar(feature_y, 'displ', obj.vector_token(disp_y(1), disp_y(2)));
            obj.set_input_selection(feature_y, tag_x);
            obj.set_input_selection(feature_y, tag_x);
            obj.apply_layer_selection(layer, feature_y);
            obj.feature_tags(int32(node.id)) = string(tag_y);
        end

        function emit_Fillet(obj, node)
            % Emit a COMSOL Fillet operation with explicit point selection.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            base_tag = obj.tag_for(node.target);

            tag = obj.session.next_comsol_tag("fil");
            feature = wp.geom.create(tag, 'Fillet');
            % Fillet input API differs across COMSOL versions/workplane contexts.
            try
                feature.selection('input').set(base_tag);
            catch
                % Some COMSOL versions only support selecting point entities
                % as feature input via selection('point').set(base_tag, ...).
            end
            obj.set_scalar(feature, 'radius', obj.length_component(node.radius, "Fillet radius"));
            points = node.points;
            if isempty(points) && isa(node.target, 'femtogds.primitives.Rectangle')
                points = 1:4;
            end
            if ~isempty(points)
                if isa(points, 'femtogds.types.Parameter')
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
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Chamfer(obj, node)
            % Emit a COMSOL Chamfer operation with explicit point selection.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            base_tag = obj.tag_for(node.target);

            tag = obj.session.next_comsol_tag("cha");
            feature = wp.geom.create(tag, 'Chamfer');
            try
                feature.selection('input').set(base_tag);
            catch
            end
            obj.set_scalar(feature, 'dist', obj.length_component(node.dist, "Chamfer distance"));

            points = node.points;
            if isempty(points) && isa(node.target, 'femtogds.primitives.Rectangle')
                points = 1:4;
            end
            if ~isempty(points)
                if isa(points, 'femtogds.types.Parameter')
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

            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Offset(obj, node)
            % Emit a COMSOL Offset operation.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            input_tag = obj.tag_for(node.target);

            tag = obj.session.next_comsol_tag("off");
            try
                feature = wp.geom.create(tag, 'Offset');
            catch first_err
                try
                    feature = wp.geom.create(tag, 'Offset2D');
                catch second_err
                    error("Failed to create COMSOL Offset feature. Offset error: %s. Offset2D error: %s.", ...
                        first_err.message, second_err.message);
                end
            end

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
                feature.set('keep', obj.bool_token(node.keep));
            catch
            end

            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Tangent(obj, node)
            % Emit a COMSOL Tangent feature.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            edge_tag = obj.tag_for(node.target);

            tag = obj.session.next_comsol_tag("tan");
            feature = wp.geom.create(tag, 'Tangent');
            type = lower(string(node.type));
            feature.set('type', char(type));
            obj.set_scalar(feature, 'start', obj.raw_component(node.start));

            edge_index = obj.entity_index(node.edge_index, "Tangent edge index");
            feature.selection('edge').set(edge_tag, edge_index);

            if type == "edge"
                if isempty(node.edge2)
                    error("Tangent type='edge' requires edge2.");
                end
                edge2_tag = obj.tag_for(node.edge2);
                edge2_index = obj.entity_index(node.edge2_index, "Tangent edge2 index");
                feature.selection('edge2').set(edge2_tag, edge2_index);
                obj.set_scalar(feature, 'start2', obj.raw_component(node.start2));
            elseif type == "point"
                if isempty(node.point_target)
                    error("Tangent type='point' requires point_target.");
                end
                point_tag = obj.tag_for(node.point_target);
                point_index = obj.entity_index(node.point_index, "Tangent point index");
                feature.selection('point').set(point_tag, point_index);
            else
                coord = obj.length_vector(node.coord, "Tangent coordinate");
                obj.set_pair(feature, 'coord', coord(1), coord(2));
            end

            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Extract(obj, node)
            % Emit a COMSOL Extract operation.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            tags = obj.collect_tags(node.members);

            tag = obj.session.next_comsol_tag("ext");
            try
                feature = wp.geom.create(tag, 'Extract');
            catch first_err
                try
                    feature = wp.geom.create(tag, 'SplitExtract');
                catch second_err
                    error("Failed to create COMSOL Extract feature. Extract error: %s. SplitExtract error: %s.", ...
                        first_err.message, second_err.message);
                end
            end
            obj.set_input_selection(feature, tags);
            try
                feature.set('inputhandling', char(node.inputhandling));
            catch
            end

            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
        end

        function emit_Thicken(obj, node)
            % Emit a COMSOL Thicken operation (2D) from a target curve/object.
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            input_tag = obj.tag_for(node.target);

            tag = obj.session.next_comsol_tag("thk");
            try
                feature = wp.geom.create(tag, 'Thicken2D');
            catch first_err
                try
                    feature = wp.geom.create(tag, 'Thicken');
                catch second_err
                    error("Failed to create COMSOL Thicken feature. Thicken2D error: %s. Thicken error: %s.", ...
                        first_err.message, second_err.message);
                end
            end

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
                feature.set('keep', obj.bool_token(node.keep));
            catch
            end
            try
                feature.set('propagatesel', obj.bool_token(node.propagatesel));
            catch
            end

            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = string(tag);
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

        function select_all_fillet_points(obj, feature, base_tag, node)
            % Select all fillet points using explicit indices when possible.
            if isa(node.target, 'femtogds.primitives.Rectangle')
                feature.selection('point').set(base_tag, 1:4);
                return;
            end
            indices = obj.infer_fillet_point_indices(node.target);
            if ~isempty(indices)
                feature.selection('point').set(base_tag, indices);
                return;
            end
            % Fallback when we cannot infer point indices.
            feature.selection('point').all;
        end

        function indices = infer_fillet_point_indices(obj, target)
            % Infer point indices from the GDS region equivalent of target.
            indices = [];
            if ~obj.session.has_gds()
                return;
            end

            if isempty(obj.session.gds_backend)
                obj.session.gds_backend = femtogds.core.GdsBackend(obj.session);
            end

            try
                reg = obj.session.gds_backend.region_for(target);
            catch
                return;
            end

            try
                it = reg.each_merged();
            catch
                return;
            end

            total_points = 0;
            while true
                try
                    poly = py.next(it);
                catch
                    break;
                end
                try
                    total_points = total_points + double(poly.num_points());
                catch
                end
            end

            if total_points > 0
                indices = 1:round(total_points);
            end
        end

        function define_parameter(obj, p)
            % Define a named femtogds.types.Parameter once in COMSOL param table.
            if ~isa(p, 'femtogds.types.Parameter') || ~p.is_named()
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
            % Define all named dependencies carried by a femtogds.types.Parameter object.
            if ~isa(p, 'femtogds.types.Parameter')
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
            % Set input feature selection with robust scalar/list handling.
            tok = string(tags);
            if ischar(tags)
                try
                    feature.selection('input').set(tags);
                catch
                end
                try
                    feature.set('input', tags);
                catch
                end
                return;
            end
            if isscalar(tok)
                one = char(tok);
                try
                    feature.selection('input').set(one);
                catch
                end
                try
                    feature.set('input', one);
                catch
                    try
                        feature.set('input', {one});
                    catch
                    end
                end
            else
                many = cellstr(tok(:).');
                try
                    feature.selection('input').set(many);
                catch
                end
                try
                    feature.set('input', many);
                catch
                end
            end
        end

        function token = vector_token(obj, x, y)
            % Convert two components into COMSOL "x,y" token syntax.
            token = obj.to_comsol_token(x) + "," + obj.to_comsol_token(y);
        end

        function [xvals, yvals] = polygon_components(obj, verts, context)
            % Build COMSOL-ready x/y component token lists for Polygon.
            if isa(verts.prefactor, 'femtogds.types.Parameter')
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

        function enable_keep_input(~, feature)
            % Best effort: keep source objects available for downstream features.
            try
                feature.set('keep', true);
                return;
            catch
            end
            try
                feature.set('keepinput', true);
            catch
            end
        end

        function out = raw_component(obj, val)
            % Convert wrapper objects into raw numeric/token payloads.
            if isa(val, 'femtogds.types.Parameter')
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
            if obj.session.snap_mode == "strict"
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
            % Extract numeric vector from femtogds.types.Vertices or raw vector.
            if isa(val, 'femtogds.types.Vertices')
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
            if isa(val, 'femtogds.types.Vertices')
                if val.nvertices ~= 1
                    error("Length vectors must resolve to a single [x y] pair.");
                end
                if isa(val.prefactor, 'femtogds.types.Parameter')
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
            % Convert femtogds.types.Parameter to COMSOL token and register dependencies.
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
            key = string(raw_token) + "|" + string(obj.session.snap_grid_nm);
            if isKey(obj.snapped_length_tokens, key)
                token = obj.snapped_length_tokens(key);
                return;
            end

            token = char(obj.session.next_comsol_tag("snp"));
            grid_expr = string(obj.session.snap_grid_nm) + "[nm]";
            snap_expr = "round((" + string(raw_token) + ")/(" + grid_expr + "))*(" + grid_expr + ")";
            obj.modeler.model.param.set(token, snap_expr, "");
            obj.snapped_length_tokens(key) = string(token);
            if obj.session.warn_on_snap
                warning("femtogds.core.GeometrySession:SnapExpr", ...
                    "Created snapped COMSOL expression '%s' from '%s'.", token, char(string(raw_token)));
            end
        end
        function name = class_short_name(~, obj_or_node)
            % Return unqualified class name from a potentially packaged class.
            cname = string(class(obj_or_node));
            parts = split(cname, ".");
            name = parts(end);
        end
        function tags = collect_tags(obj, inputs)
            % Resolve COMSOL tags for a list of input nodes.
            if isempty(inputs)
                tags = [];
                return;
            end
            tags = strings(1, numel(inputs));
            for i = 1:numel(inputs)
                tags(i) = string(obj.tag_for(inputs{i}));
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
                wp.geom.selection.create(tag, 'CumulativeSelection');
            catch
                try
                    wp.geom.selection().create(tag, 'CumulativeSelection');
                catch
                end
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








