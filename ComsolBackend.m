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
            % Initialize a COMSOL emitter bound to one GeometrySession.
            obj.session = session;
            obj.modeler = session.comsol;
            obj.defined_params = containers.Map('KeyType', 'char', 'ValueType', 'logical');
            obj.feature_tags = containers.Map('KeyType', 'int32', 'ValueType', 'char');
            obj.emitting = containers.Map('KeyType', 'int32', 'ValueType', 'logical');
            obj.selection_tags = containers.Map('KeyType', 'char', 'ValueType', 'char');
            obj.snapped_length_tokens = containers.Map('KeyType', 'char', 'ValueType', 'char');
        end

        function emit_all(obj, nodes)
            % Emit all nodes in registration order.
            for i = 1:numel(nodes)
                obj.tag_for(nodes{i});
            end
        end

        function emit(obj, node)
            % Dispatch emission based on node class name.
            method = "emit_" + class(node);
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
            remove(obj.emitting, id);
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
            obj.feature_tags(int32(node.id)) = char(tag);
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
            obj.feature_tags(int32(node.id)) = char(tag);
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
            obj.feature_tags(int32(node.id)) = char(tag);
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
            obj.feature_tags(int32(node.id)) = char(tag);
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
            obj.feature_tags(int32(node.id)) = char(tag);
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
            obj.feature_tags(int32(node.id)) = char(tag);
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
            obj.feature_tags(int32(node.id)) = char(tag);
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
            obj.feature_tags(int32(node.id)) = char(tag);
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
            if isempty(points) && isa(node.target, 'Rectangle')
                points = 1:4;
            end
            if ~isempty(points)
                if isa(points, 'Parameter')
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
            obj.feature_tags(int32(node.id)) = char(tag);
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

        function select_all_fillet_points(obj, feature, base_tag, node)
            % Select all fillet points using explicit indices when possible.
            if isa(node.target, 'Rectangle')
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
                obj.session.gds_backend = GdsBackend(obj.session);
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
            % Define a named Parameter once in COMSOL param table.
            if ~isa(p, 'Parameter') || ~p.is_named()
                return;
            end
            key = char(p.name);
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
            % Define all named dependencies carried by a Parameter object.
            if ~isa(p, 'Parameter')
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

            key = char(name);
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

        function out = raw_component(obj, val)
            % Convert wrapper objects into raw numeric/token payloads.
            if isa(val, 'Parameter')
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

        function vec = vector_value(obj, val)
            % Extract numeric vector from Vertices or raw vector.
            if isa(val, 'Vertices')
                vec = val.value;
            else
                vec = val;
            end
        end

        function vec = length_vector(obj, val, context)
            % Resolve and optionally snap a 2D length vector.
            if isa(val, 'Vertices')
                if val.nvertices ~= 1
                    error("Length vectors must resolve to a single [x y] pair.");
                end
                if isa(val.prefactor, 'Parameter')
                    obj.parameter_token(val.prefactor);
                end
                xexpr = string(val.comsol_string_x());
                yexpr = string(val.comsol_string_y());
                vec = [ ...
                    obj.length_component(xexpr(1), string(context) + " x"), ...
                    obj.length_component(yexpr(1), string(context) + " y")];
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
            vec = [ ...
                obj.length_component(tok(1), string(context) + " x"), ...
                obj.length_component(tok(2), string(context) + " y")];
        end

        function token = parameter_token(obj, p)
            % Convert Parameter to COMSOL token and register dependencies.
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
            key = char(string(raw_token) + "|" + string(obj.session.snap_grid_nm));
            if isKey(obj.snapped_length_tokens, key)
                token = obj.snapped_length_tokens(key);
                return;
            end

            token = char(obj.session.next_comsol_tag("snp"));
            grid_expr = string(obj.session.snap_grid_nm) + "[nm]";
            snap_expr = "round((" + string(raw_token) + ")/(" + grid_expr + "))*(" + grid_expr + ")";
            obj.modeler.model.param.set(token, snap_expr, "");
            obj.snapped_length_tokens(key) = token;
            if obj.session.warn_on_snap
                warning("GeometrySession:SnapExpr", ...
                    "Created snapped COMSOL expression '%s' from '%s'.", token, char(string(raw_token)));
            end
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
            key = char(string(layer.comsol_workplane) + "|" + string(name));
            if isKey(obj.selection_tags, key)
                tag = obj.selection_tags(key);
                return;
            end

            tag = char(obj.session.next_comsol_tag("csel"));
            obj.selection_tags(key) = tag;

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

        function token = selection_show_token(obj, state)
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
