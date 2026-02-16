classdef ComsolMphModeler < handle
    % COMSOL modeler backed by Python MPh (no MATLAB LiveLink dependency).
    properties
        model_tag
        model
        component
        geometry
        workplane
        mesh
        shell
        study
        comsol_host
        comsol_port
        py_client
        py_model
        feature_counters
    end

    methods
        function obj = ComsolMphModeler(args)
            % Create a COMSOL model through Python MPh client.
            arguments
                args.comsol_host {mustBeTextScalar} = "localhost"
                args.comsol_port double = 2036
                args.strict_installed logical = true
            end

            core.ComsolMphModeler.ensure_mph_ready(strict_installed=args.strict_installed);
            obj.comsol_host = string(args.comsol_host);
            obj.comsol_port = double(args.comsol_port);
            obj.feature_counters = dictionary(string.empty(0,1), int32.empty(0,1));
            obj.py_client = core.ComsolMphModeler.ensure_client( ...
                host=obj.comsol_host, port=obj.comsol_port);
            obj.create_new_model();
        end

        function reset_workspace(obj)
            % Recreate a fresh model in the same MPh client/session.
            prior_tag = string(obj.model_tag);
            obj.dispose_model();
            obj.feature_counters = dictionary(string.empty(0,1), int32.empty(0,1));
            obj.create_new_model(model_tag=prior_tag);
            obj.mesh = [];
            obj.shell = [];
            obj.study = [];
        end

        function names = get_names(obj)
            % Return workplane child feature tags when available.
            names = strings(0, 1);
            try
                tags = obj.workplane.geom.tags();
                names = core.ComsolMphModeler.py_iter_to_strings(tags);
            catch
            end
        end

        function y = get_next_index(obj, name)
            % Return next index for a feature prefix.
            key = string(name);
            if ~isKey(obj.feature_counters, key)
                obj.feature_counters(key) = int32(0);
            end
            obj.feature_counters(key) = obj.feature_counters(key) + 1;
            y = double(obj.feature_counters(key));
        end

        function add_parameter(obj, value, name, unit)
            % Set one model parameter in COMSOL.
            arguments
                obj
                value
                name {mustBeTextScalar}
                unit {mustBeTextScalar} = ""
            end
            if isnumeric(value)
                value_str = string(value);
                if strlength(unit) ~= 0
                    value_str = value_str + "[" + string(unit) + "]";
                end
            else
                value_str = string(value);
            end
            obj.model.param.set(name, value_str, "");
        end

        function add_variable(obj, name, expression)
            % Define one variable under var1.
            arguments
                obj
                name {mustBeTextScalar}
                expression
            end
            var1_raw = obj.model.call_raw('variable', 'var1');
            var1 = core.MphProxy(var1_raw);
            var1.set(name, expression, "");
        end

        function start_gui(obj, args)
            % Launch COMSOL Desktop, optionally opening an MPH file.
            arguments
                obj core.ComsolMphModeler
                args.open_file {mustBeTextScalar} = ""
                args.export_current logical = true
                args.output_file {mustBeTextScalar} = ""
                args.connect_server logical = true
            end

            exe_path = "";
            launch_args = "";
            if args.connect_server
                exe_path = core.ComsolMphModeler.find_comsol_mphclient_executable();
                if strlength(exe_path) == 0
                    error("ComsolMphModeler:ComsolMphClientNotFound", ...
                        "Could not find COMSOL Multiphysics client executable from configured paths.");
                end
                launch_args = sprintf(' -server "%s" -port %d', ...
                    char(obj.comsol_host), round(double(obj.comsol_port)));
            else
                exe_path = core.ComsolMphModeler.find_comsol_executable();
                if strlength(exe_path) == 0
                    error("ComsolMphModeler:ComsolExecutableNotFound", ...
                        "Could not find COMSOL Desktop executable from configured paths.");
                end
            end

            target = string(args.open_file);
            if strlength(target) == 0 && args.export_current
                if strlength(string(args.output_file)) > 0
                    target = string(args.output_file);
                else
                    stamp = string(datestr(now, "yyyymmdd_HHMMSSFFF"));
                    target = fullfile(tempdir, "femtogds_gui_" + stamp + ".mph");
                end

                try
                    obj.model.save(char(target));
                catch ex
                    warning("ComsolMphModeler:GuiExportFailed", ...
                        "Could not export current model for GUI opening: %s", ex.message);
                    target = "";
                end
            end

            open_arg = "";
            if strlength(target) > 0
                if ~isfile(target)
                    warning("ComsolMphModeler:GuiOpenFileMissing", ...
                        "Requested open file does not exist: %s", char(target));
                else
                    open_arg = " -open """ + target + """";
                end
            end

            if ispc
                cmd = sprintf('start "" "%s"%s%s', char(exe_path), char(launch_args), char(open_arg));
            else
                cmd = sprintf('"%s"%s%s &', char(exe_path), char(launch_args), char(open_arg));
            end

            [status, out] = system(cmd);
            if status ~= 0
                error("ComsolMphModeler:GuiLaunchFailed", ...
                    "Failed to launch COMSOL Desktop (%s): %s", char(exe_path), string(out));
            end
        end

        function plot(obj)
            % Build geometry sequence (no desktop plotting in MPh mode).
            obj.geometry.run();
        end

        function save_to_m_file(obj, filename)
            % Export current model to COMSOL-generated MATLAB script.
            arguments
                obj core.ComsolMphModeler
                filename {mustBeTextScalar} = 'untitled.m'
            end
            obj.model.save(filename, 'm');
        end

        function comsol_object = create_comsol_object(obj, comsol_object_name)
            % Create a workplane feature with the default COMSOL tag prefix.
            prefix = obj.comsol_prefix(comsol_object_name);
            ind = obj.get_next_index(prefix);
            comsol_name = prefix + ind;
            comsol_object = obj.workplane.geom.create(comsol_name, comsol_object_name);
        end
    end

    methods (Static)
        function mph_mod = ensure_ready(args)
            % Ensure Python runtime and installed MPh package are available.
            arguments
                args.strict_installed logical = true
            end
            mph_mod = core.ComsolMphModeler.ensure_mph_ready( ...
                strict_installed=args.strict_installed);
        end

        function obj = shared(args)
            % Return shared MPh-backed modeler instance.
            arguments
                args.reset logical = true
                args.comsol_host {mustBeTextScalar} = "localhost"
                args.comsol_port double = 2036
                args.strict_installed logical = true
            end

            obj = core.ComsolMphModeler.shared_store();
            if isempty(obj) || ~isvalid(obj)
                obj = core.ComsolMphModeler( ...
                    comsol_host=args.comsol_host, ...
                    comsol_port=args.comsol_port, ...
                    strict_installed=args.strict_installed);
            else
                host_changed = obj.comsol_host ~= string(args.comsol_host);
                port_changed = obj.comsol_port ~= double(args.comsol_port);
                if host_changed || port_changed
                    obj = core.ComsolMphModeler( ...
                        comsol_host=args.comsol_host, ...
                        comsol_port=args.comsol_port, ...
                        strict_installed=args.strict_installed);
                elseif args.reset
                    obj.reset_workspace();
                end
            end
            core.ComsolMphModeler.shared_store(obj);
        end

        function clear_shared()
            % Clear shared modeler and remove its current model.
            obj = core.ComsolMphModeler.shared_store();
            if ~isempty(obj) && isvalid(obj)
                obj.dispose_model();
            end
            core.ComsolMphModeler.shared_store([]);
        end

        function removed = clear_generated_models(args)
            % Remove models named with the generated prefix from MPh client.
            arguments
                args.prefix {mustBeTextScalar} = "Model_"
            end
            removed = 0;
            entry = core.ComsolMphModeler.client_store();
            if isempty(entry)
                return;
            end
            client = entry.client;

            try
                models = py.list(client.models());
            catch
                return;
            end

            for i = 1:numel(models)
                mdl = models{i};
                name = core.ComsolMphModeler.py_scalar_to_string(mdl.name());
                if startsWith(name, string(args.prefix))
                    try
                        client.remove(mdl);
                        removed = removed + 1;
                    catch
                    end
                end
            end

            obj = core.ComsolMphModeler.shared_store();
            if ~isempty(obj) && isvalid(obj)
                if startsWith(string(obj.model_tag), string(args.prefix))
                    core.ComsolMphModeler.shared_store([]);
                end
            end
        end

        function y = comsol_prefix(comsol_object_name)
            % Return default 3-letter lowercase COMSOL feature prefix.
            y = lower(string(comsol_object_name).extractBetween(1, 3));
        end

        function names = py_iter_to_strings(iterable)
            % Convert Python iterable of string-like objects to MATLAB string.
            values = cell(py.list(iterable));
            names = strings(1, numel(values));
            for i = 1:numel(values)
                names(i) = core.ComsolMphModeler.py_scalar_to_string(values{i});
            end
        end

        function s = py_scalar_to_string(v)
            % Convert one Python scalar/string-like object to MATLAB string.
            try
                s = string(char(v));
                return;
            catch
            end
            try
                s = string(v);
            catch
                s = "";
            end
        end
    end

    methods (Access=private)
        function create_new_model(obj, args)
            % Allocate and initialize a fresh COMSOL model in MPh.
            arguments
                obj
                args.model_tag {mustBeTextScalar} = ""
            end

            requested = string(args.model_tag);
            if strlength(requested) == 0
                obj.model_tag = core.ComsolLivelinkModeler.next_model_tag();
            else
                obj.model_tag = requested;
            end
            obj.py_model = obj.py_client.create(char(obj.model_tag));
            bridge = core.ComsolMphModeler.bridge_module();
            java_model = bridge.model_java_handle(obj.py_model);
            obj.model = core.MphProxy(java_model);
            try
                obj.model.modelPath(pwd);
            catch
            end
            obj.initialize_workspace();
        end

        function initialize_workspace(obj)
            % Initialize variable/component/geometry/workplane defaults.
            obj.model.variable.create('var1');
            obj.component = obj.model.component.create('Component', true);
            obj.geometry = obj.component.geom.create('Geometry', int32(3));
            obj.geometry.lengthUnit("nm");
            obj.workplane = obj.geometry.create('wp1', 'WorkPlane');
            obj.geometry.feature('wp1').set('unite', true);
        end

        function dispose_model(obj)
            % Remove currently held model from the Python MPh client.
            if isempty(obj.py_client) || isempty(obj.py_model)
                return;
            end
            try
                obj.py_client.remove(obj.py_model);
            catch
            end
            obj.py_model = [];
            obj.model = [];
            obj.component = [];
            obj.geometry = [];
            obj.workplane = [];
        end
    end

    methods (Static, Access=private)
        function mph_mod = ensure_mph_ready(args)
            % Ensure Python and installed MPh are available.
            arguments
                args.strict_installed logical = true
            end

            try
                pe = pyenv();
            catch ex
                error("ComsolMphModeler:PyenvUnavailable", ...
                    "MATLAB Python bridge is unavailable: %s", ex.message);
            end

            if pe.Status == "NotLoaded"
                py.list();
            end

            try
                mph_mod = py.importlib.import_module('mph');
            catch ex
                error("ComsolMphModeler:MphImportFailed", ...
                    "Could not import Python package 'mph'. Install it in pyenv interpreter (%s): %s", ...
                    pe.Executable, ex.message);
            end

            if args.strict_installed
                module_file = string(char(py.getattr(mph_mod, "__file__")));
                local_repo = string(fullfile(pwd, "MPh"));
                if startsWith(lower(module_file), lower(local_repo))
                    error("ComsolMphModeler:LocalMphForbidden", ...
                        "Loaded local repo copy (%s). Install/use official Python package 'mph' instead.", ...
                        char(module_file));
                end
            end
        end

        function client = ensure_client(args)
            % Create/reuse one MPh client per MATLAB process.
            arguments
                args.host {mustBeTextScalar}
                args.port double
            end
            host = string(args.host);
            port = double(args.port);

            entry = core.ComsolMphModeler.client_store();
            needs_new = true;
            if ~isempty(entry)
                same_host = entry.host == host;
                same_port = entry.port == port;
                alive = core.ComsolMphModeler.client_alive(entry.client);
                needs_new = ~(same_host && same_port && alive);
                if needs_new
                    try
                        entry.client.disconnect();
                    catch
                    end
                end
            end

            if needs_new
                mph_mod = core.ComsolMphModeler.ensure_mph_ready(strict_installed=true);
                try
                    client = mph_mod.Client(pyargs('host', char(host), 'port', int32(port)));
                catch ex
                    if contains(string(ex.message), "Only one client can be instantiated")
                        try
                            bridge = core.ComsolMphModeler.bridge_module();
                            client = bridge.attach_existing_client(mph_mod, char(host), int32(port));
                        catch ex_attach
                            error("ComsolMphModeler:ClientConnectFailed", ...
                                "Failed to reuse existing MPh client at %s:%d: %s", ...
                                char(host), port, ex_attach.message);
                        end
                    else
                        error("ComsolMphModeler:ClientConnectFailed", ...
                            "Failed to connect MPh client to %s:%d: %s", ...
                            char(host), port, ex.message);
                    end
                end
                entry = struct('client', client, 'host', host, 'port', port);
                core.ComsolMphModeler.client_store(entry);
            else
                client = entry.client;
            end
        end

        function tf = client_alive(client)
            % Return true when the MPh client can query server tags.
            tf = false;
            try
                client.names();
                tf = true;
            catch
            end
        end

        function mod = bridge_module()
            % Import the MATLAB-safe Python bridge for JPype objects.
            persistent bridge_mod
            if ~isempty(bridge_mod)
                mod = bridge_mod;
                return;
            end

            module_name = "femtogds_mph_bridge";
            try
                bridge_mod = py.importlib.import_module(char(module_name));
            catch
                % Add project root to sys.path if MATLAB was started elsewhere.
                try
                    this_dir = fileparts(mfilename("fullpath"));
                    root_dir = fileparts(this_dir);
                    sys_mod = py.importlib.import_module("sys");
                    sys_mod.path.append(char(root_dir));
                catch
                end
                bridge_mod = py.importlib.import_module(char(module_name));
            end
            mod = bridge_mod;
        end

        function exe_path = find_comsol_executable()
            % Resolve COMSOL Desktop executable from config and PATH.
            exe_path = "";
            candidates = strings(0, 1);

            try
                cfg = core.ProjectConfig.load();
                root = string(cfg.comsol.root);
            catch
                root = "";
            end

            roots = strings(0, 1);
            if strlength(root) > 0
                roots = [roots; root];
                if endsWith(lower(root), lower("\Multiphysics")) || endsWith(lower(root), lower("/Multiphysics"))
                    roots = [roots; string(fileparts(char(root)))];
                end
            end
            roots = unique(roots(strlength(roots) > 0), "stable");

            for r = 1:numel(roots)
                rr = roots(r);
                if ispc
                    candidates = [candidates; ...
                        rr + "\bin\win64\comsol.exe"; ...
                        rr + "\bin\comsol.exe"; ...
                        rr + "\comsol.exe"];
                else
                    candidates = [candidates; ...
                        rr + "/bin/comsol"; ...
                        rr + "/comsol"];
                end
            end

            for i = 1:numel(candidates)
                if isfile(candidates(i))
                    exe_path = candidates(i);
                    return;
                end
            end

            if ispc
                [status, out] = system("where comsol.exe");
                if status == 0
                    lines = splitlines(string(out));
                    lines = strtrim(lines(lines ~= ""));
                    if ~isempty(lines) && isfile(lines(1))
                        exe_path = lines(1);
                        return;
                    end
                end
            else
                [status, out] = system("which comsol");
                if status == 0
                    hit = strtrim(string(out));
                    if strlength(hit) > 0 && isfile(hit)
                        exe_path = hit;
                        return;
                    end
                end
            end
        end

        function exe_path = find_comsol_mphclient_executable()
            % Resolve COMSOL mph client executable from config and PATH.
            exe_path = "";
            candidates = strings(0, 1);

            try
                cfg = core.ProjectConfig.load();
                root = string(cfg.comsol.root);
            catch
                root = "";
            end

            roots = strings(0, 1);
            if strlength(root) > 0
                roots = [roots; root];
                if endsWith(lower(root), lower("\Multiphysics")) || endsWith(lower(root), lower("/Multiphysics"))
                    roots = [roots; string(fileparts(char(root)))];
                end
            end
            roots = unique(roots(strlength(roots) > 0), "stable");

            for r = 1:numel(roots)
                rr = roots(r);
                if ispc
                    candidates = [candidates; ...
                        rr + "\bin\win64\comsolmphclient.exe"; ...
                        rr + "\bin\comsolmphclient.exe"; ...
                        rr + "\comsolmphclient.exe"];
                else
                    candidates = [candidates; ...
                        rr + "/bin/comsolmphclient"; ...
                        rr + "/comsolmphclient"];
                end
            end

            for i = 1:numel(candidates)
                if isfile(candidates(i))
                    exe_path = candidates(i);
                    return;
                end
            end

            if ispc
                [status, out] = system("where comsolmphclient.exe");
                if status == 0
                    lines = splitlines(string(out));
                    lines = strtrim(lines(lines ~= ""));
                    if ~isempty(lines) && isfile(lines(1))
                        exe_path = lines(1);
                        return;
                    end
                end
            else
                [status, out] = system("which comsolmphclient");
                if status == 0
                    hit = strtrim(string(out));
                    if strlength(hit) > 0 && isfile(hit)
                        exe_path = hit;
                        return;
                    end
                end
            end
        end

        function obj = shared_store(varargin)
            % Persistent storage for the shared MPh modeler.
            persistent shared_obj
            if nargin == 1
                shared_obj = varargin{1};
            end
            obj = shared_obj;
        end

        function entry = client_store(varargin)
            % Persistent storage for MPh client connection metadata.
            persistent client_entry
            if nargin == 1
                client_entry = varargin{1};
            end
            entry = client_entry;
        end
    end
end
