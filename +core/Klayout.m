classdef Klayout < handle
    properties
        pya
    end
    methods
        function obj = Klayout
            % Load KLayout Python bindings.
            obj.pya = core.Klayout.import_pya();
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
                    python_paths = [python_paths; core.Klayout.find_versioned_python_paths(root + "\lib")];
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
                    python_paths = [python_paths; core.Klayout.find_versioned_python_paths(root + "/lib")];
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
                    core.Klayout.try_add_python_path(p);
                end
            end

            for i = 1:numel(bin_paths)
                p = bin_paths(i);
                if isfolder(p)
                    core.Klayout.try_add_process_path(p);
                    core.Klayout.try_add_dll_directory(p);
                end
            end
        end

        function pya_mod = import_pya()
            % Prefer already-importable Python modules before path injection.
            [pya_mod, ok, details] = core.Klayout.try_import_modules();
            if ok
                return;
            end

            core.Klayout.configure_runtime_paths();
            [pya_mod, ok, details] = core.Klayout.try_import_modules();
            if ok
                return;
            end

            diag = core.Klayout.format_import_diagnostic(details);
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
end
