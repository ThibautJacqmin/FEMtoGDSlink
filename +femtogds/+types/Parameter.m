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
        function obj = Parameter(value, name, args)
            % Construct scalar parameter with optional name/unit/expression.
            arguments
                value = 0
                name {mustBeTextScalar} = ""
                args.unit {mustBeTextScalar} = "nm"
                args.expr {mustBeTextScalar} = ""
            end
            obj.value = double(value);
            obj.name = string(name);
            obj.unit = string(args.unit);

            if strlength(args.expr) > 0
                obj.expr = string(args.expr);
            elseif strlength(obj.name) > 0
                obj.expr = obj.name;
            else
                obj.expr = string(obj.value);
            end

            if obj.is_named()
                obj.dependency_records = struct( ...
                    'name', obj.name, ...
                    'value', obj.value, ...
                    'unit', obj.unit, ...
                    'expr', obj.expr);
            else
                obj.dependency_records = struct('name', {}, 'value', {}, 'unit', {}, 'expr', {});
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
            [rhs_value, rhs_expr, rhs_unit, rhs_records] = Parameter.coerce_operand(rhs);
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
            y_unit = Parameter.combine_units(obj.unit, rhs_unit, operation);
            y = Parameter(y_value, "", unit=y_unit, expr=y_expr);
            y.dependency_records = Parameter.merge_dependency_records(obj.dependency_records, rhs_records);
        end
    end
    methods (Static, Access=private)
        function [value, expr, unit, records] = coerce_operand(rhs)
            % Normalize RHS operand to value/expression/unit/dependencies.
            if isa(rhs, "Parameter")
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

