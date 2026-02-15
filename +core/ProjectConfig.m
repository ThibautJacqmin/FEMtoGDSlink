classdef ProjectConfig
    % Central runtime configuration loader for local installation paths.
    methods (Static)
        function cfg = load(args)
            % Load cached config, or reload from femtogds_config.m.
            arguments
                args.reload logical = false
            end

            if args.reload
                cfg = core.ProjectConfig.resolve_config();
                core.ProjectConfig.cache_store(cfg);
                return;
            end

            cfg = core.ProjectConfig.cache_store();
            if isempty(cfg)
                cfg = core.ProjectConfig.resolve_config();
                core.ProjectConfig.cache_store(cfg);
            end
        end
    end

    methods (Static, Access=private)
        function cfg = resolve_config()
            % Build effective config from defaults + optional local override.
            cfg = core.ProjectConfig.default_config();

            if exist("femtogds_config", "file") == 2
                user_cfg = femtogds_config();
                if ~isstruct(user_cfg)
                    error("ProjectConfig:InvalidUserConfig", ...
                        "femtogds_config must return a struct.");
                end
                cfg = core.ProjectConfig.merge_structs(cfg, user_cfg);
            end

            cfg = core.ProjectConfig.normalize_config(cfg);
        end

        function cfg = default_config()
            % Project defaults used when no local file is provided.
            cfg = struct();
            cfg.comsol = struct( ...
                "root", "", ...
                "host", "localhost", ...
                "port", 2036);
            cfg.klayout = struct( ...
                "root", "", ...
                "python_paths", strings(0, 1), ...
                "bin_paths", strings(0, 1));
        end

        function out = merge_structs(base, override)
            % Recursively merge override struct fields into base struct.
            out = base;
            f = fieldnames(override);
            for i = 1:numel(f)
                key = f{i};
                value = override.(key);
                if isfield(out, key) && isstruct(out.(key)) && isstruct(value)
                    out.(key) = core.ProjectConfig.merge_structs(out.(key), value);
                else
                    out.(key) = value;
                end
            end
        end

        function cfg = normalize_config(cfg)
            % Normalize expected field types.
            if ~isfield(cfg, "comsol") || ~isstruct(cfg.comsol)
                cfg.comsol = struct();
            end
            if ~isfield(cfg.comsol, "root"), cfg.comsol.root = ""; end
            if ~isfield(cfg.comsol, "host"), cfg.comsol.host = "localhost"; end
            if ~isfield(cfg.comsol, "port"), cfg.comsol.port = 2036; end
            cfg.comsol.root = string(cfg.comsol.root);
            cfg.comsol.host = string(cfg.comsol.host);
            cfg.comsol.port = double(cfg.comsol.port);

            if ~isfield(cfg, "klayout") || ~isstruct(cfg.klayout)
                cfg.klayout = struct();
            end
            if ~isfield(cfg.klayout, "root"), cfg.klayout.root = ""; end
            if ~isfield(cfg.klayout, "python_paths"), cfg.klayout.python_paths = strings(0, 1); end
            if ~isfield(cfg.klayout, "bin_paths"), cfg.klayout.bin_paths = strings(0, 1); end
            cfg.klayout.root = string(cfg.klayout.root);
            cfg.klayout.python_paths = string(cfg.klayout.python_paths(:));
            cfg.klayout.bin_paths = string(cfg.klayout.bin_paths(:));
        end

        function cfg = cache_store(varargin)
            % Persistent cache for the last resolved config.
            persistent cached_cfg
            if nargin == 1
                cached_cfg = varargin{1};
            end
            cfg = cached_cfg;
        end
    end
end
