classdef Klayout < handle
    properties
        pya
    end
    methods
        function obj = Klayout
            % Import python module lygadgets (layer on to of klayout)
            mod = py.importlib.import_module('lygadgets');
            obj.pya = mod.pya;
        end
        function python_list = get_list_of_tuples_from_vertices_array(obj, matlab_vertices)
            %GET_LIST_OF_TUPLES_FROM_VERTICES_ARRAY
            %  vertices is a matlab nx2 array containing polygon vertices
            %  python list is a python list of tuples, each tuple (x, y) being one
            %  point of the polygon
            %cell_array_of_python_tuples = cellfun(@(x) {obj.pya.DPoint(x(1), x(2))}, num2cell(matlab_vertices, 2));
            points_array = matlab_vertices;
            python_list = py.list();


            % Convert the MATLAB array to DPoint objects and add them to the Python list
            for i = 1:size(points_array, 1)
                python_list.append(obj.pya.DPoint(points_array(i, 1), points_array(i, 2)));
            end
        end
    end
end
