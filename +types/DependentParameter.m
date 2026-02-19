classdef DependentParameter < types.Parameter
    % Backward-compatible wrapper; prefer types.Parameter directly.
    properties
        % Legacy function handle used to compute value from dependency inputs.
        anonymous_function function_handle
        % Legacy single dependency parameter.
        dependency types.Parameter
        % Optional explicit COMSOL modeler handle (legacy API).
        comsol_modeler
    end
    methods
        function obj = DependentParameter(anonymous_function, parameter, name, args)
            % Construct a dependent parameter (deprecated API).
            arguments
                anonymous_function function_handle
                parameter types.Parameter
                name {mustBeTextScalar} = ""
                args.expression {mustBeTextScalar} = ""
                args.unit {mustBeTextScalar} = "__auto__"
                args.comsol_modeler = []
            end

            obj@types.Parameter( ...
                anonymous_function, parameter, name, unit=args.unit, expression=args.expression);
            obj.anonymous_function = anonymous_function;
            obj.dependency = parameter;
            obj.comsol_modeler = args.comsol_modeler;
        end
    end
end
