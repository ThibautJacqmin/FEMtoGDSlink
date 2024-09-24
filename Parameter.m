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
                obj.comsol_modeler.add_parameter(name, value, obj.unit)
            end
        end

        function y = comsol_flag(obj)
            y = ~isempty(obj.comsol_modeler);
        end

    end
end