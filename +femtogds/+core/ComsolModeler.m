classdef ComsolModeler < handle
    % Thin wrapper around COMSOL Java API for geometry/model bookkeeping.
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
        function obj = ComsolModeler
            % Create a fresh COMSOL model with one component and workplane.
            import com.comsol.model.*
            import com.comsol.model.util.*
            obj.model_tag = ComsolModeler.next_model_tag();
            % Create new model
            obj.model = ModelUtil.create(char(obj.model_tag));
            % Activate progress bar
            ModelUtil.showProgress(true);
            % Disable Comsol model history
            obj.model.hist.disable;
            % Set working path
            obj.model.modelPath(pwd);
            obj.initialize_workspace();
        end
        function reset_workspace(obj)
            % Reset component/geometry tree while keeping model/window alive.
            % Reset model content while keeping the same COMSOL model/window.
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
            % Get an string array containin all Comsol names of graphical
            % objects and operation (corresponding to tree nodes in Comsol
            % geometry)
            names = string(obj.workplane.geom);
            names = names.extractAfter("Child nodes: ");
            names = names.split(", ");
        end
        function y = get_next_index(obj, name)
            % Return next numeric suffix for a COMSOL geometry tag prefix.
            % Retrueve the next index of a node name. For instance if
            % rect1, rect2, and rect3 exists, the function returns 4.
            y = obj.get_names;
            y = y(y.startsWith(name));
            y = max(double(y.extractAfter(name)));
            y = y+1;
            if isempty(y)
                y=1;
            end
        end
        function add_parameter(obj, value, name, unit)
            % Set one model parameter, converting numeric values to tokens.
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
            obj.model.variable('var1').set(name, expression, "");
        end
        function add_material(obj, prop)
            % Create and assign a basic isotropic material definition.
            arguments
                obj ComsolModeler
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
            Enu = mat_object.propertyGroup().create("Enu", "Young's modulus and Poisson's ratio");
            Enu.set('nu', prop.poisson_ratio);
            Enu.set('E', prop.youngs_modulus);
            % All the geometry set to the material, to be improved later
            % Geometry elementas are assigned an index when created. It is
            % incremented by 1 at each creation
            mat_object.selection.set(1:obj.geometry.getNBoundaries);
        end
        function add_mesh(obj, meshsize)
            % Create a default 2D free-triangular mesh configuration.
            arguments
                obj ComsolModeler
                meshsize double=4
            end
            % meshsize normal = 5, extremely fine = 1, extremely coarse = 9
            obj.mesh = obj.component.mesh.create('mesh1');
            obj.mesh.feature('size').set('hauto', meshsize);
            ftr = obj.mesh.create("ftri"+1, "FreeTri");
            ftr.selection.set(1:obj.geometry.getNBoundaries);
        end
        function add_physics(obj, args)
            % Add shell physics with thickness and initial stress settings.
            arguments
                obj ComsolModeler
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
            eig.set('eigsr', 1); % smallest real part
            eig.set('eiglr', 100); % largest real part
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
                obj ComsolModeler
                filename {mustBeTextScalar}='untitled.m'
            end
            obj.model.save(filename, 'm');
        end
        function comsol_object = create_comsol_object(obj, comsol_object_name)
            % Create a workplane geometry feature with an auto-generated tag.
            % This function creates a new comsol object in the plane
            % geometry. The comsol name can be "Rotate", "Difference",
            % "Move", "Copy"....
            % It returns the comsol object to be stored in
            % obj.comsol_shape; and the comsol object name of the initial
            % object that can be used for selection.
            prefix = obj.comsol_prefix(comsol_object_name);
            ind = obj.get_next_index(prefix);
            comsol_name = prefix+ind;
            comsol_object = obj.workplane.geom.create(comsol_name, comsol_object_name);
        end
        function comsol_shape = make_1D_array(obj, ncopies, vertex, initial_comsol_shape)
            % Build a linear Array feature from an existing geometry tag.
            arguments
                obj
                ncopies {mustBeA(ncopies, {'femtogds.types.Parameter', 'femtogds.types.DependentParameter'})}
                vertex {mustBeA(vertex, {'femtogds.types.Vertices'})}
                initial_comsol_shape
            end
            previous_object_name = string(initial_comsol_shape.tag); % save name of initial comsol object to be selected
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
                ncopies_x {mustBeA(ncopies_x, {'femtogds.types.Parameter', 'femtogds.types.DependentParameter'})}
                ncopies_y {mustBeA(ncopies_y, {'femtogds.types.Parameter', 'femtogds.types.DependentParameter'})}
                vertex_x {mustBeA(vertex_x, {'femtogds.types.Vertices'})}
                vertex_y {mustBeA(vertex_y, {'femtogds.types.Vertices'})}
                initial_comsol_shape
            end
            row_shape = obj.make_1D_array(ncopies_x, vertex_x, initial_comsol_shape);
            comsol_shape = obj.make_1D_array(ncopies_y, vertex_y, row_shape);
        end
    end
    methods (Static)
        function obj = shared(args)
            % Return a shared ComsolModeler instance, optionally reset first.
            arguments
                args.reset logical = true
            end
            obj = ComsolModeler.shared_store();
            if isempty(obj) || ~isvalid(obj)
                obj = ComsolModeler();
            elseif args.reset
                obj.reset_workspace();
            end
            ComsolModeler.shared_store(obj);
        end

        function clear_shared()
            % Dispose and clear the process-wide shared ComsolModeler.
            obj = ComsolModeler.shared_store();
            if ~isempty(obj) && isvalid(obj)
                try
                    import com.comsol.model.util.*
                    ModelUtil.remove(char(obj.model_tag));
                catch
                end
            end
            ComsolModeler.shared_store([]);
        end

        function removed = clear_generated_models(args)
            % Remove generated models from COMSOL server by tag prefix.
            arguments
                args.prefix {mustBeTextScalar} = "Model_"
            end
            removed = 0;
            removed_tags = strings(0, 1);
            try
                import com.comsol.model.util.*
                tags = string(ModelUtil.tags());
            catch
                return;
            end

            for i = 1:numel(tags)
                t = tags(i);
                if startsWith(t, string(args.prefix))
                    try
                        ModelUtil.remove(char(t));
                        removed = removed + 1;
                        removed_tags(end+1, 1) = t; %#ok<AGROW>
                    catch
                    end
                end
            end

            obj = ComsolModeler.shared_store();
            if ~isempty(obj) && isvalid(obj)
                if any(string(obj.model_tag) == removed_tags)
                    ComsolModeler.shared_store([]);
                end
            end
        end

        function tag = next_model_tag()
            % Generate a unique COMSOL model tag for new sessions.
            stamp = string(datestr(now, "yyyymmdd_HHMMSSFFF"));
            suffix = string(randi([0, 9999]));
            tag = "Model_" + stamp + "_" + suffix;
        end

        function y = comsol_prefix(comsol_object_name)
            % Return default 3-letter lowercase COMSOL feature prefix.
            % Comsol element prefix (pol, mir, fil, sca, ...)
            y = lower(comsol_object_name.extractBetween(1, 3));
        end
    end
    methods (Access=private)
        function initialize_workspace(obj)
            % Initialize default variable/component/geometry/workplane nodes.
            % Create variable
            obj.model.variable.create('var1');
            % Create component
            obj.component = obj.model.component.create('Component', true);
            % Create 3D geometry
            obj.geometry = obj.component.geom.create('Geometry', 3);
            % Set length unit to nanometer like in KLayout
            obj.geometry.lengthUnit("nm");
            % Create workplane
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
        function obj = shared_store(varargin)
            % Persistent storage for the shared ComsolModeler instance.
            persistent shared_obj
            if nargin == 1
                shared_obj = varargin{1};
            end
            obj = shared_obj;
        end
    end
end




