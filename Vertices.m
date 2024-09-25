classdef Vertices<handle
    properties
        array
        value
        prefactor
    end
    methods
        function obj = Vertices(array, prefactor)
            arguments
                array (:, 2) double = [0, 0]
                prefactor Parameter = Parameter("", 1)
            end
            obj.value = round(array.*prefactor.value);
            obj.array = array;
            obj.prefactor = prefactor;
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
        function y = plus(obj, vertices_object)
            assert(obj.prefactor.value==vertices_object.prefactor.value, ...
                            "Error: Vertices prefactors must be the same");
            y = Vertices([obj.array; vertices_object.array], obj.prefactor);
        end
                
    end
end