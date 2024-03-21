classdef ComsolModeler < handle
    properties
        model
        component
        geometry
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
        function start_gui(obj)
            mphlaunch(obj.model)
        end

    end
end