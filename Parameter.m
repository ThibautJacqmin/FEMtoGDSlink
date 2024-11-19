classdef Parameter<handle
    properties
        value
        name
        unit
        comsol_modeler
    end
    methods
        function obj = Parameter(value, name, args)
            arguments                
                value
                name {mustBeTextScalar} = "temp_name"
                args.unit = "nm"
                args.comsol_modeler ComsolModeler=ComsolModeler.empty
            end
            obj.name = name;
            switch class(value)
                case 'double'
                    obj.value = value;
                    obj.unit = args.unit;
                case 'Parameter'
                    obj.value = value.value;
                    obj.unit = value.unit;
            end
            obj.comsol_modeler = args.comsol_modeler;
            if obj.comsol_flag
                try
                    obj.comsol_modeler.add_parameter(obj.value, obj.name, obj.unit);
                catch
                end
            end
        end
        function y = plus(obj, parameter_object)
            assert(obj.unit==parameter_object.unit);
            y = Parameter(obj.value+parameter_object.value, unit= obj.unit, ...
                comsol_modeler=obj.comsol_modeler);
        end
        function y = minus(obj, parameter_object)
            assert(obj.unit==parameter_object.unit);
            y = Parameter(obj.value-parameter_object.value, unit= obj.unit, ...
                comsol_modeler=obj.comsol_modeler);
        end
        function y = times(obj, parameter_object)
            switch class(parameter_object)
                case 'double'
                    y = Parameter(obj.value*parameter_object, unit=obj.unit, ...
                        comsol_modeler=obj.comsol_modeler);
                case 'Parameter'
                    y = Parameter(obj.value*parameter_object.value, unit=obj.unit, ...
                        comsol_modeler=obj.comsol_modeler);
            end
        end
        function y = rdivide(obj, parameter_object)
            switch class(parameter_object)
                case 'double'
                    y = Parameter(obj.value/parameter_object, unit=obj.unit, ...
                        comsol_modeler=obj.comsol_modeler);
                case 'Parameter'
                    y = Parameter(obj.value/parameter_object.value, unit=obj.unit, ...
                        comsol_modeler=obj.comsol_modeler);
            end
        end
        function y = comsol_flag(obj)
            y = ~isempty(obj.comsol_modeler);
        end

    end
end