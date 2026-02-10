classdef Parameter
    % Expression-aware scalar parameter used by geometry features.
    properties
        value double = 0
        name string = ""
        unit string = "nm"
        expr string = ""
    end
    methods
        function obj = Parameter(value, name, args)
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
        end

        function tf = is_named(obj)
            tf = strlength(obj.name) > 0;
        end

        function token = expression_token(obj)
            if obj.is_named()
                token = obj.name;
            else
                token = obj.expr;
            end
        end

        function y = plus(obj, rhs)
            y = obj.apply_operation(rhs, "+");
        end

        function y = minus(obj, rhs)
            y = obj.apply_operation(rhs, "-");
        end

        function y = times(obj, rhs)
            y = obj.apply_operation(rhs, "*");
        end

        function y = mtimes(obj, rhs)
            y = obj.apply_operation(rhs, "*");
        end

        function y = rdivide(obj, rhs)
            y = obj.apply_operation(rhs, "/");
        end

        function y = mrdivide(obj, rhs)
            y = obj.apply_operation(rhs, "/");
        end
    end
    methods (Access=private)
        function y = apply_operation(obj, rhs, operation)
            [rhs_value, rhs_expr, rhs_unit] = Parameter.coerce_operand(rhs);
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
        end
    end
    methods (Static, Access=private)
        function [value, expr, unit] = coerce_operand(rhs)
            if isa(rhs, "Parameter")
                value = rhs.value;
                expr = rhs.expression_token();
                unit = rhs.unit;
            elseif isnumeric(rhs) && isscalar(rhs)
                value = double(rhs);
                expr = string(rhs);
                unit = "";
            else
                error("Parameter operations require scalar double or Parameter.");
            end
        end

        function unit = combine_units(lhs_unit, rhs_unit, operation)
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
