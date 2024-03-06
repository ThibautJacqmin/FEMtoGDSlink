classdef Comsol < handle
    properties
        model
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
            model.modelPath(pwd);
        end
    end
end