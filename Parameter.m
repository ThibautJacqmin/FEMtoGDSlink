classdef Parameter<handle
    properties
        value
        name
        unit
        comsol_string
        comsol_modeler
    end
    methods
        function obj = Parameter(value, name, comsol_string, args)
            arguments
                value
                name {mustBeTextScalar} = ""
                comsol_string {mustBeTextScalar} = ""
                args.unit = "nm"
                args.comsol_modeler ComsolModeler=ComsolModeler.empty
            end
            obj.name = name;
            obj.value = value;
            obj.unit = args.unit;
            obj.comsol_string = obj.name;                
            obj.comsol_modeler = args.comsol_modeler;
            if obj.comsol_flag
                try
                    obj.comsol_modeler.add_parameter(obj.value, obj.comsol_string, obj.unit);
                catch
                end
            end
        end
        function y = apply_operation(obj, parameter_object, operation)
            % Implements +, -, *, / operations for Parameters
             switch class(parameter_object)
                case 'double'
                    % Case of operation with a number
                    y = Parameter(eval("(obj.value" + operation + "parameter_object)"));
                    y.comsol_string = "("+obj.comsol_string+")" + operation + "("+string(parameter_object)+")";
                case 'Parameter'
                    % Case of operation with a Parameter object
                    y = Parameter(eval("(obj.value" + operation + "parameter_object.value)"));
                    y.comsol_string = "("+obj.comsol_string+")" + operation + "("+parameter_object.comsol_string+")";
            end
        end
        function y = plus(obj, parameter_object)
            % Implements addition for parameters
            y = obj.apply_operation(parameter_object, "+");
        end
        function y = minus(obj, parameter_object)
            % Implements subtraction for parameters
            y = obj.apply_operation(parameter_object, "-");
        end
        function y = times(obj, parameter_object)
            % Implements multiplication .* for parameters
            y = obj.apply_operation(parameter_object, "*");
        end
        function y = mtimes(obj, parameter_object)
            % Implements multiplication * for parameters
            y = obj.apply_operation(parameter_object, "*");
        end
        function y = rdivide(obj, parameter_object)
            % Implements division ./ for parameters
            y = obj.apply_operation(parameter_object, "/");
        end
        function y = mrdivide(obj, parameter_object)
            % Implements division / for parameters
            y = obj.apply_operation(parameter_object, "/");
        end
        function y = comsol_flag(obj)
            y = ~isempty(obj.comsol_modeler);
        end

    end
end