classdef Vertices<handle
    properties
        array      % coefficient without dimension
        prefactor  % prefactor containing the phyical dimension
    end
    properties (Dependent)
        value
        xvalue
        yvalue
        nvertices  % number of vertices
    end
    methods
        function obj = Vertices(array, prefactor)
            arguments
                array double = [0, 0]
                prefactor = femtogds.types.Parameter(1, "")
            end
            if isa(prefactor, "femtogds.types.Parameter")
                obj.prefactor = prefactor;
            else
                obj.prefactor = femtogds.types.Parameter(prefactor, "");
            end
            if ndims(array) == 2
                obj.array = array;
            elseif ndims(array) == 3
                s = size(array);
                obj.array = reshape(array, s(1)*s(2), 2);
            end
        end
        function y = get.value(obj)
           y = obj.array.*obj.prefactor.value;
        end
        function y = get.xvalue(obj)
           y = obj.array(:, 1).*obj.prefactor.value;
        end
        function y = get.yvalue(obj)
           y = obj.array(:, 2).*obj.prefactor.value;
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
            s = Utilities.vertices_to_klayout_string(obj.value);
        end
        function y = get_sub_vertex(obj, vertex_index)
            y = femtogds.types.Vertices(obj.array(vertex_index, :), obj.prefactor);
        end
        function y = concat(obj, vertices_object)
            % Concatenation of Vertices
            assert(obj.prefactor.value==vertices_object.prefactor.value, ...
                            "Error: Vertices prefactors must be the same");
            y = femtogds.types.Vertices([obj.array; vertices_object.array], obj.prefactor);
        end
        function y = plus(obj, vertices_to_add)
            % Adds Vertices to another Vertices object (adding components
            % by components) Or add a vector to a Vertices object
            % vertices_to_add can be either a Vertices object or a [x, y]
            % (1, 2) vector
            if isa(vertices_to_add, "double") && isequal(size(vertices_to_add), [1, 2])
                vertices_to_add = femtogds.types.Vertices(repmat(vertices_to_add, obj.nvertices, 1));
            end
            % Adds Vertices
            if isequal(obj.prefactor, vertices_to_add.prefactor)
                % Keep prefactor if same
                y = femtogds.types.Vertices(obj.array+vertices_to_add.array, obj.prefactor);
            else
                % Set prefactor to 1 is different
                y = femtogds.types.Vertices(obj.value+vertices_to_add.value);
            end
        end
        function y = minus(obj, vertices_to_subtract)
            % Subtract Vertices to another Vertices object (subtracting components
            % by components) Or add a vector to a Vertices object
            % vertices_to_subtract can be either a Vertices object or a [x, y]
            % (1, 2) vector
            if isa(vertices_to_subtract, "double") && isequal(size(vertices_to_subtract), [1, 2])
                vertices_to_subtract = femtogds.types.Vertices(repmat(vertices_to_subtract, obj.nvertices, 1));
            end
            % Subtract Vertices
            if isequal(obj.prefactor, vertices_to_subtract.prefactor)
                % Keep prefactor if same
                y = femtogds.types.Vertices(obj.array-vertices_to_subtract.array, obj.prefactor);
            else
                % Set prefactor to 1 is different
                y = femtogds.types.Vertices(obj.value-vertices_to_subtract.value);
            end
        end
        function obj = times(obj, coefficient)
            % Mutliply Vertices by a coefficient
            obj.prefactor = obj.prefactor*coefficient;
        end
        function obj = mrdivide(obj, coefficient)
            % Divide Vertices by a coefficient
            obj.prefactor = obj.prefactor/coefficient;
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
end

