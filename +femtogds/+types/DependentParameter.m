classdef DependentParameter < femtogds.types.Parameter
    % Named parameter defined from another parameter by an expression.
    properties
        anonymous_function function_handle
        dependency femtogds.types.Parameter
        comsol_modeler
    end
    methods
        function obj = DependentParameter(anonymous_function, parameter, name, args)
            % Build named parameter from a function of one parent parameter.
            arguments
                anonymous_function function_handle
                parameter femtogds.types.Parameter
                name {mustBeTextScalar} = ""
                args.expression {mustBeTextScalar} = ""
                args.unit {mustBeTextScalar} = ""
                args.comsol_modeler femtogds.core.ComsolModeler = femtogds.core.ComsolModeler.empty
            end

            if strlength(args.expression) > 0
                expression = string(args.expression);
            else
                expression = femtogds.types.DependentParameter.expression_from_function( ...
                    anonymous_function, parameter.expression_token());
            end

            if strlength(args.unit) > 0
                unit = string(args.unit);
            else
                unit = parameter.unit;
            end

            value = anonymous_function(parameter.value);
            obj@femtogds.types.Parameter(value, name, unit=unit, expr=expression);

            obj.anonymous_function = anonymous_function;
            obj.dependency = parameter;
            obj.comsol_modeler = args.comsol_modeler;
            obj.dependency_records = femtogds.types.DependentParameter.merge_records( ...
                obj.dependency_records, parameter.dependency_records);

            if ~isempty(obj.comsol_modeler) && obj.is_named()
                obj.comsol_modeler.add_parameter(obj.expr, obj.name, obj.unit);
            end
        end
    end
    methods (Static, Access=private)
        function out = merge_records(lhs, rhs)
            % Merge dependency arrays while preserving first occurrence.
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

        function expression = expression_from_function(anonymous_function, replacement_token)
            % Infer expression text from single-variable anonymous function.
            info = functions(anonymous_function);
            fun_str = string(info.function);
            tokens = regexp(fun_str, '^@\((?<var>[A-Za-z]\w*)\)\s*(?<expr>.+)$', 'names', 'once');
            if isempty(tokens)
                error("Unable to infer expression from anonymous function '%s'. Provide args.expression.", ...
                    char(fun_str));
            end
            expression = string(tokens.expr);
            var_name = char(tokens.var);
            pattern = ['\\<', regexptranslate('escape', var_name), '\\>'];
            expression = string(regexprep(char(expression), pattern, char(string(replacement_token))));
        end
    end
end
