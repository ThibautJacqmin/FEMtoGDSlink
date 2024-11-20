classdef DependentParameter<DependentParametersAndVariables
    methods
        function obj = DependentParameter(anonymous_function, parameter, name, args)
            arguments
                anonymous_function function_handle
                parameter Parameter
                name {mustBeTextScalar} = ""
                args.comsol_modeler ComsolModeler=ComsolModeler.empty
            end
            obj = obj@DependentParametersAndVariables(anonymous_function, ...
                parameter, name,...
                comsol_modeler=args.comsol_modeler);
        end
        function add_object(obj, name, expression)
            obj.comsol_modeler.add_parameter(expression, name);
        end
    end
end