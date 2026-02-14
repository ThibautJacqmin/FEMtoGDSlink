classdef Vertices < handle
    properties
        % Dimensionless vertex coefficients (Nx2).
        array (:, 2) double = [0, 0]
        % Length scale prefactor applied to all coordinates.
        prefactor types.Parameter = types.Parameter(1, "")
    end
    properties (Dependent)
        value
        xvalue
        yvalue
        nvertices
    end
    methods
        function obj = Vertices(array, prefactor)
            arguments
                array {mustBeReal, mustBeFinite} = [0, 0]
                prefactor = types.Parameter(1, "")
            end
            obj.array = types.Vertices.normalize_array(array);
            obj.prefactor = types.Vertices.coerce_prefactor(prefactor);
        end

        function y = get.value(obj)
            y = obj.array .* obj.prefactor.value;
        end

        function y = get.xvalue(obj)
            y = obj.array(:, 1) .* obj.prefactor.value;
        end

        function y = get.yvalue(obj)
            y = obj.array(:, 2) .* obj.prefactor.value;
        end

        function y = get.nvertices(obj)
            y = size(obj.array, 1);
        end

        function y = isobarycentre(obj)
            y = mean(obj.array);
        end

        function s = comsol_string(obj)
            x = string(obj.comsol_string_x());
            y = string(obj.comsol_string_y());
            s = cellstr(x + "," + y);
        end

        function s = comsol_string_x(obj)
            s = obj.expr_components(obj.array(:, 1));
        end

        function s = comsol_string_y(obj)
            s = obj.expr_components(obj.array(:, 2));
        end

        function s = klayout_string(obj)
            s = core.KlayoutCodec.vertices_to_klayout_string(obj.value);
        end

        function y = get_sub_vertex(obj, vertex_index)
            y = types.Vertices(obj.array(vertex_index, :), obj.prefactor);
        end

        function y = concat(obj, vertices_object)
            if ~isa(vertices_object, "types.Vertices")
                error("Vertices.concat expects a types.Vertices input.");
            end
            if ~isequal(obj.prefactor, vertices_object.prefactor)
                error("Vertices.concat requires identical prefactors.");
            end
            y = types.Vertices([obj.array; vertices_object.array], obj.prefactor);
        end

        function y = plus(obj, vertices_to_add)
            rhs = types.Vertices.coerce_add_sub_operand(vertices_to_add, obj.nvertices, "plus");
            if isequal(obj.prefactor, rhs.prefactor)
                y = types.Vertices(obj.array + rhs.array, obj.prefactor);
            else
                y = types.Vertices(obj.value + rhs.value);
            end
        end

        function y = minus(obj, vertices_to_subtract)
            rhs = types.Vertices.coerce_add_sub_operand(vertices_to_subtract, obj.nvertices, "minus");
            if isequal(obj.prefactor, rhs.prefactor)
                y = types.Vertices(obj.array - rhs.array, obj.prefactor);
            else
                y = types.Vertices(obj.value - rhs.value);
            end
        end

        function y = times(lhs, rhs)
            if isa(lhs, "types.Vertices")
                scale = types.Vertices.coerce_scale(rhs, "times");
                pref = types.Vertices.scale_prefactor(lhs.prefactor, scale, "times");
                y = types.Vertices(lhs.array, pref);
            else
                scale = types.Vertices.coerce_scale(lhs, "times");
                pref = types.Vertices.scale_prefactor(rhs.prefactor, scale, "times");
                y = types.Vertices(rhs.array, pref);
            end
        end

        function y = mtimes(lhs, rhs)
            y = times(lhs, rhs);
        end

        function y = mrdivide(lhs, rhs)
            if ~isa(lhs, "types.Vertices")
                error("Division by Vertices is not supported.");
            end
            scale = types.Vertices.coerce_scale(rhs, "mrdivide");
            pref = types.Vertices.scale_prefactor(lhs.prefactor, scale, "mrdivide");
            y = types.Vertices(lhs.array, pref);
        end

        function y = rdivide(lhs, rhs)
            y = mrdivide(lhs, rhs);
        end

        function y = gds_value(obj)
            % Integer coordinates for GDS emission (1 nm database unit).
            y = round(obj.value);
        end
    end
    methods (Access=private)
        function s = expr_components(obj, coefficients)
            coeff = string(coefficients(:));
            factor = string(obj.prefactor.expression_token());
            if factor == "1"
                expr = coeff;
            else
                expr = "(" + coeff + ")*(" + factor + ")";
            end
            s = cellstr(expr);
        end
    end
    methods (Static, Access=private)
        function out = normalize_array(array)
            if ismatrix(array)
                if size(array, 2) ~= 2
                    error("Vertices array must be Nx2.");
                end
                out = double(array);
                return;
            end

            if ndims(array) == 3 && size(array, 3) == 2
                s = size(array);
                out = reshape(double(array), s(1) * s(2), 2);
                return;
            end

            error("Vertices array must be Nx2 or NxMx2 with third dimension = 2.");
        end

        function p = coerce_prefactor(prefactor)
            if isa(prefactor, "types.Parameter")
                p = prefactor;
            else
                p = types.Parameter(prefactor, "");
            end
            if ~(isscalar(p.value) && isfinite(p.value))
                error("Vertices prefactor must resolve to a finite scalar.");
            end
        end

        function v = coerce_add_sub_operand(val, nrows, op_name)
            if isa(val, "types.Vertices")
                v = val;
            elseif isnumeric(val)
                arr = double(val);
                if isequal(size(arr), [1, 2])
                    v = types.Vertices(repmat(arr, nrows, 1));
                elseif size(arr, 2) == 2 && size(arr, 1) == nrows
                    v = types.Vertices(arr);
                else
                    error("Vertices.%s numeric operand must be [1x2] or [%dx2].", ...
                        op_name, nrows);
                end
            else
                error("Vertices.%s expects types.Vertices or numeric coordinates.", op_name);
            end

            if v.nvertices ~= nrows
                error("Vertices.%s requires matching vertex counts (%d vs %d).", ...
                    op_name, nrows, v.nvertices);
            end
        end

        function scale = coerce_scale(val, op_name)
            if isa(val, "types.Parameter")
                scale = val;
                return;
            end
            if isnumeric(val) && isscalar(val) && isfinite(val)
                scale = double(val);
                return;
            end
            error("Vertices.%s expects a scalar numeric or types.Parameter factor.", op_name);
        end

        function pref = scale_prefactor(base_pref, scale, op_name)
            % Scale a length prefactor by numeric or Parameter factors.
            base_unit = string(base_pref.unit);

            if isnumeric(scale)
                if op_name == "times"
                    pref = base_pref * scale;
                else
                    pref = base_pref / scale;
                end
                pref.unit = base_unit;
                return;
            end

            scale_unit = string(scale.unit);
            is_scale_dimensionless = strlength(scale_unit) == 0;

            if op_name == "times"
                pref = base_pref * scale;
            else
                if ~is_scale_dimensionless
                    error(["Vertices.mrdivide with a unit-bearing Parameter is not supported. " ...
                        "Use a dimensionless scale Parameter for division."]);
                end
                pref = base_pref / scale;
            end

            if is_scale_dimensionless
                pref.unit = base_unit;
                return;
            end

            if types.Vertices.is_neutral_prefactor(base_pref)
                pref.unit = scale_unit;
                return;
            end

            error(["Vertices scaling with a unit-bearing Parameter requires a neutral prefactor " ...
                "(for example Vertices([x y]) * p_um)."]);
        end

        function tf = is_neutral_prefactor(p)
            % True for default unit-length neutral prefactor.
            tf = isscalar(p.value) && isfinite(p.value) && ...
                abs(double(p.value) - 1) <= 1e-12 && ...
                string(p.expression_token()) == "1";
        end
    end
end

