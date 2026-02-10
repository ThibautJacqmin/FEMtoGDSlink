classdef DependentParameter < Parameter
    % Named parameter defined from another parameter by an expression.
    properties
        anonymous_function function_handle
        dependency Parameter
        comsol_modeler
    end
    methods
        function obj = DependentParameter(anonymous_function, parameter, name, args)
            arguments
                anonymous_function function_handle
                parameter Parameter
                name {mustBeTextScalar} = ""
                args.expression {mustBeTextScalar} = ""
                args.unit {mustBeTextScalar} = ""
                args.comsol_modeler ComsolModeler = ComsolModeler.empty
            end

            if strlength(args.expression) > 0
                expression = string(args.expression);
            else
                expression = DependentParametersAndVariables.expression_from_function( ...
                    anonymous_function, parameter.expression_token());
            end

            if strlength(args.unit) > 0
                unit = string(args.unit);
            else
                unit = parameter.unit;
            end

            value = anonymous_function(parameter.value);
            obj@Parameter(value, name, unit=unit, expr=expression);

            obj.anonymous_function = anonymous_function;
            obj.dependency = parameter;
            obj.comsol_modeler = args.comsol_modeler;

            if ~isempty(obj.comsol_modeler) && obj.is_named()
                obj.comsol_modeler.add_parameter(obj.expr, obj.name, obj.unit);
            end
        end
    end
end
