classdef Variable<DependentParametersAndVariables
    methods
        function obj = Variable(name, anonymous_function, parameter, args)
            arguments
                name {mustBeTextScalar}
                anonymous_function function_handle
                parameter Parameter
                args.expression {mustBeTextScalar} = ""
                args.comsol_modeler ComsolModeler=ComsolModeler.empty
            end
            obj = obj@DependentParametersAndVariables(anonymous_function, ...
                parameter, name, ...
                expression=args.expression, ...
                comsol_modeler=args.comsol_modeler);
        end
        function add_object(obj, name, expression)
            obj.comsol_modeler.add_variable(name, expression);
        end 
    end
end
