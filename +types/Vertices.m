classdef Vertices < handle
    %VERTICES Coordinate container for geometry points.
    %
    % Vertices stores Nx2 coordinates and keeps two things available at the
    % same time:
    %   - numeric values for MATLAB-side geometry calculations,
    %   - expression tokens for COMSOL emission.
    %
    % Numeric coordinates are interpreted as lengths in nm by default:
    %
    %   v = types.Vertices([10, 5]);      % [10 nm, 5 nm]
    %
    % The legacy constructor form is still supported. The second argument is
    % a shared length prefactor applied to every coordinate coefficient:
    %
    %   u = types.Parameter(1, "u", unit="um");
    %   v = types.Vertices([10, 5], u);   % [10*u, 5*u] = [10 um, 5 um]
    %
    % For independent x/y parameter expressions, use component-wise vertices:
    %
    %   x = types.Parameter(100, "x", unit="um");
    %   y = types.Parameter(50,  "y", unit="um");
    %   v = types.Vertices.xy(x, y);      % [x, y]
    %
    % Component-wise vertices also work with expressions and numeric constants:
    %
    %   xr = types.Parameter(120, "x_right", unit="um");
    %   w  = types.Parameter(20,  "w",       unit="um");
    %   v  = types.Vertices.xy(xr - w, 5);   % [(x_right)-(w), 5[um]]
    %
    % For multiple points, pass an Nx2 cell array:
    %
    %   p0 = types.Vertices.from_components({x, 0; x + w, y});
    %
    % Unit rule for component-wise vertices:
    %   - all unit-bearing components must use the same supported length unit;
    %   - numeric constants inherit that unit;
    %   - if no component has a unit, values are treated as nm;
    %   - mixed units intentionally error rather than silently converting.
    %
    % This keeps the existing GeometryPipeline/GDS behavior predictable while
    % allowing COMSOL coordinates such as {x_param, y_param}.
    properties
        % Dimensionless vertex coefficients for legacy prefactor mode, or
        % numeric component values in the common component unit.
        array (:, 2) double = [0, 0]
        % Shared length prefactor. In component-wise mode this is a neutral
        % Parameter carrying the common component unit for compatibility with
        % existing code that inspects `.prefactor`.
        prefactor types.Parameter = types.Parameter(1, "")
    end
    properties (Access=private)
        % Original component inputs when using component-wise mode.
        component_items cell = cell(0, 2)
        % COMSOL expression token per coordinate in component-wise mode.
        component_exprs string = strings(0, 2)
        % Common length unit for component-wise coordinates.
        component_unit string = ""
    end
    properties (Dependent)
        % Physical coordinates in the native prefactor/component unit.
        value
        % X components of `value`.
        xvalue
        % Y components of `value`.
        yvalue
        % Number of vertices (rows in `array`).
        nvertices
    end
    methods
        function obj = Vertices(array, prefactor)
            % Construct from numeric coordinates, Parameter coordinates, or cells.
            if nargin < 1
                array = [0, 0];
            end
            provided_prefactor = nargin >= 2;
            if nargin < 2
                prefactor = types.Parameter(1, "", auto_register=false);
            end

            if iscell(array) || isa(array, "types.Parameter")
                if provided_prefactor
                    error("Vertices:ComponentPrefactorUnsupported", ...
                        "Component-wise Vertices input cannot also use a shared prefactor.");
                end
                obj.set_component_coordinates(array);
                return;
            end

            obj.array = types.Vertices.normalize_array(array);
            obj.prefactor = types.Vertices.coerce_prefactor(prefactor);
            obj.clear_component_coordinates();
        end

        function y = get.value(obj)
            % Resolve full coordinates in their native length unit.
            if obj.has_component_coordinates()
                y = obj.array;
            else
                y = obj.array .* obj.prefactor.value;
            end
        end

        function y = get.xvalue(obj)
            % Return X-coordinate vector in the native length unit.
            vals = obj.value;
            y = vals(:, 1);
        end

        function y = get.yvalue(obj)
            % Return Y-coordinate vector in the native length unit.
            vals = obj.value;
            y = vals(:, 2);
        end

        function y = get.nvertices(obj)
            % Return number of vertices.
            y = size(obj.array, 1);
        end

        function tf = has_component_coordinates(obj)
            % True when this object stores per-coordinate expressions.
            tf = ~isempty(obj.component_exprs);
        end

        function y = isobarycentre(obj)
            % Return centroid in stored coordinates.
            y = mean(obj.array);
        end

        function s = comsol_string(obj)
            % Return COMSOL-friendly coordinate token list {"x1,y1", ...}.
            x = string(obj.comsol_string_x());
            y = string(obj.comsol_string_y());
            s = cellstr(x + "," + y);
        end

        function s = comsol_string_x(obj)
            % Return COMSOL expression tokens for X coordinates.
            if obj.has_component_coordinates()
                s = cellstr(obj.component_exprs(:, 1));
            else
                s = obj.expr_components(obj.array(:, 1));
            end
        end

        function s = comsol_string_y(obj)
            % Return COMSOL expression tokens for Y coordinates.
            if obj.has_component_coordinates()
                s = cellstr(obj.component_exprs(:, 2));
            else
                s = obj.expr_components(obj.array(:, 2));
            end
        end

        function s = klayout_string(obj)
            % Return KLayout `DPolygon.from_s(...)` compatible vertex string.
            s = core.KlayoutCodec.vertices_to_klayout_string(obj.value);
        end

        function y = length_value_nm(obj)
            % Return coordinates converted to nm for GDS/database-unit code.
            if obj.has_component_coordinates()
                unit = obj.component_unit;
                vals = obj.array;
            else
                unit = string(obj.prefactor.unit);
                vals = obj.array .* obj.prefactor.value;
            end

            [scale_nm, is_length] = core.GeometryPipeline.unit_scale_to_nm(unit);
            if ~is_length
                error("Vertices:UnsupportedLengthUnit", ...
                    "Vertices length unit '%s' is not supported.", char(unit));
            end
            y = vals .* scale_nm;
        end

        function params = parameter_dependencies(obj)
            % Return Parameter objects that must be registered before COMSOL use.
            params = {};
            if obj.has_component_coordinates()
                for i = 1:numel(obj.component_items)
                    item = obj.component_items{i};
                    if isa(item, "types.Parameter")
                        params{end+1} = item; %#ok<AGROW>
                    end
                end
            elseif isa(obj.prefactor, "types.Parameter")
                params = {obj.prefactor};
            end
        end

        function y = get_sub_vertex(obj, vertex_index)
            % Return one vertex as a new Vertices object.
            if obj.has_component_coordinates()
                y = types.Vertices.from_components(obj.component_items(vertex_index, :));
            else
                y = types.Vertices(obj.array(vertex_index, :), obj.prefactor);
            end
        end

        function y = concat(obj, vertices_object)
            % Concatenate two Vertices objects.
            if ~isa(vertices_object, "types.Vertices")
                error("Vertices.concat expects a types.Vertices input.");
            end
            if obj.has_component_coordinates() || vertices_object.has_component_coordinates()
                y = types.Vertices.from_components([ ...
                    obj.component_items_for_mode(); ...
                    vertices_object.component_items_for_mode()]);
                return;
            end
            if ~isequal(obj.prefactor, vertices_object.prefactor)
                error("Vertices.concat requires identical prefactors.");
            end
            y = types.Vertices([obj.array; vertices_object.array], obj.prefactor);
        end

        function y = plus(obj, vertices_to_add)
            % Add another Vertices/numeric operand with size checks.
            rhs = types.Vertices.coerce_add_sub_operand(vertices_to_add, obj.nvertices, "plus");
            if isequal(obj.prefactor, rhs.prefactor) && ...
                    ~obj.has_component_coordinates() && ~rhs.has_component_coordinates()
                y = types.Vertices(obj.array + rhs.array, obj.prefactor);
            else
                y = types.Vertices(obj.value + rhs.value);
            end
        end

        function y = minus(obj, vertices_to_subtract)
            % Subtract another Vertices/numeric operand with size checks.
            rhs = types.Vertices.coerce_add_sub_operand(vertices_to_subtract, obj.nvertices, "minus");
            if isequal(obj.prefactor, rhs.prefactor) && ...
                    ~obj.has_component_coordinates() && ~rhs.has_component_coordinates()
                y = types.Vertices(obj.array - rhs.array, obj.prefactor);
            else
                y = types.Vertices(obj.value - rhs.value);
            end
        end

        function y = times(lhs, rhs)
            % Scale Vertices by scalar numeric or types.Parameter factor.
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
            % `*` alias of `times` for scalar-style scaling use.
            y = times(lhs, rhs);
        end

        function y = mrdivide(lhs, rhs)
            % Divide Vertices by scalar numeric or dimensionless Parameter.
            if ~isa(lhs, "types.Vertices")
                error("Division by Vertices is not supported.");
            end
            scale = types.Vertices.coerce_scale(rhs, "mrdivide");
            pref = types.Vertices.scale_prefactor(lhs.prefactor, scale, "mrdivide");
            y = types.Vertices(lhs.array, pref);
        end

        function y = rdivide(lhs, rhs)
            % `./` alias of `mrdivide`.
            y = mrdivide(lhs, rhs);
        end

        function y = gds_value(obj)
            % Integer coordinates for GDS emission at 1 nm database unit.
            y = round(obj.length_value_nm());
        end
    end
    methods (Access=private)
        function set_component_coordinates(obj, raw)
            cells = types.Vertices.normalize_component_cells(raw);
            [values, exprs, unit, items] = types.Vertices.component_payload(cells);
            obj.array = values;
            obj.prefactor = types.Parameter(1, "", unit=unit, auto_register=false);
            obj.component_items = items;
            obj.component_exprs = exprs;
            obj.component_unit = unit;
        end

        function clear_component_coordinates(obj)
            obj.component_items = cell(0, 2);
            obj.component_exprs = strings(0, 2);
            obj.component_unit = "";
        end

        function items = component_items_for_mode(obj)
            if obj.has_component_coordinates()
                items = obj.component_items;
            else
                items = obj.legacy_component_items();
            end
        end

        function items = legacy_component_items(obj)
            n = obj.nvertices;
            items = cell(n, 2);
            pref = obj.prefactor;
            pref_unit = string(pref.unit);
            pref_token = string(pref.expression_token());
            pref_is_plain_nm = abs(double(pref.value) - 1) <= 1e-12 && ...
                pref_token == "1" && any(pref_unit == ["", "nm"]);

            for i = 1:n
                for j = 1:2
                    coeff = obj.array(i, j);
                    if pref_is_plain_nm
                        items{i, j} = coeff;
                    elseif pref_token == "1"
                        expr = types.Vertices.numeric_expr(coeff * pref.value, pref_unit);
                        items{i, j} = types.Parameter(coeff * pref.value, "", ...
                            unit=pref_unit, expression=expr, auto_register=false);
                    else
                        expr = "(" + string(coeff) + ")*(" + pref_token + ")";
                        item = types.Parameter(coeff * pref.value, "", ...
                            unit=pref_unit, expression=expr, auto_register=false);
                        item.dependency_records = pref.dependency_records;
                        items{i, j} = item;
                    end
                end
            end
        end

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
    methods (Static)
        function obj = xy(x, y)
            % Build a single component-wise vertex from x and y components.
            obj = types.Vertices.from_components({x, y});
        end

        function obj = from_components(components)
            % Build component-wise vertices from an Nx2 cell/Parameter/numeric matrix.
            obj = types.Vertices();
            obj.set_component_coordinates(components);
        end
    end
    methods (Static, Access=private)
        function out = normalize_array(array)
            if ~(isnumeric(array) && isreal(array) && all(isfinite(array(:))))
                error("Vertices:InvalidArray", ...
                    "Vertices array must be finite real numeric coordinates, Parameter coordinates, or an Nx2 cell array.");
            end

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

        function cells = normalize_component_cells(raw)
            if iscell(raw)
                cells = raw;
            elseif isa(raw, "types.Parameter")
                cells = num2cell(raw);
            elseif isnumeric(raw)
                cells = num2cell(types.Vertices.normalize_array(raw));
            else
                error("Vertices:InvalidComponents", ...
                    "Component-wise Vertices require numeric, Parameter, or cell inputs.");
            end

            if isvector(cells) && numel(cells) == 2
                cells = reshape(cells, 1, 2);
            end
            if ~ismatrix(cells) || size(cells, 2) ~= 2
                error("Vertices:InvalidComponents", ...
                    "Component-wise Vertices input must be Nx2.");
            end

            for i = 1:numel(cells)
                item = cells{i};
                if isa(item, "types.Parameter")
                    if ~isscalar(item)
                        error("Vertices:InvalidComponentValue", ...
                            "Each Parameter coordinate component must be scalar.");
                    end
                elseif ~(isnumeric(item) && isscalar(item) && isreal(item) && isfinite(item))
                    error("Vertices:InvalidComponentValue", ...
                        "Each coordinate component must be a finite scalar numeric value or scalar types.Parameter.");
                end
            end
        end

        function [values, exprs, unit, items] = component_payload(cells)
            unit = types.Vertices.common_component_unit(cells);
            values = zeros(size(cells));
            exprs = strings(size(cells));
            items = cells;

            for i = 1:numel(cells)
                item = cells{i};
                if isa(item, "types.Parameter")
                    p_unit = string(item.unit);
                    if strlength(p_unit) == 0 && unit ~= "nm"
                        error("Vertices:UnitlessParameterInLengthVector", ...
                            "Unitless Parameter coordinate '%s' cannot be mixed with length unit '%s'.", ...
                            char(string(item.expression_token())), char(unit));
                    end
                    values(i) = double(item.value);
                    exprs(i) = string(item.expression_token());
                else
                    values(i) = double(item);
                    exprs(i) = types.Vertices.numeric_expr(values(i), unit);
                end
            end
        end

        function unit = common_component_unit(cells)
            units = strings(0, 1);
            for i = 1:numel(cells)
                item = cells{i};
                if isa(item, "types.Parameter")
                    u = string(item.unit);
                    if strlength(u) > 0
                        units(end+1, 1) = u; %#ok<AGROW>
                    end
                end
            end

            units = unique(units, "stable");
            if isempty(units)
                unit = "nm";
            elseif numel(units) == 1
                unit = units(1);
            else
                error("Vertices:MixedComponentUnits", ...
                    "Component-wise Vertices require a single length unit. Got: %s.", ...
                    char(strjoin(units, ", ")));
            end

            [~, is_length] = core.GeometryPipeline.unit_scale_to_nm(unit);
            if ~is_length
                error("Vertices:UnsupportedLengthUnit", ...
                    "Component-wise Vertices unit '%s' is not a supported length unit.", ...
                    char(unit));
            end
        end

        function expr = numeric_expr(value, unit)
            unit = string(unit);
            if strlength(unit) == 0 || unit == "nm"
                expr = string(value);
            else
                expr = string(value) + "[" + unit + "]";
            end
        end

        function p = coerce_prefactor(prefactor)
            if isa(prefactor, "types.Parameter")
                p = prefactor;
            else
                p = types.Parameter(prefactor, "", auto_register=false);
            end
            if ~(isscalar(p.value) && isfinite(p.value))
                error("Vertices prefactor must resolve to a finite scalar.");
            end

            [~, is_length] = core.GeometryPipeline.unit_scale_to_nm(string(p.unit));
            if ~is_length
                error("Vertices:UnsupportedLengthUnit", ...
                    "Vertices prefactor unit '%s' is not a supported length unit.", ...
                    char(string(p.unit)));
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
