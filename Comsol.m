classdef Comsol < handle
    properties
        model
        component
        geometry
    end
    methods
        function obj = Comsol
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
        function start_gui(obj)
            mphlaunch(obj.model)
        end
    end
end