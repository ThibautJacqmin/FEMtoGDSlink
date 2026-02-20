classdef GeometrySession < handle
    % GeometrySession coordinates COMSOL and GDS backends and layer mapping.
    properties
        % Active COMSOL modeler instance (LiveLink or MPh) or [].
        comsol
        % Active in-memory GDS/KLayout modeler or [].
        gds
        % Dictionary: layer name -> core.LayerSpec.
        layers
        % Ordered geometry feature graph nodes.
        nodes
        % Dictionary: workplane tag -> {workplane handle}.
        comsol_workplanes
        % Dictionary: COMSOL feature prefix -> next integer counter.
        comsol_counters
        % Lazily-created COMSOL emitter backend.
        comsol_backend
        % Lazily-created KLayout/GDS emitter backend.
        gds_backend
        % Last assigned graph node id.
        node_counter
        % If true, emit COMSOL features incrementally on node creation.
        emit_on_create
        % Enable/disable grid snapping of length values.
        snap_on_grid
        % GDS database unit resolution in nm.
        gds_resolution_nm
        % Warn once per context when values are snapped.
        warn_on_snap
        % Dictionary tracking whether warning already emitted per snap context.
        snap_warned
        % Dictionary accumulating snap statistics per context.
        snap_stats
        % If true, enable live external KLayout preview updates.
        preview_klayout
        % True once preview process has been launched and acknowledged.
        preview_live_active
        % Temporary GDS file path watched by external preview.
        preview_live_filename
        % Ready-flag file path used for preview startup handshake.
        preview_live_readyfile
    end
    methods
        function obj = GeometrySession(args)
            % Build a geometry session and initialize enabled backends.
            arguments
                args.enable_comsol logical = true
                args.enable_gds logical = true
                args.comsol_emit_on_create logical = false
                args.snap_on_grid logical = true
                args.gds_resolution_nm double = NaN
                args.warn_on_snap logical = true
                args.preview_klayout logical = false
                args.launch_comsol_gui logical = false
                args.comsol_api {mustBeTextScalar} = "mph"
            end

            enable_comsol = args.enable_comsol;
            enable_gds = args.enable_gds;
            api = core.GeometrySession.normalize_comsol_api(args.comsol_api);
            cfg = core.ComsolModeler.connection_defaults();
            resolved_gds_nm = core.GeometrySession.resolve_gds_resolution( ...
                args.gds_resolution_nm);

            if enable_comsol
                if api == "mph"
                    obj.comsol = core.ComsolMphModeler( ...
                        comsol_host=cfg.host, comsol_port=cfg.port);
                else
                    obj.comsol = core.ComsolLivelinkModeler( ...
                        comsol_host=cfg.host, comsol_port=cfg.port, ...
                        comsol_root=cfg.root);
                end
            else
                obj.comsol = [];
            end

            if enable_gds
                obj.gds = core.GdsModeler(dbu_nm=resolved_gds_nm);
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
            obj.emit_on_create = args.comsol_emit_on_create;
            obj.snap_on_grid = logical(args.snap_on_grid);
            obj.gds_resolution_nm = resolved_gds_nm;
            obj.warn_on_snap = args.warn_on_snap;
            obj.snap_warned = dictionary(string.empty(0,1), false(0,1));
            obj.snap_stats = dictionary(string.empty(0,1), ...
                struct('count', 0, 'max_delta_nm', 0, 'grid_nm', obj.gds_resolution_nm));
            obj.preview_klayout = args.preview_klayout;
            obj.preview_live_active = false;
            obj.preview_live_filename = "";
            obj.preview_live_readyfile = "";

            % Always keep the latest session as process-global current context.
            core.GeometrySession.set_current(obj);

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
                args.comsol_workplane {mustBeTextScalar} = ""
                args.comsol_selection {mustBeTextScalar} = ""
                args.comsol_selection_state {mustBeTextScalar} = "all"
                args.comsol_enable_selection logical = true
            end
            % End-user API simplification: COMSOL emission is inferred from
            % whether a COMSOL workplane tag is provided on this layer.
            comsol_wp = string(args.comsol_workplane);
            comsol_emit = strlength(strtrim(comsol_wp)) > 0;
            layer = core.LayerSpec(name, ...
                gds_layer=args.gds_layer, ...
                gds_datatype=args.gds_datatype, ...
                comsol_workplane=comsol_wp, ...
                comsol_selection=args.comsol_selection, ...
                comsol_selection_state=args.comsol_selection_state, ...
                comsol_enable_selection=args.comsol_enable_selection, ...
                comsol_emit=comsol_emit);
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

            % Live KLayout preview: open and update as nodes are created.
            if obj.preview_klayout && obj.has_gds()
                obj.preview_live_step(feature);
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
            if strlength(strtrim(tag)) == 0
                error("Layer '%s' has no comsol_workplane; COMSOL emission is disabled for this layer.", ...
                    char(string(layer.name)));
            end
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

        function out = build(obj, args)
            % Build enabled backends in one call.
            %
            % Behavior:
            % - If GDS backend is enabled, export GDS.
            % - If COMSOL backend is enabled, emit COMSOL geometry.
            % - If report=true, print/return diagnostic report.
            %
            % When gds_filename is omitted, the default is:
            %   <caller_m_file_basename>.gds
            % and falls back to:
            %   <pwd>/femtogds_output.gds
            arguments
                obj core.GeometrySession
                args.gds_filename {mustBeTextScalar} = ""
                args.report logical = true
                args.report_display logical = true
            end

            out = struct();
            out.built_gds = false;
            out.built_comsol = false;
            out.gds_filename = "";
            out.report = struct();

            if obj.has_gds()
                gds_filename = string(args.gds_filename);
                if strlength(strtrim(gds_filename)) == 0
                    gds_filename = core.GeometrySession.default_gds_filename();
                end
                obj.export_gds(gds_filename);
                out.built_gds = true;
                out.gds_filename = gds_filename;
            end

            if obj.has_comsol()
                obj.build_comsol();
                out.built_comsol = true;
            end

            if args.report
                out.report = obj.build_report(display=args.report_display);
            end
        end

        function export_gds(obj, filename)
            % Emit graph to GDS backend and write layout to disk.
            % By default, only terminal (final) nodes are exported.
            arguments
                obj core.GeometrySession
                filename {mustBeTextScalar}
            end
            if ~obj.has_gds()
                error("GDS backend disabled.");
            end

            if obj.preview_klayout
                if obj.preview_live_active
                    obj.reset_and_init_gds_backend();
                    nodes_to_emit = obj.nodes;
                    obj.gds_backend.emit_all(nodes_to_emit);
                    obj.gds.write(filename);
                else
                    obj.preview_gds_build( ...
                        reset_layout=true, ...
                        zoom_fit=true, ...
                        show_all_cells=true, ...
                        output_filename=filename, ...
                        launch_external=true);
                end
                return;
            end

            obj.ensure_gds_backend();
            nodes_to_emit = obj.terminal_nodes;
            obj.gds_backend.emit_all(nodes_to_emit);
            obj.gds.write(filename);
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

        function open_klayout_gui(obj, args)
            % Open KLayout view for current in-memory GDS layout.
            arguments
                obj core.GeometrySession
                args.zoom_fit logical = true
                args.show_all_cells logical = true
            end
            if ~obj.has_gds()
                error("GDS backend disabled.");
            end
            obj.gds.open_gui(zoom_fit=args.zoom_fit, show_all_cells=args.show_all_cells);
        end

        function refresh_klayout_gui(obj, args)
            % Refresh KLayout view for current in-memory GDS layout.
            arguments
                obj core.GeometrySession
                args.zoom_fit logical = false
                args.show_all_cells logical = true
            end
            if ~obj.has_gds()
                error("GDS backend disabled.");
            end
            obj.gds.refresh_gui(zoom_fit=args.zoom_fit, show_all_cells=args.show_all_cells);
        end

        function preview_gds_build(obj, args)
            % Emit GDS geometry step-by-step and optionally launch KLayout preview.
            arguments
                obj core.GeometrySession
                args.reset_layout logical = true
                args.zoom_fit logical = true
                args.show_all_cells logical = true
                args.output_filename {mustBeTextScalar} = ""
                args.launch_external logical = false
            end
            if ~obj.has_gds()
                error("GDS backend disabled.");
            end

            output_filename = string(args.output_filename);
            if strlength(output_filename) == 0
                output_filename = fullfile(tempdir, "femtogds_preview.gds");
            end

            if args.reset_layout
                obj.reset_gds_layout();
            end
            obj.ensure_gds_backend();

            if obj.preview_klayout
                nodes_to_emit = obj.nodes;
            else
                nodes_to_emit = obj.terminal_nodes();
            end
            obj.gds.write(output_filename);

            if args.launch_external
                ready_file = fullfile(tempdir, "femtogds_klayout_ready.flag");
                if isfile(ready_file)
                    delete(ready_file);
                end
                obj.gds.launch_external_preview(output_filename, ...
                    zoom_fit=args.zoom_fit, ...
                    show_all_cells=args.show_all_cells, ...
                    ready_file=ready_file);

                t0 = tic;
                while toc(t0) < 6
                    if isfile(ready_file)
                        break;
                    end
                    pause(0.05);
                end
            end

            for i = 1:numel(nodes_to_emit)
                obj.gds_backend.emit(nodes_to_emit{i});
                obj.gds.write(output_filename);
                % Intentionally no pause: rely on file-based reload in KLayout.
            end

            if obj.preview_klayout
                obj.reset_and_init_gds_backend();
                final_nodes = nodes_to_emit;
                obj.gds_backend.emit_all(final_nodes);
                obj.gds.write(output_filename);
            end
        end

        function snapped = snap_length(obj, values, context)
            % Snap lengths to grid when snap_on_grid is enabled.
            arguments
                obj core.GeometrySession
                values
                context {mustBeTextScalar} = "geometry"
            end
            if ~obj.snap_on_grid
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
                "snap_on_grid", logical(obj.snap_on_grid), ...
                "gds_resolution_nm", obj.gds_resolution_nm, ...
                "warn_on_snap", obj.warn_on_snap);

            report.nodes = obj.node_report();
            report.gds = obj.gds_report();
            report.comsol = obj.comsol_report();
            report.snap = obj.snap_report(display=false);

            if args.display
                fprintf("Build Report (%s)\n", string(report.timestamp));
                fprintf("Session: COMSOL=%d, GDS=%d, snap_on_grid=%d, gds_resolution_nm=%g\n", ...
                    report.session.comsol_enabled, report.session.gds_enabled, ...
                    report.session.snap_on_grid, report.session.gds_resolution_nm);

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

        function ctx = with_shared_comsol(args)
            % Create a session using process-wide shared COMSOL modeler.
            % comsol_api:
            % - "livelink": MATLAB LiveLink modeler.
            % - "mph": Python MPh modeler (no LiveLink).
            arguments
                args.enable_comsol logical = true
                args.enable_gds logical = true
                args.emit_on_create logical = false
                args.snap_on_grid logical = true
                args.gds_resolution_nm double = NaN
                args.warn_on_snap logical = true
                args.preview_klayout logical = false
                args.reset_model logical = true
                args.launch_comsol_gui logical = false
                args.clean_on_reset logical = false
                args.comsol_api {mustBeTextScalar} = "mph"
            end

            api = core.GeometrySession.normalize_comsol_api(args.comsol_api);
            cfg = core.ComsolModeler.connection_defaults();
            shared_modeler = [];
            if args.enable_comsol
                if args.reset_model && args.clean_on_reset
                    core.GeometrySession.clean_comsol_server();
                end
                if api == "mph"
                    shared_modeler = core.ComsolMphModeler.shared( ...
                        reset=args.reset_model, ...
                        comsol_host=cfg.host, ...
                        comsol_port=cfg.port);
                else
                    shared_modeler = core.ComsolLivelinkModeler.shared( ...
                        reset=args.reset_model, ...
                        comsol_host=cfg.host, ...
                        comsol_port=cfg.port, ...
                        comsol_root=cfg.root);
                end
            end
            ctx = core.GeometrySession( ...
                enable_comsol=false, ...
                enable_gds=args.enable_gds, ...
                emit_on_create=args.emit_on_create, ...
                snap_on_grid=args.snap_on_grid, ...
                gds_resolution_nm=args.gds_resolution_nm, ...
                warn_on_snap=args.warn_on_snap, ...
                preview_klayout=args.preview_klayout, ...
                comsol_api=api, ...
                launch_comsol_gui=false);

            if args.enable_comsol
                ctx.comsol = shared_modeler;
                ctx.comsol_workplanes("wp1") = {ctx.comsol.workplane};
                if args.launch_comsol_gui
                    try
                        ctx.comsol.start_gui();
                    catch
                        warning("GeometrySession:GuiLaunch", ...
                            "Failed to launch/attach COMSOL Desktop automatically.");
                    end
                end
            end
        end

        function clear_shared_comsol()
            % Dispose and clear shared COMSOL model used by helper API.
            core.ComsolLivelinkModeler.clear_shared();
            try
                core.ComsolMphModeler.clear_shared();
            catch
            end
        end

        function removed = clean_comsol_server(args)
            % Remove generated COMSOL models from the server.
            % This intentionally does not clear the shared modeler handle.
            arguments
                args.prefix (1,1) string = "Model_"
            end
            removed = core.ComsolLivelinkModeler.clear_generated_models(prefix=args.prefix);
            try
                removed = removed + core.ComsolMphModeler.clear_generated_models(prefix=args.prefix);
            catch
            end
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
        function api = normalize_comsol_api(raw_api)
            % Validate COMSOL API selector.
            api = lower(string(raw_api));
            if ~any(api == ["mph", "livelink"])
                error("GeometrySession:InvalidComsolApi", ...
                    "comsol_api must be 'mph' or 'livelink'.");
            end
        end

        function grid = validate_length_grid(raw_grid, arg_name)
            % Validate a length grid/resolution scalar expressed in nm.
            grid = double(raw_grid);
            if ~(isscalar(grid) && isfinite(grid) && grid > 0)
                error("%s must be a finite positive scalar in nm.", string(arg_name));
            end
        end

        function grid = resolve_gds_resolution(raw_resolution)
            % Resolve GDS resolution argument.
            has_resolution = isscalar(raw_resolution) && isfinite(raw_resolution);

            if has_resolution
                grid = core.GeometrySession.validate_length_grid(raw_resolution, "gds_resolution_nm");
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

        function filename = default_gds_filename()
            % Derive default GDS filename from caller stack.
            %
            % Prefer the first non-core MATLAB file in the call stack and map:
            %   <path>/<name>.m -> <path>/<name>.gds
            % If no suitable file is found, fallback to current folder.
            fallback_name = "femtogds_output.gds";
            filename = string(fullfile(pwd, fallback_name));

            try
                st = dbstack("-completenames");
            catch
                return;
            end

            for i = 2:numel(st)
                file_i = string(st(i).file);
                if strlength(file_i) == 0 || ~endsWith(lower(file_i), ".m")
                    continue;
                end
                if contains(file_i, filesep + "+core" + filesep)
                    continue;
                end
                [folder_i, base_i, ~] = fileparts(char(file_i));
                filename = string(fullfile(folder_i, base_i + ".gds"));
                return;
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

        function reset_gds_layout(obj)
            % Reinitialize in-memory GDS modeler and clear backend caches.
            if ~obj.has_gds()
                error("GDS backend disabled.");
            end
            obj.gds = core.GdsModeler(dbu_nm=obj.gds_resolution_nm);
            obj.gds_backend = [];
        end

        function ensure_gds_backend(obj)
            % Lazily initialize GDS backend for current in-memory layout.
            if isempty(obj.gds_backend)
                obj.gds_backend = core.KlayoutBackend(obj);
            end
        end

        function reset_and_init_gds_backend(obj)
            % Recreate GDS modeler/backends and ensure backend is ready.
            obj.reset_gds_layout();
            obj.ensure_gds_backend();
        end

        function preview_live_step(obj, feature)
            % Incrementally update external KLayout preview after one node creation.
            if ~obj.has_gds()
                return;
            end

            obj.ensure_preview_live_started();
            if ~obj.preview_live_active
                return;
            end

            obj.ensure_gds_backend();
            obj.gds_backend.emit(feature);

            obj.gds.write(obj.preview_live_filename);
            % Intentionally no pause: keep live preview updates unthrottled.
        end

        function ensure_preview_live_started(obj)
            % Start external KLayout preview process once for this session.
            if obj.preview_live_active
                return;
            end
            if ~obj.preview_klayout || ~obj.has_gds()
                return;
            end

            if strlength(obj.preview_live_filename) == 0
                obj.preview_live_filename = string(tempname()) + ".gds";
            end
            if strlength(obj.preview_live_readyfile) == 0
                obj.preview_live_readyfile = string(tempname()) + ".flag";
            end
            if isfile(obj.preview_live_readyfile)
                delete(obj.preview_live_readyfile);
            end

            obj.gds.write(obj.preview_live_filename);
            obj.gds.launch_external_preview(obj.preview_live_filename, ...
                zoom_fit=true, ...
                show_all_cells=true, ...
                ready_file=obj.preview_live_readyfile);

            t0 = tic;
            while toc(t0) < 6
                if isfile(obj.preview_live_readyfile)
                    break;
                end
                pause(0.05);
            end
            obj.preview_live_active = true;
        end
    end
end
