classdef GDSModeler < Klayout
    properties
        pylayout
        pycell
        shapes
    end
    properties (Constant)
        % Set unit length (1 is 1 µm, and default is 1 nm)
        pydbu = 0.001 % 1 nm
    end
    methods
        function obj = GDSModeler
            % Create layout
            obj.pylayout = obj.pya.Layout();
            obj.pylayout.dbu = obj.pydbu;
            % Create cell
            obj.pycell = obj.pylayout.create_cell("Main");
        end
        function py_layer = create_layer(obj, number)
            py_layer = obj.pylayout.layer(string(number));
        end
        function add_to_layer(obj, layer, shape, klayout_cell)
            % Last argument allows to add to a different cell than the main
            % one. Useful for arrays, for which an intermediate cell
            % is needed.
            arguments
                obj
                layer
                shape
                klayout_cell = obj.pycell
            end
            shape.layer = layer;
            klayout_cell.shapes(layer).insert(shape.pgon_py);
            obj.shapes{end+1}.layer = int8(layer);
            obj.shapes{end}.shape = shape;
        end
        function delete_layer(obj, layer)
            obj.pylayout.delete_layer(layer);
        end
        function write(obj, filename)
            obj.pylayout.write(filename);
        end
        function mark = add_alignment_mark(obj, args)
            arguments
                obj
                args.type = 1
            end
            data = load(fullfile(obj.get_folder, "Library", "alignment_mark_type_" + num2str(args.type) +".mat"));
            mark = Polygon;
            mark.pgon_py = obj.pya.Region();
            for fieldname=string(fieldnames(data))'
                mark.pgon_py.insert(obj.pya.Polygon.from_s(Utilities.vertices_to_klayout_string(data.(fieldname)*1e3)));
            end
            mark.adopt_klayout_shape(mark.pgon_py);
            mark.vertices = Vertices(Utilities.get_vertices_from_klayout(mark.pgon_py));
        end
        function two_inch_wafer = add_two_inch_wafer(obj)
            arguments
                obj
            end
            data = load(fullfile(obj.get_folder, "Library", "two_inch_wafer.mat"));
            two_inch_wafer = Polygon;
            two_inch_wafer.pgon_py = obj.pya.Region();
            two_inch_wafer.pgon_py.insert(obj.pya.Polygon.from_s(Utilities.vertices_to_klayout_string(data.wafer_edge*1e3)));
            two_inch_wafer.adopt_klayout_shape(two_inch_wafer.pgon_py);
            two_inch_wafer.vertices = Vertices(Utilities.get_vertices_from_klayout(two_inch_wafer.pgon_py));
        end
        

    end
    methods (Static)
        function y = get_folder
            s = string(mfilename('fullpath'));
            m = mfilename;
            y = s.erase(m);
        end
    end
end
