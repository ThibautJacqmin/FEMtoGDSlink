classdef Model < handle
    properties
        pya
        pylayout
        pycell
        shape_list = {}
        fig
    end
    properties (Constant)
        % Set unit length (1 is 1 µm, and default is 1 nm)
        pydbu = 1
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
            % Figure
            obj.fig = figure(1);
            hold on;
        end
        function layer = create_layer(obj, number)
            layer = obj.pylayout.layer(number, 0);
        end
        function add_to_layer(obj, layer, shape)
            py_shape = shape.get_python_obj(obj.pya);
            obj.pycell.shapes(layer).insert(py_shape);
            obj.shape_list{end+1} = shape;
        end
        function mark = add_alignment_mark(obj, layer)
            layout_temp = obj.pya.Layout();
            layout_temp.read('C:\Users\ThibautJacqmin\Documents\GitHub\FEMtoGDSlink\Library\alignment_mark.gds')
            cell = layout_temp.top_cell();
            new_cell = obj.pylayout.create_cell("AlignmentMark");
            new_cell.copy_shapes(cell);
            mark = new_cell.shapes(1);
            obj.pycell.shapes(layer).insert(mark);
        end
        function write(obj, filename)
            obj.pylayout.write(filename);
        end
        function plot(obj)
            for shape=obj.shape_list
                obj.fig;
                shape{1}.plot;
            end
        end
    end
end