classdef ComsolModeler < handle
    properties
        model
        component
        geometry
        mesh
    end
    methods
        function obj = ComsolModeler
            import com.comsol.model.*
            import com.comsol.model.util.*
            % Create new model
            obj.model = ModelUtil.create('Model');
            % Activate progress bar
            ModelUtil.showProgress(true);
            % Disable Comsol model history
            obj.model.hist.disable;
            % Set working path
            obj.model.modelPath(pwd);
            % Create component
            obj.component = obj.model.component.create('Component', true);
            % Creat 2D geometry
            obj.geometry = obj.component.geom.create('Geometry', 2);
        end
        function names = get_names(obj)
            % Get an string array containin all Comsol names of graphical
            % objects and operation (corresponding to tree nodes in Comsol
            % geometry)
            names = string(obj.geometry.toString);
            names = names.extractAfter("Child nodes: ");
            names = names.split(", ");
        end
        function y = get_next_index(obj, name)
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
        function add_parameter(obj, name, value, unit, description)
            arguments
                obj
                name {mustBeTextScalar}
                value {double}
                unit {mustBeTextScalar} = ""
                description {mustBeTextScalar} = ""
            end
            obj.model.param.set(name, string(value)+"["+num2str(unit)+"]", description);
        end
        function add_material(obj, prop)
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
            mat_object.selection.set(1:obj.geometry.getNDomains);
        end
        function add_mesh(obj, meshsize)
            arguments
                obj ComsolModeler
                meshsize double=4
            end
            % meshsize normal = 5, extremely fine = 1, extremely coarse = 9
            obj.mesh = obj.component.mesh.create('mesh1');
            obj.mesh.feature('size').set('hauto', meshsize);
            obj.mesh.create("ftri"+1, "FreeTri");
            obj.mesh.run;
        end
        function start_gui(obj)
            mphlaunch(obj.model)
        end
        function plot(obj)
            obj.geometry.run;
            mphgeom(obj.model);
        end
        function save_to_m_file(obj, filename)
            arguments
                obj ComsolModeler
                filename {mustBeTextScalar}='untitled.m'
            end
            obj.model.save(filename, 'm');
        end
    end
end