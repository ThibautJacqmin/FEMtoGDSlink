classdef ComsolBootstrap
    % Bootstrap COMSOL Java API via LiveLink or direct Java path.
    methods (Static)
        function ensure_ready(args)
            % Ensure COMSOL Java API is reachable and optionally connected.
            arguments
                args.mode {mustBeTextScalar} = "auto"
                args.host {mustBeTextScalar} = "localhost"
                args.port double = 2036
                args.comsol_root {mustBeTextScalar} = ""
                args.connect logical = true
            end

            mode = lower(string(args.mode));
            if ~any(mode == ["auto", "livelink", "independent"])
                error("ComsolBootstrap:InvalidMode", ...
                    "mode must be 'auto', 'livelink', or 'independent'.");
            end

            if core.ComsolBootstrap.is_modelutil_ready()
                return;
            end

            switch mode
                case "livelink"
                    core.ComsolBootstrap.ensure_livelink( ...
                        host=args.host, port=args.port, connect=args.connect, comsol_root=args.comsol_root);
                case "independent"
                    core.ComsolBootstrap.ensure_independent( ...
                        host=args.host, port=args.port, comsol_root=args.comsol_root, connect=args.connect);
                otherwise
                    core.ComsolBootstrap.ensure_auto( ...
                        host=args.host, port=args.port, comsol_root=args.comsol_root, connect=args.connect);
            end

            if args.connect && ~core.ComsolBootstrap.is_modelutil_ready()
                error("ComsolBootstrap:NotReady", ...
                    "COMSOL Java API is not ready after bootstrap (mode='%s').", char(mode));
            end
        end
    end

    methods (Static, Access=private)
        function ensure_auto(args)
            % Try LiveLink first (if available), then independent Java path.
            arguments
                args.host {mustBeTextScalar}
                args.port double
                args.comsol_root {mustBeTextScalar}
                args.connect logical
            end

            try
                core.ComsolBootstrap.ensure_livelink( ...
                    host=args.host, port=args.port, connect=args.connect, comsol_root=args.comsol_root);
                return;
            catch first_err
                warning("ComsolBootstrap:AutoLiveLinkFailed", ...
                    "LiveLink bootstrap failed, falling back to independent mode: %s", ...
                        first_err.message);
            end

            try
                core.ComsolBootstrap.ensure_independent( ...
                    host=args.host, port=args.port, comsol_root=args.comsol_root, connect=args.connect);
            catch second_err
                msg = sprintf( ...
                    "Auto bootstrap failed. LiveLink failure: %s | Independent failure: %s", ...
                    first_err.message, second_err.message);
                error("ComsolBootstrap:AutoFailed", "%s", msg);
            end
        end

        function ensure_livelink(args)
            % Bootstrap via mphstart (LiveLink for MATLAB).
            arguments
                args.host {mustBeTextScalar}
                args.port double
                args.connect logical
                args.comsol_root {mustBeTextScalar} = ""
            end

            if core.ComsolBootstrap.is_modelutil_class_available() && ~args.connect
                return;
            end
            if core.ComsolBootstrap.is_modelutil_ready()
                return;
            end

            if isempty(which('mphstart'))
                root = core.ComsolBootstrap.resolve_comsol_root(args.comsol_root);
                if strlength(root) > 0
                    mli = fullfile(char(root), "mli");
                    if isfolder(mli)
                        addpath(mli);
                    end
                end
            end

            if isempty(which('mphstart'))
                error("ComsolBootstrap:LiveLinkMissing", ...
                    "mphstart not found (even after adding COMSOL mli path).");
            end

            if args.connect
                mphstart(char(string(args.host)), double(args.port));
            end
        end

        function ensure_independent(args)
            % Bootstrap by adding COMSOL Java API jars and connecting directly.
            arguments
                args.host {mustBeTextScalar}
                args.port double
                args.comsol_root {mustBeTextScalar}
                args.connect logical
            end

            try
                root = core.ComsolBootstrap.resolve_comsol_root(args.comsol_root);

                if strlength(root) == 0
                    error("ComsolBootstrap:ComsolRootNotFound", ...
                        "Could not discover COMSOL installation root.");
                end

                core.ComsolBootstrap.prepare_native_path(root);
                core.ComsolBootstrap.add_plugin_jars(root);

                if ~core.ComsolBootstrap.is_modelutil_class_available()
                    error("ComsolBootstrap:ModelUtilMissing", ...
                        "ModelUtil class not found after adding COMSOL plugin jars.");
                end

                if args.connect && ~core.ComsolBootstrap.is_modelutil_ready()
                    core.ComsolBootstrap.connect_modelutil(args.host, args.port);
                end
            catch ex
                if startsWith(string(ex.identifier), "ComsolBootstrap:")
                    rethrow(ex);
                end
                msg = sprintf( ...
                    "Direct Java bootstrap failed. This can happen when MATLAB JVM and COMSOL API class versions are incompatible. Details: %s", ...
                    ex.message);
                error("ComsolBootstrap:IndependentBootstrapFailed", "%s", msg);
            end
        end

        function connect_modelutil(host, port)
            % Connect ModelUtil to a running COMSOL server.
            arguments
                host {mustBeTextScalar}
                port double
            end
            com.comsol.model.util.ModelUtil.connect(char(string(host)), double(port));
        end

        function tf = is_modelutil_class_available()
            % Return true when ModelUtil class can be loaded.
            try
                tf = exist("com.comsol.model.util.ModelUtil", "class") == 8;
            catch
                tf = false;
            end
        end

        function tf = is_modelutil_ready()
            % Return true when ModelUtil API is available and connected.
            tf = false;
            if ~core.ComsolBootstrap.is_modelutil_class_available()
                return;
            end

            try
                com.comsol.model.util.ModelUtil.tags();
                tf = true;
            catch
            end
        end

        function root = discover_comsol_root()
            % Discover COMSOL root folder (Windows registry first).
            root = "";

            if ispc
                root = core.ComsolBootstrap.discover_comsol_root_windows();
                if strlength(root) > 0
                    return;
                end
            end

            % Fallback: common installation folders.
            guesses = [
                "C:\Program Files\COMSOL\COMSOL64\Multiphysics"
                "/usr/local/comsol/multiphysics"
                "/Applications/COMSOL/Multiphysics"
            ];
            for i = 1:numel(guesses)
                g = guesses(i);
                if isfolder(g)
                    root = g;
                    return;
                end
            end
        end

        function root = resolve_comsol_root(explicit_root)
            % Resolve COMSOL root from explicit input, config, then discovery.
            root = string(explicit_root);
            if strlength(root) > 0 && ~isfolder(root)
                warning("ComsolBootstrap:InvalidConfiguredRoot", ...
                    "Configured COMSOL root does not exist: %s", char(root));
                root = "";
            end

            if strlength(root) == 0
                try
                    cfg = core.ProjectConfig.load();
                    root = string(cfg.comsol.root);
                catch
                    root = "";
                end
                if strlength(root) > 0 && ~isfolder(root)
                    warning("ComsolBootstrap:InvalidConfiguredRoot", ...
                        "Configured COMSOL root does not exist: %s", char(root));
                    root = "";
                end
            end

            if strlength(root) == 0
                root = core.ComsolBootstrap.discover_comsol_root();
            end
        end

        function root = discover_comsol_root_windows()
            % Discover COMSOL root from HKLM\SOFTWARE\Comsol\*\COMSOLROOT.
            root = "";
            keys = [
                "HKLM\SOFTWARE\Comsol"
                "HKLM\SOFTWARE\WOW6432Node\Comsol"
            ];
            latest_stamp = -inf;

            for k = 1:numel(keys)
                base = keys(k);
                cmd = sprintf('reg query "%s" /s /v COMSOLROOT', char(base));
                [status, out] = system(cmd);
                if status ~= 0 || strlength(string(out)) == 0
                    continue;
                end

                lines = splitlines(string(out));
                current_subkey = "";
                for i = 1:numel(lines)
                    line = strtrim(lines(i));
                    if strlength(line) == 0
                        continue;
                    end
                    if startsWith(line, "HKEY_")
                        current_subkey = line;
                        continue;
                    end
                    if contains(line, "COMSOLROOT")
                        toks = regexp(char(line), '^COMSOLROOT\s+REG_\w+\s+(.+)$', ...
                            'tokens', 'once');
                        if isempty(toks)
                            continue;
                        end
                        candidate = string(strtrim(toks{1}));
                        if ~isfolder(candidate)
                            continue;
                        end
                        stamp = core.ComsolBootstrap.subkey_version_score(current_subkey);
                        if stamp > latest_stamp
                            latest_stamp = stamp;
                            root = candidate;
                        end
                    end
                end
            end
        end

        function score = subkey_version_score(subkey)
            % Build sortable numeric score from key text like COMSOL60.
            txt = lower(string(subkey));
            tok = regexp(char(txt), 'comsol(\d+)([a-z]?)', 'tokens', 'once');
            if isempty(tok)
                score = -inf;
                return;
            end
            major = str2double(tok{1});
            patch = 0;
            if ~isempty(tok{2})
                patch = double(tok{2}) - double('a') + 1;
            end
            score = major * 100 + patch;
        end

        function prepare_native_path(root)
            % Add COMSOL native library folder to PATH on Windows.
            root = string(root);
            if ~ispc
                return;
            end

            lib = root + "\lib\win64";
            if ~isfolder(lib)
                return;
            end

            path_env = string(getenv("PATH"));
            if contains(lower(path_env), lower(lib))
                return;
            end
            setenv("PATH", char(lib + ";" + path_env));
        end

        function add_plugin_jars(root)
            % Add all COMSOL plugin jars to MATLAB dynamic Java classpath.
            root = string(root);
            plugins = root + "\plugins";
            if ~isfolder(plugins)
                error("ComsolBootstrap:PluginsMissing", ...
                    "COMSOL plugins folder not found: %s", char(plugins));
            end

            jar_files = dir(fullfile(char(plugins), "*.jar"));
            if isempty(jar_files)
                error("ComsolBootstrap:NoPluginJars", ...
                    "No COMSOL plugin jars found in %s.", char(plugins));
            end

            dyn_cp = string(javaclasspath("-dynamic"));
            for i = 1:numel(jar_files)
                jar_path = string(fullfile(jar_files(i).folder, jar_files(i).name));
                if any(strcmpi(dyn_cp, jar_path))
                    continue;
                end
                javaaddpath(char(jar_path));
            end
        end
    end
end
