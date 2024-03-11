classdef ComsolModeler < Comsol
    methods
        function obj = ComsolModeler
            
        end
        function add_parameter(obj, name, value, unit, description)
            arguments
                obj
                name {mustBeTextScalar}
                value {double}
                unit {mustBeTextScalar} = ""
                description {mustBeTextScalar} = ""
            end
            obj.model.param.set(name, string(value)+"["+num2str(unit)+"]", description);
        end
    end
end