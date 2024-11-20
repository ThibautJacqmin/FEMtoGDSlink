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
        function y = plus(obj, parameter_object)
            % Implements addition for parameters
            switch class(parameter_object)
                case 'double'
                    % Case of addition with a number
                    y = Parameter(obj.value+parameter_object, "dummy", comsol_modeler=obj.comsol_modeler);
                    y.comsol_string = obj.comsol_string+"+"+string(parameter_object);
                case 'Parameter'
                    % Case of addition with a Parameter object
                    y = Parameter(obj.value+parameter_object.value, "dummy", comsol_modeler=obj.comsol_modeler);
                    y.comsol_string = obj.comsol_string+"+"+parameter_object.comsol_string;
            end
            if obj.comsol_flag
                obj.comsol_modeler.add_parameter(y.comsol_string, "dummy");
            end
        end
        function y = minus(obj, parameter_object)
            switch class(parameter_object)
                case 'double'
                    y = Parameter(obj.value-parameter_object, "dummy", comsol_modeler=obj.comsol_modeler);
                    y.comsol_string = obj.comsol_string+"-"+string(parameter_object);
                case 'Parameter'
                    y = Parameter(obj.value+parameter_object.value, "dummy", comsol_modeler=obj.comsol_modeler);
                    y.comsol_string = obj.comsol_string+"-"+parameter_object.comsol_string;
            end
            if obj.comsol_flag
                obj.comsol_modeler.add_parameter(y.comsol_string, "dummy");
            end
        end
        function y = times(obj, parameter_object)
            switch class(parameter_object)
                case 'double'
                    y = Parameter(obj.value*parameter_object, "dummy", comsol_modeler=obj.comsol_modeler);
                    y.comsol_string = obj.comsol_string+"*"+string(parameter_object);
                case 'Parameter'
                    y = Parameter(obj.value*parameter_object.value, "dummy", comsol_modeler=obj.comsol_modeler);
                    y.comsol_string = obj.comsol_string+"*"+parameter_object.comsol_string;
            end
            if obj.comsol_flag
                obj.comsol_modeler.add_parameter(y.comsol_string, "dummy");
            end
        end
        function y = mtimes(obj, parameter_object)
            switch class(parameter_object)
                case 'double'
                    y = Parameter(obj.value*parameter_object, "dummy", comsol_modeler=obj.comsol_modeler);
                    y.comsol_string = obj.comsol_string+"*"+string(parameter_object);
                case 'Parameter'
                    y = Parameter(obj.value*parameter_object.value, "dummy", comsol_modeler=obj.comsol_modeler);
                    y.comsol_string = obj.comsol_string+"*"+parameter_object.comsol_string;
            end
            if obj.comsol_flag
                obj.comsol_modeler.add_parameter(y.comsol_string, "dummy");
            end
        end
        function y = rdivide(obj, parameter_object)
            switch class(parameter_object)
                case 'double'
                    y = Parameter(obj.value/parameter_object, "dummy", comsol_modeler=obj.comsol_modeler);
                    y.comsol_string = obj.comsol_string+"/"+string(parameter_object);
                case 'Parameter'
                    y = Parameter(obj.value/parameter_object.value, "dummy", comsol_modeler=obj.comsol_modeler);
                    y.comsol_string = obj.comsol_string+"/"+parameter_object.comsol_string;
            end
            if obj.comsol_flag
                obj.comsol_modeler.add_parameter(y.comsol_string, "dummy");
            end
        end
        function y = mrdivide(obj, parameter_object)
            switch class(parameter_object)
                case 'double'
                    y = Parameter(obj.value/parameter_object, "dummy", comsol_modeler=obj.comsol_modeler);
                    y.comsol_string = obj.comsol_string+"/"+string(parameter_object);
                case 'Parameter'
                    y = Parameter(obj.value/parameter_object.value, "dummy", comsol_modeler=obj.comsol_modeler);
                    y.comsol_string = obj.comsol_string+"/"+parameter_object.comsol_string;
            end
            if obj.comsol_flag
                obj.comsol_modeler.add_parameter(y.comsol_string, "dummy");
            end
        end
        function y = comsol_flag(obj)
            y = ~isempty(obj.comsol_modeler);
        end

    end
end