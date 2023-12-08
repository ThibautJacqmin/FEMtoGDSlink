classdef Model < handle
    properties
        pya
        pylayout
        pycell
    end
    properties (Constant)
        % Set unit length (1 is 1 µm, and default is 1 nm)
        pydbu = 0.001
    end
    methods
        function obj = Model
            % Import python module lygadgets (layer on to of klayout)
            mod = py.importlib.import_module('lygadgets');
            obj.pya = mod.pya;
            % Create layout
            obj.pylayout = obj.pya.Layout();
            obj.pylayout.dbu = obj.pydbu;
            % Create cell
            obj.pycell = obj.pylayout.create_cell("Main");
        end
        function layer = create_layer(obj, number)
            layer = obj.pylayout.layer(number, 0);
        end
        function add_to_layer(obj, layer_name, shape)
            py_shape = shape.get_python_obj(obj.pya);
            obj.pycell.shapes(layer_name).insert(py_shape);
        end
        function write(obj, filename)
            obj.pylayout.write(filename);
        end

    end
end