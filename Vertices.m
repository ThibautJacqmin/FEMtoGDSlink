classdef Vertices < handle
    % Lightweight container for sets of vertices with optional unit
    % handling via a Parameter prefactor. The class exposes convenience
    % helpers to interact with both COMSOL and KLayout backends.
    properties
        array      % coefficient without dimension
        prefactor  % Parameter holding the physical dimension
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
                array double = [0, 0]
                prefactor = Parameter(1, "")
            end
            obj.prefactor = obj.normalizePrefactor(prefactor);
            obj.array = obj.normalizeArray(array);
        end
        function y = get.value(obj)
            y = round(obj.array .* obj.prefactor.value);
        end
        function y = get.xvalue(obj)
            y = obj.value(:, 1);
        end
        function y = get.yvalue(obj)
            y = obj.value(:, 2);
        end
        function y = get.nvertices(obj)
            y = size(obj.array, 1);
        end
        function y = isobarycentre(obj)
            y = mean(obj.array, 1) * obj.prefactor.value;
        end
        function s = comsol_string(obj)
            s = Utilities.vertices_to_comsol_string(obj.value, ...
                comsol_parameter_name=obj.prefactor.name);
        end
        function s = comsol_string_x(obj)
            s = Utilities.vertices_to_comsol_string(obj.value(:, 1), ...
                comsol_parameter_name=obj.prefactor.name);
        end
        function s = comsol_string_y(obj)
            s = Utilities.vertices_to_comsol_string(obj.value(:, 2), ...
                comsol_parameter_name=obj.prefactor.name);
        end
        function s = klayout_string(obj)
            s = Utilities.vertices_to_klayout_string(obj.value);
        end
        function y = get_sub_vertex(obj, vertex_index)
            y = Vertices(obj.array(vertex_index, :), obj.prefactor);
        end
        function y = concat(obj, vertices_object)
            arguments
                obj Vertices
                vertices_object Vertices
            end
            obj.assertMatchingPrefactor(vertices_object);
            y = Vertices([obj.array; vertices_object.array], obj.prefactor);
        end
        function y = plus(obj, vertices_to_add)
            vertices_to_add = obj.ensureVertices(vertices_to_add);
            if obj.hasMatchingPrefactor(vertices_to_add)
                y = Vertices(obj.array + vertices_to_add.array, obj.prefactor);
            else
                y = Vertices(obj.value + vertices_to_add.value);
            end
        end
        function y = minus(obj, vertices_to_subtract)
            vertices_to_subtract = obj.ensureVertices(vertices_to_subtract);
            if obj.hasMatchingPrefactor(vertices_to_subtract)
                y = Vertices(obj.array - vertices_to_subtract.array, obj.prefactor);
            else
                y = Vertices(obj.value - vertices_to_subtract.value);
            end
        end
        function obj = times(obj, coefficient)
            obj.prefactor = obj.prefactor * coefficient;
        end
        function obj = mrdivide(obj, coefficient)
            obj.prefactor = obj.prefactor / coefficient;
        end
        function copy_obj = copy(obj)
            copy_obj = Vertices(obj.array, obj.prefactor);
        end
    end
    methods (Access = private)
        function pref = normalizePrefactor(~, prefactor)
            if isa(prefactor, "Parameter")
                pref = prefactor;
            else
                pref = Parameter(prefactor, "");
            end
        end
        function arr = normalizeArray(~, array)
            if isempty(array)
                arr = zeros(0, 2);
                return;
            end
            if ndims(array) > 2
                s = size(array);
                array = reshape(array, [], 2);
            end
            if size(array, 2) ~= 2
                error('Vertices:InvalidArray', 'Vertices must be provided as an N-by-2 array.');
            end
            arr = array;
        end
        function obj.assertMatchingPrefactor(obj2)
            if ~obj.hasMatchingPrefactor(obj2)
                error('Vertices:PrefactorMismatch', ...
                    'Vertices prefactors must be identical for this operation.');
            end
        end
        function flag = hasMatchingPrefactor(obj, other)
            flag = isa(other, 'Vertices') && ...
                obj.prefactor.value == other.prefactor.value && ...
                strcmp(obj.prefactor.unit, other.prefactor.unit);
        end
        function vertices = ensureVertices(obj, input)
            if isa(input, 'Vertices')
                vertices = input;
            elseif isnumeric(input) && isvector(input) && numel(input) == 2
                vertices = Vertices(repmat(input, obj.nvertices, 1), obj.prefactor);
            elseif isnumeric(input) && size(input, 2) == 2
                vertices = Vertices(input, obj.prefactor);
            else
                error('Vertices:UnsupportedType', ...
                    'Unsupported operand type "%s" for Vertices arithmetic.', class(input));
            end
        end
    end
end
