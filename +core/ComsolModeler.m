classdef (Abstract) ComsolModeler < handle
    % Shared COMSOL modeler utilities for LiveLink and MPh backends.
    properties
        % Top-level COMSOL model tag.
        model_tag
        % COMSOL model handle/proxy object.
        model
        % Default COMSOL component handle.
        component
        % Default COMSOL geometry handle.
        geometry
        % Default 2D workplane feature handle (`wp1`).
        workplane
        % Optional mesh handle if configured by higher-level code.
        mesh
        % Optional shell/physics handle if configured by higher-level code.
        shell
        % Optional study handle if configured by higher-level code.
        study
    end

    methods
        function add_parameter(obj, value, name, unit, description)
            % Set one model parameter, converting numeric values to tokens.
            arguments
                obj
                value
                name {mustBeTextScalar}
                unit {mustBeTextScalar} = ""
                description {mustBeTextScalar} = ""
            end

            value_str = core.ComsolModeler.parameter_value_string(value, unit);
            obj.model.param.set(name, value_str, description);
        end

        function comsol_object = create_comsol_object(obj, comsol_object_name)
            % Create a workplane feature using a standard COMSOL tag prefix.
            prefix = core.ComsolModeler.comsol_prefix(comsol_object_name);
            ind = obj.get_next_index(prefix);
            comsol_name = prefix + ind;
            comsol_object = obj.workplane.geom.create(comsol_name, comsol_object_name);
        end
    end

    methods (Access=protected)
        function initialize_workspace(obj, args)
            % Initialize default variable/component/geometry/workplane nodes.
            arguments
                obj
                args.geom_dim double = 3
            end

            obj.model.variable.create('var1');
            obj.component = obj.model.component.create('Component', true);
            obj.geometry = obj.component.geom.create('Geometry', int32(args.geom_dim));
            obj.geometry.lengthUnit("nm");
            obj.workplane = obj.geometry.create('wp1', 'WorkPlane');
            obj.geometry.feature('wp1').set('unite', true);
            obj.mesh = [];
            obj.shell = [];
            obj.study = [];
        end
    end

    methods (Abstract)
        names = get_names(obj)
        y = get_next_index(obj, name)
    end

    methods (Static)
        function tag = next_model_tag()
            % Generate a unique COMSOL model tag for new sessions.
            stamp = string(datetime("now", Format="yyyyMMdd_HHmmssSSS"));
            suffix = string(randi([0, 9999]));
            tag = "Model_" + stamp + "_" + suffix;
        end

        function y = comsol_prefix(comsol_object_name)
            % Return default 3-letter lowercase COMSOL feature prefix.
            y = lower(string(comsol_object_name).extractBetween(1, 3));
        end

        function cfg = connection_defaults()
            % Load COMSOL host/port/root defaults with ProjectConfig fallback.
            cfg = struct("host", "localhost", "port", 2036, "root", "");
            try
                loaded = core.ProjectConfig.load();
                if isfield(loaded, "comsol") && isstruct(loaded.comsol)
                    if isfield(loaded.comsol, "host")
                        cfg.host = string(loaded.comsol.host);
                    end
                    if isfield(loaded.comsol, "port")
                        cfg.port = double(loaded.comsol.port);
                    end
                    if isfield(loaded.comsol, "root")
                        cfg.root = string(loaded.comsol.root);
                    end
                end
            catch
            end

            if strlength(string(cfg.host)) == 0
                cfg.host = "localhost";
            end
            if ~(isscalar(cfg.port) && isfinite(cfg.port) && cfg.port > 0)
                cfg.port = 2036;
            end
            cfg.root = string(cfg.root);
        end

        function roots = configured_roots()
            % Return normalized COMSOL root candidates from config.
            cfg = core.ComsolModeler.connection_defaults();
            roots = strings(0, 1);
            root = string(cfg.root);
            if strlength(root) > 0
                roots(end+1, 1) = root; %#ok<AGROW>
                if endsWith(lower(root), lower("\Multiphysics")) || ...
                        endsWith(lower(root), lower("/Multiphysics"))
                    roots(end+1, 1) = string(fileparts(char(root))); %#ok<AGROW>
                end
            end
            roots = unique(roots(strlength(roots) > 0), "stable");
        end
    end

    methods (Static, Access=private)
        function value_str = parameter_value_string(value, unit)
            if isnumeric(value)
                value_str = string(value);
                if strlength(unit) ~= 0
                    value_str = value_str + "[" + string(unit) + "]";
                end
            else
                value_str = string(value);
            end
        end
    end
end
