classdef GDSModeler < core.Klayout
    properties
        pylayout
        pycell
        shapes
        dbu_nm
        pylay
        pyview
        pyview_cellview_index
    end
    methods
        function obj = GDSModeler(args)
            arguments
                args.dbu_nm double = 1
            end
            dbu_nm = double(args.dbu_nm);
            if ~(isscalar(dbu_nm) && isfinite(dbu_nm) && dbu_nm > 0)
                error("GDSModeler:InvalidDbuNm", ...
                    "dbu_nm must be a finite positive scalar in nm.");
            end
            obj.dbu_nm = dbu_nm;

            % Create layout
            obj.pylayout = obj.pya.Layout();
            % KLayout dbu is in um.
            obj.pylayout.dbu = obj.dbu_nm * 1e-3;

            % Create cell
            obj.pycell = obj.pylayout.create_cell("Main");
            obj.shapes = {};
            obj.pylay = [];
            obj.pyview = [];
            obj.pyview_cellview_index = int32(-1);
        end
        function py_layer = create_layer(obj, number, datatype)
            if nargin < 3
                py_layer = obj.pylayout.layer(string(number));
            else
                py_layer = obj.pylayout.layer(int32(number), int32(datatype));
            end
        end
        function add_to_layer(obj, layer, shape, klayout_cell)
            % Last argument allows to add to a different cell than the main
            % one. Useful for arrays, for which an intermediate cell
            % is needed.
            arguments
                obj
                layer
                shape
                klayout_cell = obj.pycell
            end
            shape.layer = layer;
            klayout_cell.shapes(layer).insert(shape.pgon_py);
            obj.shapes{end+1}.layer = int8(layer);
            obj.shapes{end}.shape = shape;
        end
        function delete_layer(obj, layer)
            obj.pylayout.delete_layer(layer);
        end
        function write(obj, filename)
            obj.pylayout.write(filename);
        end

        function tf = has_gui_support(obj)
            % Return true when KLayout Desktop application API is available.
            tf = false;
            try
                lay = obj.get_lay_module();
                if ~py.hasattr(lay, "Application")
                    return;
                end
                app = lay.Application.instance();
                if isa(app, "py.NoneType")
                    return;
                end
                if py.hasattr(app, "main_window")
                    mw = app.main_window();
                    tf = ~isa(mw, "py.NoneType");
                end
            catch
            end
        end

        function open_gui(obj, args)
            % Open a KLayout LayoutView bound to the current layout object.
            arguments
                obj
                args.zoom_fit logical = true
                args.show_all_cells logical = true
            end

            if ~obj.has_gui_support()
                error("GDSModeler:KlayoutGuiUnavailable", "%s", ...
                    "KLayout GUI is unavailable in the current Python runtime. " + ...
                    "The loaded module provides geometry APIs but no desktop Application/main window.");
            end

            lay = obj.get_lay_module();
            if isempty(obj.pyview)
                try
                    obj.pyview = lay.LayoutView();
                catch ex
                    error("GDSModeler:KlayoutGuiOpenFailed", ...
                        "Could not create KLayout LayoutView: %s", ex.message);
                end
            end

            try
                cv = obj.pyview.show_layout(obj.pylayout, false);
                obj.pyview_cellview_index = int32(double(cv));
            catch ex
                error("GDSModeler:KlayoutGuiOpenFailed", ...
                    "Could not attach layout to KLayout LayoutView: %s", ex.message);
            end

            obj.refresh_gui(zoom_fit=args.zoom_fit, show_all_cells=args.show_all_cells);
        end

        function refresh_gui(obj, args)
            % Refresh the currently opened KLayout view (best effort).
            arguments
                obj
                args.zoom_fit logical = false
                args.show_all_cells logical = true
            end

            if isempty(obj.pyview)
                return;
            end

            if args.show_all_cells
                try
                    obj.pyview.show_all_cells();
                catch
                end
            end
            try
                obj.pyview.max_hier();
            catch
            end
            if args.zoom_fit
                try
                    obj.pyview.zoom_fit();
                catch
                end
            end
        end

        function close_gui(obj)
            % Close and clear GUI handles.
            obj.pyview = [];
            obj.pyview_cellview_index = int32(-1);
        end

        function launch_external_gui(obj, gds_filename)
            % Launch standalone KLayout Desktop with a GDS file.
            arguments
                obj
                gds_filename {mustBeTextScalar}
            end

            exe_path = obj.find_klayout_executable();
            if strlength(exe_path) == 0
                error("GDSModeler:KlayoutExecutableNotFound", ...
                    "Could not find a KLayout desktop executable from configured paths.");
            end

            target = string(gds_filename);
            if ~isfile(target)
                error("GDSModeler:MissingGdsFile", ...
                    "Cannot launch KLayout: file does not exist (%s).", char(target));
            end

            if ispc
                cmd = sprintf('start "" "%s" "%s"', char(exe_path), char(target));
            else
                cmd = sprintf('"%s" "%s" &', char(exe_path), char(target));
            end

            [status, out] = system(cmd);
            if status ~= 0
                error("GDSModeler:KlayoutLaunchFailed", ...
                    "Failed to launch KLayout executable (%s): %s", char(exe_path), string(out));
            end
        end

        function launch_external_preview(obj, gds_filename, args)
            % Launch standalone KLayout Desktop with an auto-reload preview script.
            arguments
                obj
                gds_filename {mustBeTextScalar}
                args.refresh_interval_ms double = 120
                args.zoom_fit logical = true
                args.show_all_cells logical = true
                args.ready_file {mustBeTextScalar} = ""
            end

            exe_path = obj.find_klayout_executable();
            if strlength(exe_path) == 0
                error("GDSModeler:KlayoutExecutableNotFound", ...
                    "Could not find a KLayout desktop executable from configured paths.");
            end

            script_path = fullfile(core.GDSModeler.get_folder(), "klayout_preview_bridge.py");
            if ~isfile(script_path)
                error("GDSModeler:KlayoutPreviewScriptMissing", ...
                    "KLayout preview script not found: %s", script_path);
            end

            target = string(gds_filename);
            if ~isfile(target)
                error("GDSModeler:MissingGdsFile", ...
                    "Cannot launch KLayout preview: file does not exist (%s).", char(target));
            end

            refresh_ms = max(20, round(double(args.refresh_interval_ms)));
            zoom_flag = core.GDSModeler.bool_flag(args.zoom_fit);
            show_all_flag = core.GDSModeler.bool_flag(args.show_all_cells);
            ready_file = string(args.ready_file);

            if ispc
                cmd = sprintf([ ...
                    'start "" "%s" -rr "%s" -rd "preview_gds_file=%s" ' ...
                    '-rd "preview_refresh_ms=%d" -rd "preview_zoom_fit=%s" ' ...
                    '-rd "preview_show_all=%s"'], ...
                    char(exe_path), char(string(script_path)), char(target), ...
                    refresh_ms, char(zoom_flag), char(show_all_flag));
                if strlength(ready_file) > 0
                    cmd = sprintf('%s -rd "preview_ready_file=%s"', cmd, char(ready_file));
                end
            else
                cmd = sprintf([ ...
                    '"%s" -rr "%s" -rd "preview_gds_file=%s" ' ...
                    '-rd "preview_refresh_ms=%d" -rd "preview_zoom_fit=%s" ' ...
                    '-rd "preview_show_all=%s"'], ...
                    char(exe_path), char(string(script_path)), char(target), ...
                    refresh_ms, char(zoom_flag), char(show_all_flag));
                if strlength(ready_file) > 0
                    cmd = sprintf('%s -rd "preview_ready_file=%s"', cmd, char(ready_file));
                end
                cmd = sprintf('%s &', cmd);
            end

            [status, out] = system(cmd);
            if status ~= 0
                error("GDSModeler:KlayoutPreviewLaunchFailed", ...
                    "Failed to launch KLayout preview (%s): %s", char(exe_path), string(out));
            end
        end
        function mark = add_alignment_mark(obj, args)
            arguments
                obj
                args.type = 1
            end
            data = load(fullfile(obj.get_folder, "Library", "alignment_mark_type_" + num2str(args.type) +".mat"));
            mark = primitives.Polygon;
            mark.pgon_py = obj.pya.Region();
            for fieldname=string(fieldnames(data))'
                mark.pgon_py.insert(obj.pya.Polygon.from_s(core.KlayoutCodec.vertices_to_klayout_string(data.(fieldname)*1e3)));
            end
            mark.vertices = types.Vertices(core.KlayoutCodec.get_vertices_from_klayout(mark.pgon_py));
        end
        function two_inch_wafer = add_two_inch_wafer(obj)
            arguments
                obj
            end
            data = load(fullfile(obj.get_folder, "Library", "two_inch_wafer.mat"));
            two_inch_wafer = primitives.Polygon;
            two_inch_wafer.pgon_py = obj.pya.Region();
            two_inch_wafer.pgon_py.insert(obj.pya.Polygon.from_s(core.KlayoutCodec.vertices_to_klayout_string(data.wafer_edge*1e3)));
            two_inch_wafer.vertices = types.Vertices(core.KlayoutCodec.get_vertices_from_klayout(two_inch_wafer.pgon_py));
        end


    end
    methods (Access=private)
        function lay = get_lay_module(obj)
            % Load KLayout Application API module for GUI operations.
            if ~isempty(obj.pylay)
                lay = obj.pylay;
                return;
            end

            lay_modules = {"klayout.lay", "lay"};
            for i = 1:numel(lay_modules)
                try
                    lay = py.importlib.import_module(lay_modules{i});
                    obj.pylay = lay;
                    return;
                catch
                end
            end

            error("GDSModeler:KlayoutLayMissing", ...
                "KLayout Application API module not found (expected 'klayout.lay').");
        end

        function exe_path = find_klayout_executable(~)
            % Resolve KLayout desktop executable path from config and PATH.
            exe_path = "";
            candidates = strings(0, 1);

            try
                cfg = core.ProjectConfig.load();
                root = string(cfg.klayout.root);
            catch
                root = "";
            end

            if strlength(root) > 0
                if ispc
                    candidates = [candidates; ...
                        root + "\klayout_app.exe"; ...
                        root + "\klayout.exe"; ...
                        root + "\bin\klayout_app.exe"; ...
                        root + "\bin\klayout.exe"; ...
                        root + "\klayout_vo_app.exe"];
                else
                    candidates = [candidates; ...
                        root + "/bin/klayout"; ...
                        root + "/klayout"];
                end
            end

            for i = 1:numel(candidates)
                if isfile(candidates(i))
                    exe_path = candidates(i);
                    return;
                end
            end

            if ispc
                [status, out] = system("where klayout_app.exe");
                if status == 0
                    lines = splitlines(string(out));
                    lines = strtrim(lines(lines ~= ""));
                    if ~isempty(lines) && isfile(lines(1))
                        exe_path = lines(1);
                        return;
                    end
                end
                [status, out] = system("where klayout.exe");
                if status == 0
                    lines = splitlines(string(out));
                    lines = strtrim(lines(lines ~= ""));
                    if ~isempty(lines) && isfile(lines(1))
                        exe_path = lines(1);
                        return;
                    end
                end
            end
        end
    end
    methods (Static)
        function y = get_folder
            s = string(mfilename('fullpath'));
            m = mfilename;
            y = s.erase(m);
        end

        function y = bool_flag(tf)
            if tf
                y = "1";
            else
                y = "0";
            end
        end
    end
end
