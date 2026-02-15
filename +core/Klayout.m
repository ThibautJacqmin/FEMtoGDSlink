classdef Klayout < handle
    properties
        pya
    end
    methods
        function obj = Klayout
            % Load KLayout Python bindings, preferring direct modules.
            core.Klayout.configure_runtime_paths();
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
                        root + "\lib\site-packages"
                        root + "\python"
                        root + "\lib\python"
                        root + "\pymod"
                    ];
                    bin_paths = [ ...
                        root + "\bin"
                        root + "\lib"
                    ];
                else
                    python_paths = [ ...
                        root + "/lib/python"
                        root + "/lib/site-packages"
                        root + "/python"
                    ];
                    bin_paths = [ ...
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
            % Prefer direct KLayout modules over wrapper packages.
            direct_modules = {"pya", "klayout.db"};
            for i = 1:numel(direct_modules)
                try
                    pya_mod = py.importlib.import_module(direct_modules{i});
                    return;
                catch
                end
            end

            error("KLayout Python bindings not found. A valid pya handle is expected.");
        end

        function try_add_python_path(path_str)
            % Add one directory to Python sys.path (best effort).
            try
                sys_mod = py.importlib.import_module("sys");
                sys_mod.path.insert(int32(0), char(path_str));
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
    end
end
