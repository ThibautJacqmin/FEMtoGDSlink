classdef Parameter<handle
    properties
        value
        name
        unit
        comsol_modeler
    end
    methods
        function obj = Parameter(name, value, args)
            arguments
                name {mustBeTextScalar}
                value double
                args.unit = "nm"
                args.comsol_modeler ComsolModeler=ComsolModeler.empty
            end
            obj.name = name;
            obj.value = value;
            obj.unit = args.unit;
            obj.comsol_modeler = args.comsol_modeler;
            if obj.comsol_flag
                try
                    obj.comsol_modeler.add_parameter(name, value, obj.unit);
                catch
                end
            end
        end
        function y = plus(obj, parameter_object)
            assert(obj.unit==parameter_object.unit);
            y = Parameter(obj.name + "_" + parameter_object.name, ...
                obj.value+parameter_object.value, unit= obj.unit);
        end
        function y = minus(obj, parameter_object)
            assert(obj.unit==parameter_object.unit);
            y = Parameter(obj.name + "_" + parameter_object.name, ...
                obj.value-parameter_object.value, unit= obj.unit);
        end
        function y = times(obj, coef)
            y = Parameter(obj.name + "times" + ...
                string(coef), obj.value*coef, unit=obj.unit);
        end
        function y = rdivide(obj, coef)
            y = Parameter(obj.name + "divided_by" + ...
                string(coef), obj.value/coef, unit=obj.unit);
        end
        function y = comsol_flag(obj)
            y = ~isempty(obj.comsol_modeler);
        end

    end
end