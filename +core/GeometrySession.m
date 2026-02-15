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
        gds_resolution_nm
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
                args.use_comsol logical = true
                args.use_gds logical = true
                args.emit_on_create logical = false
                args.set_as_current logical = true
                args.snap_mode {mustBeTextScalar} = "strict"
                args.gds_resolution_nm double = NaN
                args.snap_grid_nm double = NaN
                args.warn_on_snap logical = true
                args.reuse_comsol_gui logical = false
                args.launch_comsol_gui logical = false
                args.comsol_modeler = []
            end

            enable_comsol = args.enable_comsol && args.use_comsol;
            enable_gds = args.enable_gds && args.use_gds;
            resolved_gds_nm = core.GeometrySession.resolve_gds_resolution( ...
                args.gds_resolution_nm, args.snap_grid_nm);

            if enable_comsol
                if ~isempty(args.comsol_modeler)
                    obj.comsol = args.comsol_modeler;
                elseif args.reuse_comsol_gui
                    obj.comsol = core.ComsolModeler.shared(reset=true);
                else
                    obj.comsol = core.ComsolModeler;
                end
            else
                obj.comsol = [];
            end

            if enable_gds
                obj.gds = core.GDSModeler(dbu_nm=resolved_gds_nm);
            else
                obj.gds = [];
            end

            obj.layers = dictionary(string.empty(0,1), core.LayerSpec.empty(0,1));
            obj.nodes = {};
            obj.comsol_workplanes = dictionary(string.empty(0,1), cell(0,1));
            obj.comsol_counters = dictionary(string.empty(0,1), int32.empty(0,1));
            obj.comsol_backend = [];
            obj.gds_backend = [];
            obj.node_counter = int32(0);
            obj.emit_on_create = args.emit_on_create;
            obj.snap_mode = core.GeometrySession.validate_snap_mode(args.snap_mode);
            obj.gds_resolution_nm = resolved_gds_nm;
            % Backward-compatible alias: keep snap_grid_nm tied to GDS DBU resolution.
            obj.snap_grid_nm = resolved_gds_nm;
            obj.warn_on_snap = args.warn_on_snap;
            obj.snap_warned = dictionary(string.empty(0,1), false(0,1));
            obj.snap_stats = dictionary(string.empty(0,1), ...
                struct('count', 0, 'max_delta_nm', 0, 'grid_nm', obj.gds_resolution_nm));

            if args.set_as_current
                core.GeometrySession.set_current(obj);
            end

            % Default layer mapping (layer 1 on workplane wp1).
            obj.add_layer("default", gds_layer=1, comsol_workplane="wp1");

            if ~isempty(obj.comsol)
                obj.comsol_workplanes("wp1") = {obj.comsol.workplane};
            end
            if args.launch_comsol_gui && ~isempty(obj.comsol)
                try
                    obj.comsol.start_gui();
                catch
                    warning("GeometrySession:GuiLaunch", ...
                        "Failed to launch/attach COMSOL Desktop automatically.");
                end
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
                args.emit_to_comsol logical = true
            end
            layer = core.LayerSpec(name, ...
                gds_layer=args.gds_layer, ...
                gds_datatype=args.gds_datatype, ...
                comsol_workplane=args.comsol_workplane, ...
                comsol_selection=args.comsol_selection, ...
                comsol_selection_state=args.comsol_selection_state, ...
                comsol_enable_selection=args.comsol_enable_selection, ...
                comsol_emit=args.emit_to_comsol);
            obj.layers(string(layer.name)) = layer;
        end

        function layer = resolve_layer(obj, ref)
            % Resolve layer input from core.LayerSpec instance or layer name.
            if isa(ref, 'core.LayerSpec')
                layer = ref;
                return;
            end
            if isstring(ref) || ischar(ref)
                key = string(ref);
                if ~isKey(obj.layers, key)
                    error("Unknown layer '" + string(ref) + "'. Call add_layer first.");
                end
                layer = obj.layers(key);
                return;
            end
            error("Layer reference must be a core.LayerSpec or layer name.");
        end

        function register(obj, feature)
            % Register a graph node and assign an incremental node id.
            obj.node_counter = obj.node_counter + 1;
            feature.id = obj.node_counter;
            obj.nodes{end+1} = feature;
        end

        function node_initialized(obj, feature)
            % Optionally emit COMSOL feature as soon as node is finalized.
            % COMSOL emission is layer-driven (comsol_emit).
            if obj.emit_on_create && obj.has_comsol() && feature.layer.comsol_emit
                if isempty(obj.comsol_backend)
                    obj.comsol_backend = core.ComsolBackend(obj);
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

        function p_out = register_parameter(obj, p, args)
            % Register a standalone parameter expression in COMSOL.
            arguments
                obj
                p
                args.name {mustBeTextScalar} = ""
                args.unit {mustBeTextScalar} = "__auto__"
            end

            if ~obj.has_comsol()
                error("GeometrySession:ComsolDisabled", ...
                    "Cannot register parameter: COMSOL backend disabled.");
            end

            if isa(p, 'types.Parameter')
                param_obj = p;
                if strlength(string(args.unit)) ~= 0 && string(args.unit) ~= "__auto__"
                    param_obj = types.Parameter(param_obj, param_obj.name, ...
                        unit=args.unit, expression=param_obj.expr, auto_register=false);
                end
            else
                name = string(args.name);
                if strlength(name) == 0
                    error("GeometrySession:MissingParameterName", ...
                        "register_parameter requires a name when input is not a Parameter object.");
                end
                param_obj = types.Parameter(p, name, unit=args.unit, auto_register=false);
            end

            if isempty(obj.comsol_backend)
                obj.comsol_backend = core.ComsolBackend(obj);
            end
            p_out = obj.comsol_backend.register_parameter(param_obj, name=args.name);
        end

        function wp = get_workplane(obj, layer)
            % Get or lazily create the COMSOL workplane for one layer.
            wp = [];
            if ~obj.has_comsol()
                return;
            end
            tag = string(layer.comsol_workplane);
            if isKey(obj.comsol_workplanes, tag)
                cached_wp = obj.comsol_workplanes(tag);
                wp = cached_wp{1};
            else
                wp = obj.comsol.geometry.create(tag, 'WorkPlane');
                obj.comsol.geometry.feature(tag).set('unite', true);
                obj.comsol_workplanes(tag) = {wp};
            end
        end

        function tag = next_comsol_tag(obj, prefix)
            % Generate the next unique tag for a COMSOL feature prefix.
            prefix = string(prefix);
            if ~isKey(obj.comsol_counters, prefix)
                obj.comsol_counters(prefix) = int32(0);
            end
            obj.comsol_counters(prefix) = obj.comsol_counters(prefix) + 1;
            tag = string(prefix) + string(obj.comsol_counters(prefix));
        end

        function build_comsol(obj)
            % Emit all nodes on COMSOL-enabled layers through COMSOL backend.
            if ~obj.has_comsol()
                error("COMSOL backend disabled.");
            end
            if isempty(obj.comsol_backend)
                obj.comsol_backend = core.ComsolBackend(obj);
            end
            nodes_to_emit = obj.nodes;
            nodes_to_emit = nodes_to_emit(cellfun(@(n) n.layer.comsol_emit, nodes_to_emit));
            obj.comsol_backend.emit_all(nodes_to_emit);
        end

        function export_gds(obj, filename, args)
            % Emit graph to GDS backend and write layout to disk.
            % By default, only terminal (final) nodes are exported.
            arguments
                obj core.GeometrySession
                filename {mustBeTextScalar}
                args.scope {mustBeTextScalar} = "final"
            end
            if ~obj.has_gds()
                error("GDS backend disabled.");
            end
            if isempty(obj.gds_backend)
                obj.gds_backend = core.GdsBackend(obj);
            end
            nodes_to_emit = obj.gds_nodes_for_export(scope=args.scope);
            obj.gds_backend.emit_all(nodes_to_emit);
            obj.gds.write(filename);
        end

        function nodes = gds_nodes_for_export(obj, args)
            % Select which nodes are emitted in GDS export.
            arguments
                obj core.GeometrySession
                args.scope {mustBeTextScalar} = "final"
            end
            scope = lower(string(args.scope));
            if scope == "all"
                nodes = obj.nodes;
                return;
            end
            if any(scope == ["final", "terminal", "sinks", "leaf"])
                nodes = obj.terminal_nodes();
                return;
            end
            error("GeometrySession:InvalidGdsScope", ...
                "Invalid GDS export scope '%s'. Use 'final' or 'all'.", char(scope));
        end

        function nodes = terminal_nodes(obj)
            % Return graph sink nodes (nodes not used as input by others).
            if isempty(obj.nodes)
                nodes = {};
                return;
            end

            used = dictionary(int32.empty(0,1), false(0,1));
            for i = 1:numel(obj.nodes)
                node = obj.nodes{i};
                keeps_inputs = core.GeometrySession.node_keeps_inputs(node);
                for j = 1:numel(node.inputs)
                    in = node.inputs{j};
                    if keeps_inputs
                        continue;
                    end
                    if isa(in, 'core.GeomFeature') && ~isempty(in.id)
                        used(int32(in.id)) = true;
                    end
                end
            end

            keep = false(1, numel(obj.nodes));
            for i = 1:numel(obj.nodes)
                keep(i) = ~isKey(used, int32(obj.nodes{i}.id));
            end
            nodes = obj.nodes(keep);
        end

        function open_comsol_gui(obj)
            % Launch or attach COMSOL Desktop to the current model.
            if ~obj.has_comsol()
                error("COMSOL backend disabled.");
            end
            obj.comsol.start_gui();
        end

        function snapped = snap_length(obj, values, context)
            % Snap lengths to grid when snap_mode is strict.
            arguments
                obj core.GeometrySession
                values
                context {mustBeTextScalar} = "geometry"
            end
            if obj.snap_mode == "off"
                snapped = values;
                return;
            end

            grid = obj.gds_resolution_nm;
            snapped = round(values ./ grid) .* grid;
            if obj.warn_on_snap
                delta = abs(snapped - values);
                if any(delta(:) > 1e-12)
                    key = string(context);
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
            % Snap and convert nm values into integer GDS database units.
            arguments
                obj core.GeometrySession
                values
                context {mustBeTextScalar} = "gds"
            end
            snapped = obj.snap_length(values, context);
            ints = round(snapped ./ obj.gds_resolution_nm);
        end

        function clear_snap_report(obj)
            % Reset accumulated snap warnings and statistics.
            obj.snap_warned = dictionary(string.empty(0,1), false(0,1));
            obj.snap_stats = dictionary(string.empty(0,1), struct('count', {}, 'max_delta_nm', {}, 'grid_nm', {}));
        end

        function report = snap_report(obj, args)
            % Build tabular report of snap events by context.
            arguments
                obj core.GeometrySession
                args.display logical = true
            end
            keys_list = keys(obj.snap_stats);
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
                key = keys_list(i);
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
                obj core.GeometrySession
                args.display logical = true
            end

            report = struct();
            report.timestamp = datetime("now");
            report.session = struct( ...
                "comsol_enabled", obj.has_comsol(), ...
                "gds_enabled", obj.has_gds(), ...
                "snap_mode", string(obj.snap_mode), ...
                "gds_resolution_nm", obj.gds_resolution_nm, ...
                "snap_grid_nm", obj.snap_grid_nm, ...
                "warn_on_snap", obj.warn_on_snap);

            report.nodes = obj.node_report();
            report.gds = obj.gds_report();
            report.comsol = obj.comsol_report();
            report.snap = obj.snap_report(display=false);

            if args.display
                fprintf("Build Report (%s)\n", string(report.timestamp));
                fprintf("Session: COMSOL=%d, GDS=%d, snap_mode=%s, gds_resolution_nm=%g\n", ...
                    report.session.comsol_enabled, report.session.gds_enabled, ...
                    report.session.snap_mode, report.session.gds_resolution_nm);

                fprintf("Nodes: total=%d\n", report.nodes.total);
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
        function [scale_nm, is_length] = unit_scale_to_nm(unit_token)
            % Convert supported length-unit token to an nm scale factor.
            u = lower(strtrim(string(unit_token)));
            u = replace(u, "µ", "u");
            u = replace(u, "μ", "u");

            is_length = true;
            switch u
                case {"", "nm", "nanometer", "nanometers"}
                    scale_nm = 1;
                case {"um", "micrometer", "micrometers"}
                    scale_nm = 1e3;
                case {"mm", "millimeter", "millimeters"}
                    scale_nm = 1e6;
                case {"cm", "centimeter", "centimeters"}
                    scale_nm = 1e7;
                case {"m", "meter", "meters"}
                    scale_nm = 1e9;
                case {"pm", "picometer", "picometers"}
                    scale_nm = 1e-3;
                case {"fm", "femtometer", "femtometers"}
                    scale_nm = 1e-6;
                case {"a", "angstrom", "angstroms"}
                    scale_nm = 1e-1;
                otherwise
                    scale_nm = NaN;
                    is_length = false;
            end
        end

        function ctx = with_shared_comsol(args)
            % Create a session using process-wide shared COMSOL modeler.
            % comsol_bootstrap:
            % - "livelink": use mphstart workflow.
            % - "independent": direct Java API bootstrap (no mphstart).
            % - "auto": try livelink first, then independent.
            % comsol_api:
            % - "livelink": MATLAB LiveLink modeler (current default).
            % - "mph": Python MPh modeler (no LiveLink).
            arguments
                args.enable_gds logical = true
                args.use_comsol logical = true
                args.use_gds logical = true
                args.emit_on_create logical = false
                args.set_as_current logical = true
                args.snap_mode {mustBeTextScalar} = "strict"
                args.gds_resolution_nm double = NaN
                args.snap_grid_nm double = NaN
                args.warn_on_snap logical = true
                args.reset_model logical = true
                args.launch_comsol_gui logical = false
                args.clean_on_reset logical = true
                args.comsol_api {mustBeTextScalar} = "livelink"
                args.comsol_bootstrap {mustBeTextScalar} = "auto"
                args.comsol_host {mustBeTextScalar} = "localhost"
                args.comsol_port double = 2036
                args.comsol_root {mustBeTextScalar} = ""
                args.bootstrap_connect logical = true
            end
            if args.use_comsol
                if args.reset_model && args.clean_on_reset
                    core.GeometrySession.clean_comsol_server();
                end
                api = lower(string(args.comsol_api));
                if api == "mph"
                    shared_modeler = core.ComsolMphModeler.shared( ...
                        reset=args.reset_model, ...
                        comsol_host=args.comsol_host, ...
                        comsol_port=args.comsol_port, ...
                        strict_installed=true);
                else
                    shared_modeler = core.ComsolModeler.shared( ...
                        reset=args.reset_model, ...
                        bootstrap_mode=args.comsol_bootstrap, ...
                        comsol_host=args.comsol_host, ...
                        comsol_port=args.comsol_port, ...
                        comsol_root=args.comsol_root, ...
                        bootstrap_connect=args.bootstrap_connect);
                end
            else
                shared_modeler = [];
            end
            ctx = core.GeometrySession( ...
                enable_comsol=args.use_comsol, ...
                enable_gds=args.enable_gds && args.use_gds, ...
                use_comsol=args.use_comsol, ...
                use_gds=args.use_gds, ...
                emit_on_create=args.emit_on_create, ...
                set_as_current=args.set_as_current, ...
                snap_mode=args.snap_mode, ...
                gds_resolution_nm=args.gds_resolution_nm, ...
                snap_grid_nm=args.snap_grid_nm, ...
                warn_on_snap=args.warn_on_snap, ...
                launch_comsol_gui=args.launch_comsol_gui, ...
                comsol_modeler=shared_modeler);
        end

        function clear_shared_comsol()
            % Dispose and clear shared COMSOL model used by helper API.
            core.ComsolModeler.clear_shared();
            try
                core.ComsolMphModeler.clear_shared();
            catch
            end
        end

        function removed = clean_comsol_server(args)
            % Remove generated COMSOL models and clear shared COMSOL handle.
            arguments
                args.prefix (1,1) string = "Model_"
            end
            removed = core.ComsolModeler.clear_generated_models(prefix=args.prefix);
            try
                removed = removed + core.ComsolMphModeler.clear_generated_models(prefix=args.prefix);
            catch
            end
            core.GeometrySession.clear_shared_comsol();
        end

        function set_current(ctx)
            % Set process-global active GeometrySession.
            core.GeometrySession.current_context_store(ctx);
        end

        function ctx = get_current()
            % Get process-global active GeometrySession if any.
            current_ctx = core.GeometrySession.current_context_store();
            if isempty(current_ctx)
                ctx = [];
            else
                ctx = current_ctx;
            end
        end

        function ctx = require_current()
            % Get active GeometrySession or raise an explicit error.
            ctx = core.GeometrySession.get_current();
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

        function grid = validate_length_grid(raw_grid, arg_name)
            % Validate a length grid/resolution scalar expressed in nm.
            grid = double(raw_grid);
            if ~(isscalar(grid) && isfinite(grid) && grid > 0)
                error("%s must be a finite positive scalar in nm.", string(arg_name));
            end
        end

        function grid = resolve_gds_resolution(raw_resolution, raw_snap_grid)
            % Resolve resolution argument from new/legacy aliases.
            has_resolution = isscalar(raw_resolution) && isfinite(raw_resolution);
            has_snap_grid = isscalar(raw_snap_grid) && isfinite(raw_snap_grid);

            if has_resolution && has_snap_grid
                resolution = core.GeometrySession.validate_length_grid(raw_resolution, "gds_resolution_nm");
                snap_grid = core.GeometrySession.validate_length_grid(raw_snap_grid, "snap_grid_nm");
                if abs(resolution - snap_grid) > 1e-12
                    warning("GeometrySession:GridAliasConflict", ...
                        "Both gds_resolution_nm (%.12g) and snap_grid_nm (%.12g) set; using gds_resolution_nm.", ...
                        resolution, snap_grid);
                end
                grid = resolution;
                return;
            end

            if has_resolution
                grid = core.GeometrySession.validate_length_grid(raw_resolution, "gds_resolution_nm");
                return;
            end

            if has_snap_grid
                grid = core.GeometrySession.validate_length_grid(raw_snap_grid, "snap_grid_nm");
                return;
            end

            grid = 1;
        end

        function ctx = current_context_store(varargin)
            % Persistent storage for current GeometrySession singleton.
            persistent current_ctx
            if nargin == 1
                current_ctx = varargin{1};
            end
            ctx = current_ctx;
        end

        function tbl = count_table(labels, first_col_name)
            % Aggregate counts for categorical labels.
            first_col_name = char(first_col_name);
            if isempty(labels)
                tbl = table(strings(0, 1), zeros(0, 1), ...
                    'VariableNames', {first_col_name, 'Count'});
                return;
            end
            [uniq, ~, idx] = unique(labels);
            count = accumarray(idx, 1);
            tbl = table(uniq, count, ...
                'VariableNames', {first_col_name, 'Count'});
        end

        function n = map_count(m)
            % Return number of keys in a dictionary.
            n = numel(keys(m));
        end

        function n = true_value_count(m)
            % Count true values in a logical-value dictionary.
            vals = values(m);
            if isempty(vals)
                n = 0;
                return;
            end
            n = sum(vals);
        end

        function tf = node_keeps_inputs(node)
            % Return true when node declares keep-input behavior.
            tf = false;
            if isprop(node, "keep_input_objects")
                try
                    v = node.keep_input_objects;
                    if isscalar(v)
                        tf = logical(v);
                        return;
                    end
                catch
                end
            end
            % Backward compatibility for legacy keep flag.
            if isprop(node, "keep")
                try
                    v = node.keep;
                    if isscalar(v)
                        tf = logical(v);
                    end
                catch
                end
            end
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
                stats = struct('count', 0, 'max_delta_nm', 0, 'grid_nm', obj.gds_resolution_nm);
            end

            stats.count = stats.count + numel(changed);
            stats.max_delta_nm = max(stats.max_delta_nm, max(changed));
            obj.snap_stats(key) = stats;
        end

        function report = node_report(obj)
            % Summarize node counts by type and layer.
            n = numel(obj.nodes);
            classes = strings(n, 1);
            layer_names = strings(n, 1);
            for i = 1:n
                node = obj.nodes{i};
                classes(i) = string(class(node));
                if isa(node.layer, "core.LayerSpec")
                    layer_names(i) = string(node.layer.name);
                else
                    layer_names(i) = string(node.layer);
                end
            end

            report = struct();
            report.total = n;
            report.by_type = core.GeometrySession.count_table(classes, "Type");
            report.by_layer = core.GeometrySession.count_table(layer_names, "Layer");
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
            report.cached_regions = core.GeometrySession.map_count(obj.gds_backend.regions);
            report.emitted_nodes = core.GeometrySession.true_value_count(obj.gds_backend.emitted);
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
            report.emitted_features = core.GeometrySession.map_count(obj.comsol_backend.feature_tags);
            report.selections = core.GeometrySession.map_count(obj.comsol_backend.selection_tags);
            report.snapped_expr_params = core.GeometrySession.map_count(obj.comsol_backend.snapped_length_tokens);
            report.defined_params = core.GeometrySession.map_count(obj.comsol_backend.defined_params);
        end
    end
end






