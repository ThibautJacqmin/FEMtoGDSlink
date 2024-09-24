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
            s = Utilities.vertices_to_string(obj.array, ...
                comsol_parameter_name=obj.prefactor.name,comsol_flag=true);
        end
        function s = comsol_string_x(obj)
            s =  Utilities.vertices_to_string(obj.array(:, 1), ...
                comsol_parameter_name=obj.prefactor.name,comsol_flag=true);
        end
        function s = comsol_string_y(obj)
            s = Utilities.vertices_to_string(obj.array(:, 2), ...
                comsol_parameter_name=obj.prefactor.name,comsol_flag=true);
        end
        function s = klayout_string(obj)
            s = Utilities.vertices_to_string(obj.value);
        end
                
    end
end