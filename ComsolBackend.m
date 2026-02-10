classdef ComsolBackend < handle
    % COMSOL backend for emitting feature graph into a COMSOL model.
    properties
        session
        modeler
        defined_params
        feature_tags
        emitting
        selection_tags
    end
    methods
        function obj = ComsolBackend(session)
            obj.session = session;
            obj.modeler = session.comsol;
            obj.defined_params = containers.Map('KeyType', 'char', 'ValueType', 'logical');
            obj.feature_tags = containers.Map('KeyType', 'int32', 'ValueType', 'char');
            obj.emitting = containers.Map('KeyType', 'int32', 'ValueType', 'logical');
            obj.selection_tags = containers.Map('KeyType', 'char', 'ValueType', 'char');
        end

        function emit_all(obj, nodes)
            for i = 1:numel(nodes)
                obj.tag_for(nodes{i});
            end
        end

        function emit(obj, node)
            method = "emit_" + class(node);
            if ismethod(obj, method)
                obj.(method)(node);
            else
                error("No COMSOL emitter for feature '" + class(node) + "'.");
            end
        end

        function tag = tag_for(obj, node)
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
            layer = node.layer;
            wp = obj.session.get_workplane(layer);

            tag = obj.session.next_comsol_tag("rect");
            feature = wp.geom.create(tag, 'Rectangle');
            feature.set('base', 'center');
            feature.set('pos', node.center_value());

            w = obj.expr(node.width);
            h = obj.expr(node.height);
            if isnumeric(w) && isnumeric(h)
                feature.set('size', [w, h]);
            else
                feature.set('size', {obj.to_comsol_token(w), obj.to_comsol_token(h)});
            end
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = char(tag);
        end

        function emit_Move(obj, node)
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            input_tag = obj.tag_for(node.target);

            tag = obj.session.next_comsol_tag("mov");
            feature = wp.geom.create(tag, 'Move');
            feature.selection('input').set(input_tag);
            delta = obj.vector_value(node.delta);
            feature.set('displx', delta(1));
            feature.set('disply', delta(2));
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = char(tag);
        end

        function emit_Rotate(obj, node)
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            input_tag = obj.tag_for(node.target);

            tag = obj.session.next_comsol_tag("rot");
            feature = wp.geom.create(tag, 'Rotate');
            feature.selection('input').set(input_tag);
            feature.set('rot', obj.to_comsol_token(obj.expr(node.angle)));
            feature.set('pos', obj.vector_value(node.origin));
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = char(tag);
        end

        function emit_Scale(obj, node)
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            input_tag = obj.tag_for(node.target);

            tag = obj.session.next_comsol_tag("sca");
            feature = wp.geom.create(tag, 'Scale');
            feature.selection('input').set(input_tag);
            feature.set('factor', obj.to_comsol_token(obj.expr(node.factor)));
            feature.set('pos', obj.vector_value(node.origin));
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = char(tag);
        end

        function emit_Mirror(obj, node)
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            input_tag = obj.tag_for(node.target);

            tag = obj.session.next_comsol_tag("mir");
            feature = wp.geom.create(tag, 'Mirror');
            feature.selection('input').set(input_tag);
            feature.set('pos', obj.vector_value(node.point));
            feature.set('axis', obj.vector_value(node.axis));
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = char(tag);
        end

        function emit_Union(obj, node)
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
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            base_tag = obj.tag_for(node.target);

            tag = obj.session.next_comsol_tag("fil");
            feature = wp.geom.create(tag, 'Fillet');
            feature.set('radius', obj.to_comsol_token(obj.expr(node.radius)));
            points = node.points;
            if isempty(points) && isa(node.target, 'Rectangle')
                points = 1:4;
            end
            if ~isempty(points)
                feature.selection('point').set(base_tag, points);
            else
                warning("Fillet points not specified; COMSOL may require point selection.");
            end
            obj.apply_layer_selection(layer, feature);
            obj.feature_tags(int32(node.id)) = char(tag);
        end
    end
    methods (Access=private)
        function out = expr(obj, val)
            if isa(val, 'Parameter')
                if strlength(val.name) > 0
                    obj.define_parameter(val);
                    out = char(val.name);
                else
                    out = val.value;
                end
                return;
            end
            if isobject(val) && isprop(val, 'name')
                out = char(val.name);
                return;
            end
            out = val;
        end

        function token = to_comsol_token(obj, val)
            if ischar(val)
                token = val;
            elseif isstring(val)
                token = char(val);
            else
                token = num2str(val);
            end
        end

        function define_parameter(obj, p)
            if strlength(p.name) == 0
                return;
            end
            key = char(p.name);
            if isKey(obj.defined_params, key)
                return;
            end
            unit = string(p.unit);
            if strlength(unit) ~= 0
                val = string(p.value) + "[" + unit + "]";
            else
                val = string(p.value);
            end
            obj.modeler.model.param.set(p.name, val, "");
            obj.defined_params(key) = true;
        end

        function vec = vector_value(obj, val)
            if isa(val, 'Vertices')
                vec = val.value;
            else
                vec = val;
            end
        end

        function tags = collect_tags(obj, inputs)
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
