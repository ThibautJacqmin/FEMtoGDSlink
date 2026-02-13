classdef DependentParameter < femtogds.types.Parameter
    % Backward-compatible wrapper; prefer femtogds.types.Parameter directly.
    properties
        anonymous_function function_handle
        dependency femtogds.types.Parameter
        comsol_modeler
    end
    methods
        function obj = DependentParameter(anonymous_function, parameter, name, args)
            % Construct a dependent parameter (deprecated API).
            arguments
                anonymous_function function_handle
                parameter femtogds.types.Parameter
                name {mustBeTextScalar} = ""
                args.expression {mustBeTextScalar} = ""
                args.unit {mustBeTextScalar} = "__auto__"
                args.comsol_modeler femtogds.core.ComsolModeler = femtogds.core.ComsolModeler.empty
            end

            obj@femtogds.types.Parameter( ...
                anonymous_function, parameter, name, unit=args.unit, expression=args.expression);
            obj.anonymous_function = anonymous_function;
            obj.dependency = parameter;
            obj.comsol_modeler = args.comsol_modeler;
        end
    end
end
