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
            klayout_cell.shapes(layer).insert(shape.pgon_py);
            obj.shapes{end+1}.layer = int8(layer);
            obj.shapes{end}.shape = shape;
        end
        function write(obj, filename)
            obj.pylayout.write(filename);
        end
        function make_array(obj, x, y, nx, ny, args)
            % Make an array of size nx x ny
            % with all shapes from a given layer
            % or with a given shape
            % or without optional argument : the whole design
            % (only implementation now)
            arguments
                obj
                x
                y
                nx
                ny
                args.layer
            end
            for shape=obj.shapes
                if shape{1}.layer==args.layer
                    for ix = 1:nx
                        for iy = 1:ny
                            shape_copy = shape{1}.shape.copy;
                            shape_copy.move(Vertices([ix*x.value, iy*y.value]));
                            obj.add_to_layer(shape{1}.layer, shape_copy);
                        end
                    end
                end
            end
        end
        function mark = add_alignment_mark(obj, args)
            arguments
                obj
                args.type = 1
            end
            data = load(fullfile("Library", "alignment_mark_type_" + num2str(args.type) +".mat"));
            mark = Polygon;
            mark.pgon_py = obj.pya.Region();
            for fieldname=string(fieldnames(data))'
                mark.pgon_py.insert(obj.pya.Polygon.from_s(Utilities.vertices_to_klayout_string(data.(fieldname)*1e3)));
            end
            mark.vertices = Vertices(Utilities.get_vertices_from_klayout(mark.pgon_py));
        end
        function two_inch_wafer = add_two_inch_wafer(obj)
            arguments
                obj
            end
            data = load(fullfile("Library", "two_inch_wafer.mat"));
            two_inch_wafer = Polygon;
            two_inch_wafer.pgon_py = obj.pya.Region();
            two_inch_wafer.pgon_py.insert(obj.pya.Polygon.from_s(Utilities.vertices_to_klayout_string(data.wafer_edge*1e3)));
            two_inch_wafer.vertices = Vertices(Utilities.get_vertices_from_klayout(two_inch_wafer.pgon_py));
        end

    end
end
