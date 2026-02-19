classdef GdsModeler < handle
    properties
        % Imported KLayout geometry module (`pya`/`klayout.db`).
        pya
        % KLayout `Layout` instance holding current in-memory design.
        pylayout
        % Main top cell used for default shape insertion.
        pycell
        % MATLAB-side bookkeeping of inserted shapes by layer.
        shapes
        % Database unit resolution in nanometers.
        dbu_nm
        % Imported KLayout Application API module for GUI features (`klayout.lay`).
        pylay
        % Optional GUI LayoutView handle for embedded preview mode.
        pyview
        % Cellview index currently displayed in `pyview`.
        pyview_cellview_index
    end
    methods
        function obj = GdsModeler(args)
            % Construct an in-memory KLayout layout wrapper.
            arguments
                args.dbu_nm double = 1
            end
            dbu_nm = double(args.dbu_nm);
            if ~(isscalar(dbu_nm) && isfinite(dbu_nm) && dbu_nm > 0)
                error("GdsModeler:InvalidDbuNm", ...
                    "dbu_nm must be a finite positive scalar in nm.");
            end
            obj.dbu_nm = dbu_nm;
            obj.pya = core.GdsModeler.import_pya();

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
            % Create/resolve one layout layer handle from number/datatype.
            if nargin < 3
                py_layer = obj.pylayout.layer(string(number));
            else
                py_layer = obj.pylayout.layer(int32(number), int32(datatype));
            end
        end
        function add_to_layer(obj, layer, shape, klayout_cell)
            % Insert one shape region into a layer of the target cell.
            % Last argument allows insertion into a non-main cell, useful
            % for array helper cells.
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
            % Remove one layer and its shapes from the in-memory layout.
            obj.pylayout.delete_layer(layer);
        end
        function write(obj, filename)
            % Serialize current layout to a GDS file on disk.
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
                error("GdsModeler:KlayoutGuiUnavailable", "%s", ...
                    "KLayout GUI is unavailable in the current Python runtime. " + ...
                    "The loaded module provides geometry APIs but no desktop Application/main window.");
            end

            lay = obj.get_lay_module();
            if isempty(obj.pyview)
                try
                    obj.pyview = lay.LayoutView();
                catch ex
                    error("GdsModeler:KlayoutGuiOpenFailed", ...
                        "Could not create KLayout LayoutView: %s", ex.message);
                end
            end

            try
                cv = obj.pyview.show_layout(obj.pylayout, false);
                obj.pyview_cellview_index = int32(double(cv));
            catch ex
                error("GdsModeler:KlayoutGuiOpenFailed", ...
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
                error("GdsModeler:KlayoutExecutableNotFound", ...
                    "Could not find a KLayout desktop executable from configured paths.");
            end

            target = string(gds_filename);
            if ~isfile(target)
                error("GdsModeler:MissingGdsFile", ...
                    "Cannot launch KLayout: file does not exist (%s).", char(target));
            end

            if ispc
                cmd = sprintf('start "" "%s" "%s"', char(exe_path), char(target));
            else
                cmd = sprintf('"%s" "%s" &', char(exe_path), char(target));
            end

            [status, out] = system(cmd);
            if status ~= 0
                error("GdsModeler:KlayoutLaunchFailed", ...
                    "Failed to launch KLayout executable (%s): %s", char(exe_path), string(out));
            end
        end

        function launch_external_preview(obj, gds_filename, args)
            % Launch standalone KLayout Desktop with an auto-reload preview script.
            arguments
                obj
                gds_filename {mustBeTextScalar}
                args.zoom_fit logical = true
                args.show_all_cells logical = true
                args.ready_file {mustBeTextScalar} = ""
            end

            exe_path = obj.find_klayout_executable();
            if strlength(exe_path) == 0
                error("GdsModeler:KlayoutExecutableNotFound", ...
                    "Could not find a KLayout desktop executable from configured paths.");
            end

            % Python preview bridge is maintained under python/.
            repo_root = fileparts(core.GdsModeler.get_folder());
            script_path = fullfile(repo_root, "python", "klayout_preview_bridge.py");
            if ~isfile(script_path)
                % Backward-compatible fallback for older tree layouts.
                script_path = fullfile(repo_root, "+python", "klayout_preview_bridge.py");
            end
            if ~isfile(script_path)
                % Legacy fallback when the script lived directly under +core.
                script_path = fullfile(core.GdsModeler.get_folder(), "klayout_preview_bridge.py");
            end
            if ~isfile(script_path)
                error("GdsModeler:KlayoutPreviewScriptMissing", ...
                    "KLayout preview script not found: %s", script_path);
            end

            target = string(gds_filename);
            if ~isfile(target)
                error("GdsModeler:MissingGdsFile", ...
                    "Cannot launch KLayout preview: file does not exist (%s).", char(target));
            end

            % Preview bridge polling interval: keep small and fixed so updates
            % are responsive without exposing a timing knob to end users.
            refresh_ms = 20;
            zoom_flag = core.GdsModeler.bool_flag(args.zoom_fit);
            show_all_flag = core.GdsModeler.bool_flag(args.show_all_cells);
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
                error("GdsModeler:KlayoutPreviewLaunchFailed", ...
                    "Failed to launch KLayout preview (%s): %s", char(exe_path), string(out));
            end
        end
        function mark = add_alignment_mark(obj, args)
            % Load one packaged alignment mark polygon from library files.
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
            % Load packaged two-inch wafer edge polygon from library file.
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

            error("GdsModeler:KlayoutLayMissing", ...
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
    methods (Static, Access=private)
        function configure_runtime_paths()
            % Configure Python and DLL lookup paths from project config.
            try
                cfg = core.ProjectConfig.load();
            catch
                return;
            end

            root = string(cfg.klayout.root);
            python_paths = strings(0, 1);
            bin_paths = strings(0, 1);

            if strlength(root) > 0 && isfolder(root)
                if ispc
                    python_paths = [ ...
                        root + "\pymod"
                        root + "\python"
                        root + "\lib\python"
                        root + "\lib\site-packages"
                    ];
                    python_paths = [python_paths; core.GdsModeler.find_versioned_python_paths(root + "\lib")];
                    bin_paths = [ ...
                        root
                        root + "\bin"
                        root + "\lib"
                    ];
                else
                    python_paths = [ ...
                        root + "/pymod"
                        root + "/python"
                        root + "/lib/python"
                        root + "/lib/site-packages"
                    ];
                    python_paths = [python_paths; core.GdsModeler.find_versioned_python_paths(root + "/lib")];
                    bin_paths = [ ...
                        root
                        root + "/bin"
                        root + "/lib"
                    ];
                end
            end

            python_paths = [python_paths; string(cfg.klayout.python_paths(:))];
            bin_paths = [bin_paths; string(cfg.klayout.bin_paths(:))];

            python_paths = unique(python_paths(strlength(python_paths) > 0), "stable");
            bin_paths = unique(bin_paths(strlength(bin_paths) > 0), "stable");

            for i = 1:numel(python_paths)
                p = python_paths(i);
                if isfolder(p)
                    core.GdsModeler.try_add_python_path(p);
                end
            end

            for i = 1:numel(bin_paths)
                p = bin_paths(i);
                if isfolder(p)
                    core.GdsModeler.try_add_process_path(p);
                    core.GdsModeler.try_add_dll_directory(p);
                end
            end
        end

        function pya_mod = import_pya()
            % Prefer already-importable Python modules before path injection.
            [pya_mod, ok, details] = core.GdsModeler.try_import_modules();
            if ok
                return;
            end

            core.GdsModeler.configure_runtime_paths();
            [pya_mod, ok, details] = core.GdsModeler.try_import_modules();
            if ok
                return;
            end

            diag = core.GdsModeler.format_import_diagnostic(details);
            if strlength(diag) == 0
                error("KLayout Python bindings not found. A valid pya handle is expected.");
            end
            error("KLayout Python bindings not found. A valid pya handle is expected. %s", char(diag));
        end

        function try_add_python_path(path_str)
            % Add one directory to Python sys.path (best effort).
            try
                sys_mod = py.importlib.import_module("sys");
                sys_mod.path.append(char(path_str));
            catch
            end
        end

        function try_add_process_path(path_str)
            % Prepend directory to process PATH (best effort, Windows only).
            if ~ispc
                return;
            end
            try
                current_path = string(getenv("PATH"));
                if contains(lower(current_path), lower(path_str))
                    return;
                end
                setenv("PATH", char(path_str + ";" + current_path));
            catch
            end
        end

        function try_add_dll_directory(path_str)
            % Register directory for DLL loading in Python (best effort).
            if ~ispc
                return;
            end
            try
                os_mod = py.importlib.import_module("os");
                if py.hasattr(os_mod, "add_dll_directory")
                    os_mod.add_dll_directory(char(path_str));
                end
            catch
            end
        end

        function paths = find_versioned_python_paths(lib_root)
            % Discover versioned lib/pythonX.Y paths shipped by KLayout.
            paths = strings(0, 1);
            if strlength(lib_root) == 0 || ~isfolder(lib_root)
                return;
            end

            candidates = dir(fullfile(char(lib_root), "python*"));
            for i = 1:numel(candidates)
                entry = candidates(i);
                if ~entry.isdir
                    continue;
                end
                base = string(fullfile(entry.folder, entry.name));
                paths = [paths; base; base + string(filesep) + "site-packages"; ...
                    base + string(filesep) + "lib-dynload"]; %#ok<AGROW>
            end
        end

        function [pya_mod, ok, details] = try_import_modules()
            % Try importing supported KLayout Python entry points.
            pya_mod = [];
            ok = false;
            details = strings(0, 1);

            direct_modules = {"pya", "klayout.db"};
            for i = 1:numel(direct_modules)
                name = string(direct_modules{i});
                try
                    pya_mod = py.importlib.import_module(char(name));
                    ok = true;
                    return;
                catch ex
                    details(end+1, 1) = name + ": " + string(ex.message); %#ok<AGROW>
                end
            end

            try
                mod = py.importlib.import_module("lygadgets");
                if logical(py.hasattr(mod, "pya")) && ~isa(mod.pya, "py.NoneType")
                    pya_mod = mod.pya;
                    ok = true;
                    return;
                end
                details(end+1, 1) = "lygadgets: module found but pya handle is missing."; %#ok<AGROW>
            catch ex
                details(end+1, 1) = "lygadgets: " + string(ex.message); %#ok<AGROW>
            end
        end

        function diag = format_import_diagnostic(details)
            % Create a compact diagnostic for KLayout import failures.
            diag = "";
            try
                pe = pyenv();
                py_info = "Python " + string(pe.Version) + " (" + string(pe.Executable) + ")";
                diag = py_info;
            catch
            end

            if ~isempty(details)
                attempts = "Import attempts: " + strjoin(cellstr(details), " | ");
                if strlength(diag) > 0
                    diag = diag + ". " + attempts;
                else
                    diag = attempts;
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

