classdef Parameter
    % Expression-aware scalar parameter used by geometry features.
    properties
        value double = 0
        name string = ""
        unit string = "nm"
        expr string = ""
        dependency_records struct = struct('name', {}, 'value', {}, 'unit', {}, 'expr', {})
    end
    methods
        function obj = Parameter(primary, secondary, tertiary, args)
            % Construct from numeric, Parameter, or function-handle dependencies.
            arguments
                primary = 0
                secondary = ""
                tertiary = ""
                args.unit {mustBeTextScalar} = "__auto__"
                args.expr {mustBeTextScalar} = ""
                args.expression {mustBeTextScalar} = ""
            end

            expr_override = femtogds.types.Parameter.resolve_expr_override(args.expr, args.expression);
            dep_records = struct('name', {}, 'value', {}, 'unit', {}, 'expr', {});

            if isa(primary, "function_handle")
                deps = femtogds.types.Parameter.normalize_dependencies(secondary);
                name = femtogds.types.Parameter.normalize_name(tertiary, ...
                    "Function-based Parameter requires a name as third positional argument.");
                [value, inferred_expr, dep_records, inferred_unit] = ...
                    femtogds.types.Parameter.build_from_function(primary, deps);
                expr = inferred_expr;
                unit = femtogds.types.Parameter.resolve_unit(args.unit, inferred_unit);
            elseif isa(primary, "femtogds.types.Parameter")
                if ~(isstring(secondary) || ischar(secondary) || isempty(secondary))
                    error("For Parameter(source, ...), second positional argument must be the new name.");
                end
                if strlength(string(tertiary)) > 0
                    error("For Parameter(source, name), third positional argument is not used.");
                end
                source = primary;
                value = source.value;
                name = femtogds.types.Parameter.normalize_name(secondary);
                expr = source.expression_token();
                unit = femtogds.types.Parameter.resolve_unit(args.unit, source.unit);
                dep_records = source.dependency_records;
            elseif isnumeric(primary) && isscalar(primary)
                value = double(primary);
                name = femtogds.types.Parameter.normalize_name(secondary);
                if strlength(string(tertiary)) > 0
                    error("Numeric Parameter constructor expects at most two positional arguments.");
                end
                expr = "";
                unit = femtogds.types.Parameter.resolve_unit(args.unit, "nm");
            else
                error(['Parameter primary input must be scalar numeric, femtogds.types.Parameter, ' ...
                    'or function handle.']);
            end

            if strlength(expr_override) > 0
                expr = expr_override;
            end

            obj.value = double(value);
            obj.name = name;
            obj.unit = unit;

            if strlength(expr) > 0
                obj.expr = expr;
            elseif strlength(obj.name) > 0
                obj.expr = obj.name;
            else
                obj.expr = string(obj.value);
            end

            obj.dependency_records = dep_records;
            if obj.is_named()
                self_rec = struct( ...
                    'name', obj.name, ...
                    'value', obj.value, ...
                    'unit', obj.unit, ...
                    'expr', obj.expr);
                obj.dependency_records = femtogds.types.Parameter.merge_dependency_records( ...
                    obj.dependency_records, self_rec);
            end
        end

        function tf = is_named(obj)
            % Return true when parameter has a non-empty symbolic name.
            tf = strlength(obj.name) > 0;
        end

        function token = expression_token(obj)
            % Return preferred expression token for downstream emitters.
            if obj.is_named()
                token = obj.name;
            else
                token = obj.expr;
            end
        end

        function y = plus(obj, rhs)
            % Overload + preserving expression and dependency metadata.
            y = obj.apply_operation(rhs, "+");
        end

        function y = minus(obj, rhs)
            % Overload - preserving expression and dependency metadata.
            y = obj.apply_operation(rhs, "-");
        end

        function y = times(obj, rhs)
            % Overload .* preserving expression and dependency metadata.
            y = obj.apply_operation(rhs, "*");
        end

        function y = mtimes(obj, rhs)
            % Overload * preserving expression and dependency metadata.
            y = obj.apply_operation(rhs, "*");
        end

        function y = rdivide(obj, rhs)
            % Overload ./ preserving expression and dependency metadata.
            y = obj.apply_operation(rhs, "/");
        end

        function y = mrdivide(obj, rhs)
            % Overload / preserving expression and dependency metadata.
            y = obj.apply_operation(rhs, "/");
        end
    end
    methods (Access=private)
        function y = apply_operation(obj, rhs, operation)
            % Execute binary arithmetic and propagate dependency records.
            [rhs_value, rhs_expr, rhs_unit, rhs_records] = femtogds.types.Parameter.coerce_operand(rhs);
            lhs_expr = obj.expression_token();

            switch operation
                case "+"
                    y_value = obj.value + rhs_value;
                case "-"
                    y_value = obj.value - rhs_value;
                case "*"
                    y_value = obj.value * rhs_value;
                case "/"
                    y_value = obj.value / rhs_value;
                otherwise
                    error("Unsupported operation '%s'.", operation);
            end

            y_expr = "(" + lhs_expr + ")" + operation + "(" + rhs_expr + ")";
            y_unit = femtogds.types.Parameter.combine_units(obj.unit, rhs_unit, operation);
            y = femtogds.types.Parameter(y_value, "", unit=y_unit, expr=y_expr);
            y.dependency_records = femtogds.types.Parameter.merge_dependency_records(obj.dependency_records, rhs_records);
        end
    end
    methods (Static, Access=private)
        function out = normalize_name(raw, err_msg)
            % Normalize optional name input to string scalar.
            if nargin < 2
                err_msg = "Parameter name must be a text scalar.";
            end
            if ~(isstring(raw) || ischar(raw) || isempty(raw))
                error("%s", err_msg);
            end
            out = string(raw);
            if ~isscalar(out)
                error("%s", err_msg);
            end
        end

        function expr = resolve_expr_override(expr_a, expr_b)
            % Resolve expression override from expr/expression aliases.
            expr_a = string(expr_a);
            expr_b = string(expr_b);
            if strlength(expr_a) > 0 && strlength(expr_b) > 0 && expr_a ~= expr_b
                error("Conflicting expression overrides provided via 'expr' and 'expression'.");
            end
            if strlength(expr_a) > 0
                expr = expr_a;
            else
                expr = expr_b;
            end
        end

        function unit = resolve_unit(raw_unit, default_unit)
            % Resolve unit with auto-default behavior.
            raw_unit = string(raw_unit);
            if raw_unit == "__auto__"
                unit = string(default_unit);
            else
                unit = raw_unit;
            end
        end

        function deps = normalize_dependencies(dep_input)
            % Normalize dependencies to a 1xN cell array of Parameter objects.
            if isa(dep_input, "femtogds.types.Parameter")
                deps = num2cell(dep_input(:).');
            elseif iscell(dep_input)
                deps = dep_input;
            else
                error("Function-based Parameter requires dependency Parameter input as second argument.");
            end
            if isempty(deps)
                error("Function-based Parameter requires at least one dependency Parameter.");
            end
            for i = 1:numel(deps)
                if ~isa(deps{i}, "femtogds.types.Parameter")
                    error("All dependencies must be femtogds.types.Parameter instances.");
                end
            end
        end

        function [value, expr, records, inferred_unit] = build_from_function(fun_handle, deps)
            % Build value/expression/dependencies from lambda and parents.
            info = functions(fun_handle);
            fun_str = string(info.function);
            toks = regexp(fun_str, '^@\((?<vars>[^\)]*)\)\s*(?<expr>.+)$', 'names', 'once');
            if isempty(toks)
                error("Unable to infer expression from anonymous function '%s'.", char(fun_str));
            end

            vars = strtrim(split(string(toks.vars), ","));
            vars = vars(strlength(vars) > 0);
            if numel(vars) ~= numel(deps)
                error("Anonymous function argument count (%d) does not match dependency count (%d).", ...
                    numel(vars), numel(deps));
            end

            expr = string(toks.expr);
            for i = 1:numel(vars)
                var_name = char(vars(i));
                dep_token = char(string(deps{i}.expression_token()));
                pattern = ['(?<![A-Za-z0-9_])', regexptranslate('escape', var_name), '(?![A-Za-z0-9_])'];
                expr = string(regexprep(char(expr), pattern, dep_token));
            end

            arg_values = cell(1, numel(deps));
            records = struct('name', {}, 'value', {}, 'unit', {}, 'expr', {});
            for i = 1:numel(deps)
                arg_values{i} = deps{i}.value;
                records = femtogds.types.Parameter.merge_dependency_records(records, deps{i}.dependency_records);
            end
            value = fun_handle(arg_values{:});
            if ~(isnumeric(value) && isscalar(value) && isfinite(value))
                error("Function-based Parameter must evaluate to a finite scalar numeric value.");
            end
            inferred_unit = femtogds.types.Parameter.infer_dependency_unit(deps);
        end

        function unit = infer_dependency_unit(deps)
            % Infer a conservative default unit from dependency units.
            units = strings(1, numel(deps));
            for i = 1:numel(deps)
                units(i) = string(deps{i}.unit);
            end
            if isscalar(unique(units))
                unit = units(1);
            else
                unit = "";
            end
        end

        function [value, expr, unit, records] = coerce_operand(rhs)
            % Normalize RHS operand to value/expression/unit/dependencies.
            if isa(rhs, "femtogds.types.Parameter")
                value = rhs.value;
                expr = rhs.expression_token();
                unit = rhs.unit;
                records = rhs.dependency_records;
            elseif isnumeric(rhs) && isscalar(rhs)
                value = double(rhs);
                expr = string(rhs);
                unit = "";
                records = struct('name', {}, 'value', {}, 'unit', {}, 'expr', {});
            else
                error("Parameter operations require scalar double or Parameter.");
            end
        end

        function out = merge_dependency_records(lhs, rhs)
            % Merge two dependency record arrays by parameter name.
            out = lhs;
            for i = 1:numel(rhs)
                rec = rhs(i);
                if strlength(string(rec.name)) == 0
                    continue;
                end
                idx = 0;
                for j = 1:numel(out)
                    if string(out(j).name) == string(rec.name)
                        idx = j;
                        break;
                    end
                end
                if idx == 0
                    out(end+1) = rec; %#ok<AGROW>
                elseif abs(out(idx).value - rec.value) > 1e-12 || ...
                        string(out(idx).unit) ~= string(rec.unit) || ...
                        string(out(idx).expr) ~= string(rec.expr)
                    warning("Parameter:DependencyConflict", ...
                        "Conflicting definitions for parameter '%s'; keeping first definition.", ...
                        char(string(rec.name)));
                end
            end
        end

        function unit = combine_units(lhs_unit, rhs_unit, operation)
            % Conservative unit propagation rules for scalar arithmetic.
            lhs_unit = string(lhs_unit);
            rhs_unit = string(rhs_unit);

            switch operation
                case {"+", "-"}
                    if strlength(lhs_unit) == 0
                        unit = rhs_unit;
                    elseif strlength(rhs_unit) == 0 || lhs_unit == rhs_unit
                        unit = lhs_unit;
                    else
                        unit = "";
                    end
                otherwise
                    % Unit algebra is intentionally conservative in this skeleton.
                    unit = "";
            end
        end
    end
end
