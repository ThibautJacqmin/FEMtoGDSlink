classdef ComsolBackend < handle
    % COMSOL backend for emitting feature graph into a COMSOL model.
    properties
        session
        modeler
        defined_params
        feature_tags
        emitting
    end
    methods
        function obj = ComsolBackend(session)
            obj.session = session;
            obj.modeler = session.comsol;
            obj.defined_params = containers.Map('KeyType', 'char', 'ValueType', 'logical');
            obj.feature_tags = containers.Map('KeyType', 'int32', 'ValueType', 'char');
            obj.emitting = containers.Map('KeyType', 'int32', 'ValueType', 'logical');
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
            obj.feature_tags(int32(node.id)) = char(tag);
        end

        function emit_Union(obj, node)
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            tags = obj.collect_tags(node.inputs);

            tag = obj.session.next_comsol_tag("uni");
            feature = wp.geom.create(tag, 'Union');
            feature.selection('input').set(tags);
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
            obj.feature_tags(int32(node.id)) = char(tag);
        end

        function emit_Intersection(obj, node)
            layer = node.layer;
            wp = obj.session.get_workplane(layer);
            tags = obj.collect_tags(node.inputs);

            tag = obj.session.next_comsol_tag("int");
            feature = wp.geom.create(tag, 'Intersection');
            feature.selection('input').set(tags);
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
    end
end
