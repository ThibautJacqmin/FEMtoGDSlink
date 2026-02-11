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
            obj.dependency_records = DependentParameter.merge_records( ...
                obj.dependency_records, parameter.dependency_records);

            if ~isempty(obj.comsol_modeler) && obj.is_named()
                obj.comsol_modeler.add_parameter(obj.expr, obj.name, obj.unit);
            end
        end
    end
    methods (Static, Access=private)
        function out = merge_records(lhs, rhs)
            out = lhs;
            for i = 1:numel(rhs)
                rec = rhs(i);
                idx = 0;
                for j = 1:numel(out)
                    if string(out(j).name) == string(rec.name)
                        idx = j;
                        break;
                    end
                end
                if idx == 0
                    out(end+1) = rec; %#ok<AGROW>
                end
            end
        end
    end
end
