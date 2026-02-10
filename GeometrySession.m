classdef GeometrySession < handle
    % GeometrySession coordinates COMSOL and GDS backends and layer mapping.
    properties
        comsol
        gds
        layers
        nodes
        comsol_workplanes
        comsol_counters
        comsol_backend
        gds_backend
        node_counter
        emit_on_create
    end
    methods
        function obj = GeometrySession(args)
            arguments
                args.enable_comsol logical = true
                args.enable_gds logical = true
                args.emit_on_create logical = false
                args.set_as_current logical = true
            end

            if args.enable_comsol
                obj.comsol = ComsolModeler;
            else
                obj.comsol = [];
            end

            if args.enable_gds
                obj.gds = GDSModeler;
            else
                obj.gds = [];
            end

            obj.layers = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.nodes = {};
            obj.comsol_workplanes = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.comsol_counters = containers.Map('KeyType', 'char', 'ValueType', 'int32');
            obj.comsol_backend = [];
            obj.gds_backend = [];
            obj.node_counter = int32(0);
            obj.emit_on_create = args.emit_on_create;

            if args.set_as_current
                GeometrySession.set_current(obj);
            end

            % Default layer mapping (layer 1 on workplane wp1).
            obj.add_layer("default", gds_layer=1, comsol_workplane="wp1");

            if ~isempty(obj.comsol)
                obj.comsol_workplanes('wp1') = obj.comsol.workplane;
            end
        end

        function layer = add_layer(obj, name, args)
            arguments
                obj
                name {mustBeTextScalar}
                args.gds_layer double = 1
                args.gds_datatype double = 0
                args.comsol_workplane {mustBeTextScalar} = "wp1"
                args.comsol_selection {mustBeTextScalar} = ""
                args.comsol_selection_state {mustBeTextScalar} = "all"
                args.comsol_enable_selection logical = true
            end
            layer = LayerSpec(name, ...
                gds_layer=args.gds_layer, ...
                gds_datatype=args.gds_datatype, ...
                comsol_workplane=args.comsol_workplane, ...
                comsol_selection=args.comsol_selection, ...
                comsol_selection_state=args.comsol_selection_state, ...
                comsol_enable_selection=args.comsol_enable_selection);
            obj.layers(char(layer.name)) = layer;
        end

        function layer = resolve_layer(obj, ref)
            if isa(ref, 'LayerSpec')
                layer = ref;
                return;
            end
            if isstring(ref) || ischar(ref)
                key = char(ref);
                if ~isKey(obj.layers, key)
                    error("Unknown layer '" + string(ref) + "'. Call add_layer first.");
                end
                layer = obj.layers(key);
                return;
            end
            error("Layer reference must be a LayerSpec or layer name.");
        end

        function register(obj, feature)
            obj.node_counter = obj.node_counter + 1;
            feature.id = obj.node_counter;
            obj.nodes{end+1} = feature;
        end

        function node_initialized(obj, feature)
            if obj.emit_on_create && obj.has_comsol()
                if isempty(obj.comsol_backend)
                    obj.comsol_backend = ComsolBackend(obj);
                end
                obj.comsol_backend.tag_for(feature);
            end
        end

        function tf = has_comsol(obj)
            tf = ~isempty(obj.comsol);
        end

        function tf = has_gds(obj)
            tf = ~isempty(obj.gds);
        end

        function wp = get_workplane(obj, layer)
            wp = [];
            if ~obj.has_comsol()
                return;
            end
            tag = char(layer.comsol_workplane);
            if isKey(obj.comsol_workplanes, tag)
                wp = obj.comsol_workplanes(tag);
            else
                wp = obj.comsol.geometry.create(tag, 'WorkPlane');
                obj.comsol.geometry.feature(tag).set('unite', true);
                obj.comsol_workplanes(tag) = wp;
            end
        end

        function tag = next_comsol_tag(obj, prefix)
            if ~isKey(obj.comsol_counters, prefix)
                obj.comsol_counters(prefix) = int32(0);
            end
            obj.comsol_counters(prefix) = obj.comsol_counters(prefix) + 1;
            tag = string(prefix) + string(obj.comsol_counters(prefix));
        end

        function build_comsol(obj)
            if ~obj.has_comsol()
                error("COMSOL backend disabled.");
            end
            if isempty(obj.comsol_backend)
                obj.comsol_backend = ComsolBackend(obj);
            end
            obj.comsol_backend.emit_all(obj.nodes);
        end

        function export_gds(obj, filename)
            arguments
                obj GeometrySession
                filename {mustBeTextScalar}
            end
            if ~obj.has_gds()
                error("GDS backend disabled.");
            end
            if isempty(obj.gds_backend)
                obj.gds_backend = GdsBackend(obj);
            end
            obj.gds_backend.emit_all(obj.nodes);
            obj.gds.write(filename);
        end
    end
    methods (Static)
        function set_current(ctx)
            GeometrySession.current_context_store(ctx);
        end

        function ctx = get_current()
            current_ctx = GeometrySession.current_context_store();
            if isempty(current_ctx)
                ctx = [];
            else
                ctx = current_ctx;
            end
        end

        function ctx = require_current()
            ctx = GeometrySession.get_current();
            if isempty(ctx)
                error("No active GeometrySession. Create one or call GeometrySession.set_current(ctx).");
            end
        end
    end
    methods (Static, Access=private)
        function ctx = current_context_store(varargin)
            persistent current_ctx
            if nargin == 1
                current_ctx = varargin{1};
            end
            ctx = current_ctx;
        end
    end
end
