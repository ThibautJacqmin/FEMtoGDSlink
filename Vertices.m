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
                prefactor = Parameter(1, "")
            end
            if isa(prefactor, "Parameter")
                obj.prefactor = prefactor;
            else
                obj.prefactor = Parameter("", prefactor);
            end
            if ndims(array) == 2
                obj.array = array;
            elseif ndims(array) == 3
                s = size(array);
                obj.array = reshape(array, s(1)*s(2), 2);
            end
        end
        function y = get.value(obj)
           y = round(obj.array.*obj.prefactor.value);
        end
        function y = get.xvalue(obj)
           y = round(obj.array(:, 1).*obj.prefactor.value);
        end
        function y = get.yvalue(obj)
           y = round(obj.array(:, 2).*obj.prefactor.value);
        end
        function y = get.nvertices(obj)
            y = size(obj.array, 1);
        end
        function y = isobarycentre(obj)
            y = mean(obj.array);
        end
        function s = comsol_string(obj)
            s = Utilities.vertices_to_comsol_string(obj.array, ...
                comsol_parameter_name=obj.prefactor.name);
        end
        function s = comsol_string_x(obj)
            s =  Utilities.vertices_to_comsol_string(obj.array(:, 1), ...
                comsol_parameter_name=obj.prefactor.name);
        end
        function s = comsol_string_y(obj)
            s = Utilities.vertices_to_comsol_string(obj.array(:, 2), ...
                comsol_parameter_name=obj.prefactor.name);
        end
        function s = klayout_string(obj)
            s = Utilities.vertices_to_klayout_string(obj.value);
        end
        function y = get_sub_vertex(obj, vertex_index)
            y = Vertices(obj.array(vertex_index, :), obj.prefactor);
        end
        function y = concat(obj, vertices_object)
            % Concatenation of Vertices
            assert(obj.prefactor.value==vertices_object.prefactor.value, ...
                            "Error: Vertices prefactors must be the same");
            y = Vertices([obj.array; vertices_object.array], obj.prefactor);
        end
        function y = plus(obj, vertices_to_add)
            % Adds Vertices to another Vertices object (adding components
            % by components) Or add a vector to a Vertices object
            % vertices_to_add can be either a Vertices object or a [x, y]
            % (1, 2) vector
            if isa(vertices_to_add, "double") & size(vertices_to_add)==[1, 2]
                vertices_to_add = Vertices(repmat(vertices_to_add, obj.nvertices, 1));
            end
            % Adds Vertices
            if obj.prefactor==vertices_to_add.prefactor
                % Keep prefactor if same
                y = Vertices(obj.array+vertices_to_add.array, obj.prefactor);
            else
                % Set prefactor to 1 is different
                y = Vertices(obj.value+vertices_to_add.value);
            end
        end
        function y = minus(obj, vertices_to_subtract)
            % Subtract Vertices to another Vertices object (subtracting components
            % by components) Or add a vector to a Vertices object
            % vertices_to_subtract can be either a Vertices object or a [x, y]
            % (1, 2) vector
            if isa(vertices_to_subtract, "double") & size(vertices_to_add)==[1, 2]
                vertices_to_subtract = Vertices(repmat(vertices_to_add, obj.nvertices, 1));
            end
            % Subtract Vertices
            if obj.prefactor==vertices_to_subtract.prefactor
                % Keep prefactor if same
                y = Vertices(obj.array-vertices_to_subtract.array, obj.prefactor);
            else
                % Set prefactor to 1 is different
                y = Vertices(obj.value-vertices_to_subtract.value);
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
                
    end
end