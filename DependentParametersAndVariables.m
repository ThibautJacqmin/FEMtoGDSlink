classdef DependentParametersAndVariables < handle
    properties
        name
        anonymous_function
        parameter
        unit
        comsol_modeler
    end
    methods
        function obj = DependentParametersAndVariables(anonymous_function, parameter, name, args)
            arguments
                anonymous_function function_handle
                parameter Parameter
                name {mustBeTextScalar}=""
                args.comsol_modeler ComsolModeler=ComsolModeler.empty
            end
            obj.name = name;
            obj.anonymous_function = anonymous_function;
            obj.parameter = parameter;
            obj.comsol_modeler = args.comsol_modeler;
            if obj.comsol_flag
                expression = functions(obj.anonymous_function);
                expression = string(expression.function);
                var_name = expression.extractBetween("@(", ")");
                expression = expression.extractAfter("@("+var_name+")");
                expression = expression.replace(var_name, parameter.name);
                obj.add_object(name, expression);
            end
        end
        function y = value(obj)
            y = obj.anonymous_function(obj.parameter.value);
        end
        function y = comsol_flag(obj)
            y = ~isempty(obj.comsol_modeler);
        end
    end
end