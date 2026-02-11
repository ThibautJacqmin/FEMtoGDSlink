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
        snap_mode
        snap_grid_nm
        warn_on_snap
        snap_warned
        snap_stats
    end
    methods
        function obj = GeometrySession(args)
            % Build a geometry session and initialize enabled backends.
            arguments
                args.enable_comsol logical = true
                args.enable_gds logical = true
                args.emit_on_create logical = false
                args.set_as_current logical = true
                args.snap_mode {mustBeTextScalar} = "strict"
                args.snap_grid_nm double = 1
                args.warn_on_snap logical = true
                args.reuse_comsol_gui logical = false
                args.comsol_modeler ComsolModeler = ComsolModeler.empty
            end

            if args.enable_comsol
                if ~isempty(args.comsol_modeler)
                    obj.comsol = args.comsol_modeler;
                elseif args.reuse_comsol_gui
                    obj.comsol = ComsolModeler.shared(reset=true);
                else
                    obj.comsol = ComsolModeler;
                end
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
            obj.snap_mode = GeometrySession.validate_snap_mode(args.snap_mode);
            obj.snap_grid_nm = GeometrySession.validate_snap_grid(args.snap_grid_nm);
            obj.warn_on_snap = args.warn_on_snap;
            obj.snap_warned = containers.Map('KeyType', 'char', 'ValueType', 'logical');
            obj.snap_stats = containers.Map('KeyType', 'char', 'ValueType', 'any');

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
            % Register a logical layer and its COMSOL/GDS mappings.
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
            % Resolve layer input from LayerSpec instance or layer name.
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
            % Register a graph node and assign an incremental node id.
            obj.node_counter = obj.node_counter + 1;
            feature.id = obj.node_counter;
            obj.nodes{end+1} = feature;
        end

        function node_initialized(obj, feature)
            % Optionally emit COMSOL feature as soon as node is finalized.
            if obj.emit_on_create && obj.has_comsol() && feature.output
                if isempty(obj.comsol_backend)
                    obj.comsol_backend = ComsolBackend(obj);
                end
                obj.comsol_backend.tag_for(feature);
            end
        end

        function tf = has_comsol(obj)
            % Return true when COMSOL backend is enabled.
            tf = ~isempty(obj.comsol);
        end

        function tf = has_gds(obj)
            % Return true when GDS backend is enabled.
            tf = ~isempty(obj.gds);
        end

        function wp = get_workplane(obj, layer)
            % Get or lazily create the COMSOL workplane for one layer.
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
            % Generate the next unique tag for a COMSOL feature prefix.
            if ~isKey(obj.comsol_counters, prefix)
                obj.comsol_counters(prefix) = int32(0);
            end
            obj.comsol_counters(prefix) = obj.comsol_counters(prefix) + 1;
            tag = string(prefix) + string(obj.comsol_counters(prefix));
        end

        function build_comsol(obj)
            % Emit all registered nodes through COMSOL backend.
            if ~obj.has_comsol()
                error("COMSOL backend disabled.");
            end
            if isempty(obj.comsol_backend)
                obj.comsol_backend = ComsolBackend(obj);
            end
            obj.comsol_backend.emit_all(obj.nodes);
        end

        function export_gds(obj, filename)
            % Emit graph to GDS backend and write layout to disk.
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

        function snapped = snap_length(obj, values, context)
            % Snap lengths to grid when snap_mode is strict.
            arguments
                obj GeometrySession
                values
                context {mustBeTextScalar} = "geometry"
            end
            if obj.snap_mode == "off"
                snapped = values;
                return;
            end

            grid = obj.snap_grid_nm;
            snapped = round(values ./ grid) .* grid;
            if obj.warn_on_snap
                delta = abs(snapped - values);
                if any(delta(:) > 1e-12)
                    key = char(string(context));
                    obj.record_snap(key, delta);
                    if ~isKey(obj.snap_warned, key)
                        warning("GeometrySession:Snap", ...
                            "Snapped %s to %.12g nm grid (max delta %.6g nm).", ...
                            char(context), grid, max(delta(:)));
                        obj.snap_warned(key) = true;
                    end
                end
            end
        end

        function ints = gds_integer(obj, values, context)
            % Snap and round to integer nanometer database units.
            arguments
                obj GeometrySession
                values
                context {mustBeTextScalar} = "gds"
            end
            snapped = obj.snap_length(values, context);
            ints = round(snapped);
        end

        function clear_snap_report(obj)
            % Reset accumulated snap warnings and statistics.
            obj.snap_warned = containers.Map('KeyType', 'char', 'ValueType', 'logical');
            obj.snap_stats = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end

        function report = snap_report(obj, args)
            % Build tabular report of snap events by context.
            arguments
                obj GeometrySession
                args.display logical = true
            end
            keys_list = obj.snap_stats.keys;
            if isempty(keys_list)
                report = table(strings(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
                    'VariableNames', {'Context', 'SnapCount', 'MaxDeltaNm', 'GridNm'});
                if args.display
                    disp("No snap events recorded.");
                end
                return;
            end

            n = numel(keys_list);
            context = strings(n, 1);
            snap_count = zeros(n, 1);
            max_delta = zeros(n, 1);
            grid_nm = zeros(n, 1);

            for i = 1:n
                key = keys_list{i};
                stats = obj.snap_stats(key);
                context(i) = string(key);
                snap_count(i) = stats.count;
                max_delta(i) = stats.max_delta_nm;
                grid_nm(i) = stats.grid_nm;
            end

            report = table(context, snap_count, max_delta, grid_nm, ...
                'VariableNames', {'Context', 'SnapCount', 'MaxDeltaNm', 'GridNm'});
            if args.display
                disp(report);
            end
        end

        function report = build_report(obj, args)
            % Return consolidated diagnostic report for session/backends.
            arguments
                obj GeometrySession
                args.display logical = true
            end

            report = struct();
            report.timestamp = datetime("now");
            report.session = struct( ...
                "comsol_enabled", obj.has_comsol(), ...
                "gds_enabled", obj.has_gds(), ...
                "snap_mode", string(obj.snap_mode), ...
                "snap_grid_nm", obj.snap_grid_nm, ...
                "warn_on_snap", obj.warn_on_snap);

            report.nodes = obj.node_report();
            report.gds = obj.gds_report();
            report.comsol = obj.comsol_report();
            report.snap = obj.snap_report(display=false);

            if args.display
                fprintf("Build Report (%s)\n", string(report.timestamp));
                fprintf("Session: COMSOL=%d, GDS=%d, snap_mode=%s, snap_grid_nm=%g\n", ...
                    report.session.comsol_enabled, report.session.gds_enabled, ...
                    report.session.snap_mode, report.session.snap_grid_nm);

                fprintf("Nodes: total=%d, output=%d\n", ...
                    report.nodes.total, report.nodes.output);
                if height(report.nodes.by_type) > 0
                    disp(report.nodes.by_type);
                end
                if height(report.nodes.by_layer) > 0
                    disp(report.nodes.by_layer);
                end

                fprintf("GDS backend: initialized=%d, emitted_nodes=%d, cached_regions=%d\n", ...
                    report.gds.initialized, report.gds.emitted_nodes, report.gds.cached_regions);
                fprintf("COMSOL backend: initialized=%d, emitted_features=%d, selections=%d, snapped_expr_params=%d, defined_params=%d\n", ...
                    report.comsol.initialized, report.comsol.emitted_features, report.comsol.selections, ...
                    report.comsol.snapped_expr_params, report.comsol.defined_params);

                if height(report.snap) > 0
                    disp(report.snap);
                else
                    disp("No snap events recorded.");
                end
            end
        end
    end
    methods (Static)
        function ctx = with_shared_comsol(args)
            % Create a session using process-wide shared COMSOL modeler.
            arguments
                args.enable_gds logical = true
                args.emit_on_create logical = false
                args.set_as_current logical = true
                args.snap_mode {mustBeTextScalar} = "strict"
                args.snap_grid_nm double = 1
                args.warn_on_snap logical = true
                args.reset_model logical = true
            end
            shared_modeler = ComsolModeler.shared(reset=args.reset_model);
            ctx = GeometrySession( ...
                enable_comsol=true, ...
                enable_gds=args.enable_gds, ...
                emit_on_create=args.emit_on_create, ...
                set_as_current=args.set_as_current, ...
                snap_mode=args.snap_mode, ...
                snap_grid_nm=args.snap_grid_nm, ...
                warn_on_snap=args.warn_on_snap, ...
                comsol_modeler=shared_modeler);
        end

        function clear_shared_comsol()
            % Dispose and clear shared COMSOL model used by helper API.
            ComsolModeler.clear_shared();
        end

        function set_current(ctx)
            % Set process-global active GeometrySession.
            GeometrySession.current_context_store(ctx);
        end

        function ctx = get_current()
            % Get process-global active GeometrySession if any.
            current_ctx = GeometrySession.current_context_store();
            if isempty(current_ctx)
                ctx = [];
            else
                ctx = current_ctx;
            end
        end

        function ctx = require_current()
            % Get active GeometrySession or raise an explicit error.
            ctx = GeometrySession.get_current();
            if isempty(ctx)
                error("No active GeometrySession. Create one or call GeometrySession.set_current(ctx).");
            end
        end
    end
    methods (Static, Access=private)
        function mode = validate_snap_mode(raw_mode)
            % Validate and normalize snap mode text value.
            mode = lower(string(raw_mode));
            if ~any(mode == ["strict", "off"])
                error("snap_mode must be 'strict' or 'off'.");
            end
        end

        function grid = validate_snap_grid(raw_grid)
            % Validate snapping grid as positive integer nanometers.
            grid = double(raw_grid);
            if ~(isscalar(grid) && isfinite(grid) && grid >= 1 && abs(grid-round(grid)) < 1e-12)
                error("snap_grid_nm must be a positive integer >= 1.");
            end
            grid = round(grid);
        end

        function ctx = current_context_store(varargin)
            % Persistent storage for current GeometrySession singleton.
            persistent current_ctx
            if nargin == 1
                current_ctx = varargin{1};
            end
            ctx = current_ctx;
        end
    end
    methods (Access=private)
        function record_snap(obj, key, delta)
            % Aggregate snap statistics for one context key.
            changed = delta(delta > 1e-12);
            if isempty(changed)
                return;
            end

            if isKey(obj.snap_stats, key)
                stats = obj.snap_stats(key);
            else
                stats = struct('count', 0, 'max_delta_nm', 0, 'grid_nm', obj.snap_grid_nm);
            end

            stats.count = stats.count + numel(changed);
            stats.max_delta_nm = max(stats.max_delta_nm, max(changed));
            obj.snap_stats(key) = stats;
        end

        function report = node_report(obj)
            % Summarize node counts by type/layer and output flag.
            n = numel(obj.nodes);
            classes = strings(n, 1);
            layers = strings(n, 1);
            outputs = false(n, 1);
            for i = 1:n
                node = obj.nodes{i};
                classes(i) = string(class(node));
                outputs(i) = logical(node.output);
                if isa(node.layer, "LayerSpec")
                    layers(i) = string(node.layer.name);
                else
                    layers(i) = string(node.layer);
                end
            end

            report = struct();
            report.total = n;
            report.output = sum(outputs);
            report.by_type = obj.count_table(classes, outputs, "Type");
            report.by_layer = obj.count_table(layers, outputs, "Layer");
        end

        function report = gds_report(obj)
            % Summarize GDS backend cache and emission state.
            report = struct();
            report.initialized = ~isempty(obj.gds_backend);
            report.emitted_nodes = 0;
            report.cached_regions = 0;
            if ~report.initialized
                return;
            end
            report.cached_regions = obj.map_count(obj.gds_backend.regions);
            report.emitted_nodes = obj.true_value_count(obj.gds_backend.emitted);
        end

        function report = comsol_report(obj)
            % Summarize COMSOL backend cache and emission state.
            report = struct();
            report.initialized = ~isempty(obj.comsol_backend);
            report.emitted_features = 0;
            report.selections = 0;
            report.snapped_expr_params = 0;
            report.defined_params = 0;
            if ~report.initialized
                return;
            end
            report.emitted_features = obj.map_count(obj.comsol_backend.feature_tags);
            report.selections = obj.map_count(obj.comsol_backend.selection_tags);
            report.snapped_expr_params = obj.map_count(obj.comsol_backend.snapped_length_tokens);
            report.defined_params = obj.map_count(obj.comsol_backend.defined_params);
        end

        function tbl = count_table(~, labels, outputs, first_col_name)
            % Aggregate counts and output counts for categorical labels.
            first_col_name = char(first_col_name);
            if isempty(labels)
                tbl = table(strings(0, 1), zeros(0, 1), zeros(0, 1), ...
                    'VariableNames', {first_col_name, 'Count', 'OutputCount'});
                return;
            end
            [uniq, ~, idx] = unique(labels);
            count = accumarray(idx, 1);
            out_count = accumarray(idx, double(outputs));
            tbl = table(uniq, count, out_count, ...
                'VariableNames', {first_col_name, 'Count', 'OutputCount'});
        end

        function n = map_count(~, m)
            % Return number of keys in a containers.Map.
            n = numel(m.keys);
        end

        function n = true_value_count(~, m)
            % Count true values in a logical-value containers.Map.
            vals = m.values;
            if isempty(vals)
                n = 0;
                return;
            end
            n = sum(cell2mat(vals));
        end
    end
end
