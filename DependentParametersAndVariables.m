classdef DependentParametersAndVariables < handle
    % Base helper for dependent COMSOL parameters and variables.
    properties
        name string = ""
        anonymous_function function_handle
        parameter Parameter
        expression string = ""
        comsol_modeler
    end
    methods
        function obj = DependentParametersAndVariables(anonymous_function, parameter, name, args)
            arguments
                anonymous_function function_handle
                parameter Parameter
                name {mustBeTextScalar} = ""
                args.expression {mustBeTextScalar} = ""
                args.comsol_modeler ComsolModeler = ComsolModeler.empty
            end
            obj.name = string(name);
            obj.anonymous_function = anonymous_function;
            obj.parameter = parameter;
            obj.comsol_modeler = args.comsol_modeler;

            if strlength(args.expression) > 0
                obj.expression = string(args.expression);
            else
                obj.expression = DependentParametersAndVariables.expression_from_function( ...
                    anonymous_function, parameter.expression_token());
            end

            if obj.comsol_flag() && strlength(obj.name) > 0 && ismethod(obj, 'add_object')
                obj.add_object(obj.name, obj.expression);
            end
        end

        function y = value(obj)
            y = obj.anonymous_function(obj.parameter.value);
        end

        function tf = comsol_flag(obj)
            tf = ~isempty(obj.comsol_modeler);
        end
    end
    methods (Static)
        function expression = expression_from_function(anonymous_function, replacement_token)
            info = functions(anonymous_function);
            fun_str = string(info.function);
            tokens = regexp(fun_str, '^@\((?<var>[A-Za-z]\w*)\)\s*(?<expr>.+)$', 'names', 'once');
            if isempty(tokens)
                error("Unable to infer expression from anonymous function '%s'. Provide args.expression.", ...
                    char(fun_str));
            end
            expression = string(tokens.expr);
            var_name = char(tokens.var);
            pattern = ['\<', regexptranslate('escape', var_name), '\>'];
            expression = string(regexprep(char(expression), pattern, char(string(replacement_token))));
        end
    end
end
