classdef ComsolLivelinkModeler < handle
    % COMSOL modeler backed by MATLAB LiveLink (mphstart/ModelUtil).
    properties
        model_tag
        model
        component
        geometry
        workplane
        mesh
        shell
        study
    end

    methods
        function obj = ComsolLivelinkModeler(args)
            % Create a fresh COMSOL model with one component and workplane.
            arguments
                args.comsol_host {mustBeTextScalar} = "localhost"
                args.comsol_port double = 2036
                args.comsol_root {mustBeTextScalar} = ""
            end

            core.ComsolLivelinkModeler.ensure_ready( ...
                host=args.comsol_host, ...
                port=args.comsol_port, ...
                comsol_root=args.comsol_root, ...
                connect=true);

            import com.comsol.model.*
            import com.comsol.model.util.*
            obj.model_tag = core.ComsolLivelinkModeler.next_model_tag();
            obj.model = ModelUtil.create(char(obj.model_tag));
            ModelUtil.showProgress(true);
            obj.model.hist.disable;
            obj.model.modelPath(pwd);
            obj.initialize_workspace();
        end

        function reset_workspace(obj)
            % Reset component/geometry tree while keeping model/window alive.
            obj.clear_studies();
            obj.clear_variables();
            obj.clear_components();
            obj.clear_parameters();
            obj.initialize_workspace();
            obj.mesh = [];
            obj.shell = [];
            obj.study = [];
        end

        function names = get_names(obj)
            % Return geometry child node tags currently in active workplane.
            names = string(obj.workplane.geom);
            names = names.extractAfter("Child nodes: ");
            names = names.split(", ");
        end

        function y = get_next_index(obj, name)
            % Return next numeric suffix for a COMSOL geometry tag prefix.
            y = obj.get_names;
            y = y(y.startsWith(name));
            y = max(double(y.extractAfter(name)));
            y = y+1;
            if isempty(y)
                y=1;
            end
        end

        function add_parameter(obj, value, name, unit, description)
            % Set one model parameter, converting numeric values to tokens.
            arguments
                obj
                value
                name {mustBeTextScalar}
                unit {mustBeTextScalar} = ""
                description {mustBeTextScalar} = ""
            end
            if isnumeric(value)
                value_str = string(value);
                if strlength(unit) ~= 0
                    value_str = value_str + "[" + string(unit) + "]";
                end
            else
                value_str = string(value);
            end

            obj.model.param.set(name, value_str, description);
        end

        function add_variable(obj, name, expression)
            % Define one variable under var1.
            arguments
                obj
                name {mustBeTextScalar}
                expression
            end
            obj.model.variable('var1').set(name, expression, "");
        end

        function add_material(obj, prop)
            % Create and assign a basic isotropic material definition.
            arguments
                obj core.ComsolLivelinkModeler
                prop.poisson_ratio double
                prop.youngs_modulus double
                prop.density double
            end
            for i = 1:10
                try
                    mat_object = obj.component.material().create("mat"+i, "Common");
                    break
                catch
                    warning('Material already exists');
                end
            end
            mat_object.label('Si3N4 - Silicon nitride');
            basic = mat_object.propertyGroup().create("def", "Basic");
            basic.set('density', prop.density);
            Enu = mat_object.propertyGroup().create("Enu", "Young''s modulus and Poisson''s ratio");
            Enu.set('nu', prop.poisson_ratio);
            Enu.set('E', prop.youngs_modulus);
            mat_object.selection.set(1:obj.geometry.getNBoundaries);
        end

        function add_mesh(obj, meshsize)
            % Create a default 2D free-triangular mesh configuration.
            arguments
                obj core.ComsolLivelinkModeler
                meshsize double=4
            end
            obj.mesh = obj.component.mesh.create('mesh1');
            obj.mesh.feature('size').set('hauto', meshsize);
            ftr = obj.mesh.create("ftri"+1, "FreeTri");
            ftr.selection.set(1:obj.geometry.getNBoundaries);
        end

        function add_physics(obj, args)
            % Add shell physics with thickness and initial stress settings.
            arguments
                obj core.ComsolLivelinkModeler
                args.thickness double
                args.stress double
                args.fixed_boundaries double=[]
            end
            obj.add_parameter('thickness', args.thickness, 'm', 'membrane thickness')
            obj.add_parameter('stress', args.stress, 'Pa', 'in-plane initial stress')
            obj.shell = obj.model.physics.create('shell', 'Shell', obj.geometry.tag);
            if ~isempty(args.fixed_boundaries)
                fix = obj.shell.create('fix1', 'Fixed', 1);
                fix.selection.set(args.fixed_boundaries);
            end
            obj.shell.feature('to1').set('d', 'thickness');
            iss = obj.shell.feature("emm1").create("iss1", "InitialStressandStrain", 2);
            iss.set('Ni', {'stress*thickness' '0' '0' 'stress*thickness'});
        end

        function add_study(obj)
            % Add stationary and eigenfrequency study steps for shell physics.
            obj.study = obj.model.study.create('std1');
            stat = obj.study.create('stat', 'Stationary');
            stat.setSolveFor('/physics/shell', true);
            stat.set('geometricNonlinearity', true);
            eig = obj.study.create('eig', 'Eigenfrequency');
            eig.setSolveFor('/physics/shell', true);
            eig.set('geometricNonlinearity', true);
            eig.set('eigmethod', 'region');
            eig.set('eigunit', 'kHz');
            eig.set('eigsr', 1);
            eig.set('eiglr', 100);
        end

        function start_gui(obj)
            % Launch COMSOL Desktop attached to this model.
            mphlaunch(obj.model)
        end

        function plot(obj)
            % Run geometry and display it through mphgeom.
            obj.geometry.run;
            mphgeom(obj.model);
        end

        function save_to_m_file(obj, filename)
            % Export current model to a COMSOL-generated MATLAB script.
            arguments
                obj core.ComsolLivelinkModeler
                filename {mustBeTextScalar}='untitled.m'
            end
            obj.model.save(filename, 'm');
        end

        function comsol_object = create_comsol_object(obj, comsol_object_name)
            % Create a workplane geometry feature with an auto-generated tag.
            prefix = obj.comsol_prefix(comsol_object_name);
            ind = obj.get_next_index(prefix);
            comsol_name = prefix+ind;
            comsol_object = obj.workplane.geom.create(comsol_name, comsol_object_name);
        end

        function comsol_shape = make_1D_array(obj, ncopies, vertex, initial_comsol_shape)
            % Build a linear Array feature from an existing geometry tag.
            arguments
                obj
                ncopies {mustBeA(ncopies, {'types.Parameter', 'types.DependentParameter'})}
                vertex {mustBeA(vertex, {'types.Vertices'})}
                initial_comsol_shape
            end
            previous_object_name = string(initial_comsol_shape.tag);
            comsol_shape = obj.create_comsol_object("Array");
            comsol_shape.set('type', 'linear')
            comsol_shape.set('linearsize', ncopies.value)
            comsol_shape.set('displ', vertex.comsol_string);
            comsol_shape.selection('input').set(previous_object_name);
        end

        function comsol_shape = make_2D_array(obj, ncopies_x, ncopies_y, vertex_x, vertex_y, initial_comsol_shape)
            % Build a 2D array by chaining two linear Array features.
            arguments
                obj
                ncopies_x {mustBeA(ncopies_x, {'types.Parameter', 'types.DependentParameter'})}
                ncopies_y {mustBeA(ncopies_y, {'types.Parameter', 'types.DependentParameter'})}
                vertex_x {mustBeA(vertex_x, {'types.Vertices'})}
                vertex_y {mustBeA(vertex_y, {'types.Vertices'})}
                initial_comsol_shape
            end
            row_shape = obj.make_1D_array(ncopies_x, vertex_x, initial_comsol_shape);
            comsol_shape = obj.make_1D_array(ncopies_y, vertex_y, row_shape);
        end
    end

    methods (Static)
        function ensure_ready(args)
            % Ensure LiveLink API is available and optionally connected.
            arguments
                args.host {mustBeTextScalar} = "localhost"
                args.port double = 2036
                args.comsol_root {mustBeTextScalar} = ""
                args.connect logical = true
            end
            core.ComsolLivelinkModeler.ensure_livelink( ...
                host=args.host, ...
                port=args.port, ...
                comsol_root=args.comsol_root, ...
                connect=args.connect);

            if args.connect && ~core.ComsolLivelinkModeler.is_modelutil_ready()
                error("ComsolLivelinkModeler:NotReady", ...
                    "COMSOL LiveLink API is not ready after bootstrap.");
            end
        end

        function obj = shared(args)
            % Return a shared ComsolLivelinkModeler instance.
            arguments
                args.reset logical = true
                args.comsol_host {mustBeTextScalar} = "localhost"
                args.comsol_port double = 2036
                args.comsol_root {mustBeTextScalar} = ""
            end
            obj = core.ComsolLivelinkModeler.shared_store();
            if isempty(obj) || ~isvalid(obj)
                obj = core.ComsolLivelinkModeler( ...
                    comsol_host=args.comsol_host, ...
                    comsol_port=args.comsol_port, ...
                    comsol_root=args.comsol_root);
            elseif args.reset
                obj.reset_workspace();
            end
            core.ComsolLivelinkModeler.shared_store(obj);
        end

        function clear_shared()
            % Dispose and clear the process-wide shared modeler.
            obj = core.ComsolLivelinkModeler.shared_store();
            if ~isempty(obj) && isvalid(obj)
                try
                    com.comsol.model.util.ModelUtil.remove(char(obj.model_tag));
                catch
                end
            end
            core.ComsolLivelinkModeler.shared_store([]);
        end

        function removed = clear_generated_models(args)
            % Remove generated models from COMSOL server by tag prefix.
            arguments
                args.prefix {mustBeTextScalar} = "Model_"
            end
            removed = 0;
            removed_tags = strings(0, 1);
            try
                tags = string(com.comsol.model.util.ModelUtil.tags());
            catch
                return;
            end

            for i = 1:numel(tags)
                t = tags(i);
                if startsWith(t, string(args.prefix))
                    try
                        com.comsol.model.util.ModelUtil.remove(char(t));
                        removed = removed + 1;
                        removed_tags(end+1, 1) = t; %#ok<AGROW>
                    catch
                    end
                end
            end

            obj = core.ComsolLivelinkModeler.shared_store();
            if ~isempty(obj) && isvalid(obj)
                if any(string(obj.model_tag) == removed_tags)
                    core.ComsolLivelinkModeler.shared_store([]);
                end
            end
        end

        function tag = next_model_tag()
            % Generate a unique COMSOL model tag for new sessions.
            stamp = string(datetime("now", Format="yyyyMMdd_HHmmssSSS"));
            suffix = string(randi([0, 9999]));
            tag = "Model_" + stamp + "_" + suffix;
        end

        function y = comsol_prefix(comsol_object_name)
            % Return default 3-letter lowercase COMSOL feature prefix.
            y = lower(comsol_object_name.extractBetween(1, 3));
        end
    end

    methods (Access=private)
        function initialize_workspace(obj)
            % Initialize default variable/component/geometry/workplane nodes.
            obj.model.variable.create('var1');
            obj.component = obj.model.component.create('Component', true);
            obj.geometry = obj.component.geom.create('Geometry', 3);
            obj.geometry.lengthUnit("nm");
            obj.workplane = obj.geometry.create('wp1', 'WorkPlane');
            obj.geometry.feature('wp1').set('unite', true);
        end

        function clear_parameters(obj)
            % Clear global parameter table (including generated snp* tokens).
            try
                obj.model.param.clear();
                return;
            catch
            end

            names = strings(0, 1);
            try
                names = string(obj.model.param.varnames());
            catch
            end
            for i = 1:numel(names)
                name = char(names(i));
                try
                    obj.model.param.remove(name);
                catch
                    try
                        obj.model.param().remove(name);
                    catch
                    end
                end
            end
        end

        function clear_components(obj)
            % Remove all components from model.
            tags = strings(0, 1);
            try
                tags = string(obj.model.component.tags());
            catch
            end
            for i = 1:numel(tags)
                try
                    obj.model.component.remove(char(tags(i)));
                catch
                end
            end
            if isempty(tags)
                try
                    obj.model.component.remove('Component');
                catch
                end
            end
        end

        function clear_variables(obj)
            % Remove all model variables.
            tags = strings(0, 1);
            try
                tags = string(obj.model.variable.tags());
            catch
            end
            for i = 1:numel(tags)
                try
                    obj.model.variable.remove(char(tags(i)));
                catch
                end
            end
            if isempty(tags)
                try
                    obj.model.variable.remove('var1');
                catch
                end
            end
        end

        function clear_studies(obj)
            % Remove all model studies.
            tags = strings(0, 1);
            try
                tags = string(obj.model.study.tags());
            catch
            end
            for i = 1:numel(tags)
                try
                    obj.model.study.remove(char(tags(i)));
                catch
                end
            end
            if isempty(tags)
                try
                    obj.model.study.remove('std1');
                catch
                end
            end
        end
    end

    methods (Static, Access=private)
        function ensure_livelink(args)
            % Bootstrap via mphstart (LiveLink for MATLAB only).
            arguments
                args.host {mustBeTextScalar}
                args.port double
                args.connect logical
                args.comsol_root {mustBeTextScalar} = ""
            end

            if core.ComsolLivelinkModeler.is_modelutil_class_available() && ~args.connect
                return;
            end
            if core.ComsolLivelinkModeler.is_modelutil_ready()
                return;
            end

            if isempty(which('mphstart'))
                root = core.ComsolLivelinkModeler.resolve_comsol_root(args.comsol_root);
                if strlength(root) > 0
                    mli = fullfile(char(root), "mli");
                    if isfolder(mli)
                        addpath(mli);
                    end
                end
            end

            if isempty(which('mphstart'))
                error("ComsolLivelinkModeler:LiveLinkMissing", ...
                    "mphstart not found (even after adding COMSOL mli path).");
            end

            if args.connect
                mphstart(char(string(args.host)), double(args.port));
            end
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
            if ~core.ComsolLivelinkModeler.is_modelutil_class_available()
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
                root = core.ComsolLivelinkModeler.discover_comsol_root_windows();
                if strlength(root) > 0
                    return;
                end
            end

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
                warning("ComsolLivelinkModeler:InvalidConfiguredRoot", ...
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
                    warning("ComsolLivelinkModeler:InvalidConfiguredRoot", ...
                        "Configured COMSOL root does not exist: %s", char(root));
                    root = "";
                end
            end

            if strlength(root) == 0
                root = core.ComsolLivelinkModeler.discover_comsol_root();
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
                        stamp = core.ComsolLivelinkModeler.subkey_version_score(current_subkey);
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

        function obj = shared_store(varargin)
            % Persistent storage for the shared modeler instance.
            persistent shared_obj
            if nargin == 1
                shared_obj = varargin{1};
            end
            obj = shared_obj;
        end
    end
end
