classdef GDSModeler < Klayout
    properties
        pylayout
        pycell
        shapes = {}
        fig
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
            % Figure
            obj.fig = figure(1);
            hold on
        end
        function py_layer = create_layer(obj, number)
            py_layer = obj.pylayout.layer(string(number));
        end
        function add_to_layer(obj, layer, shape)
            obj.pycell.shapes(layer).insert(shape.pgon_py);
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
            i = 0;
            for shape=obj.shapes
                i = i+1
                for ix = 1:nx
                    for iy = 1:ny
                        shape_copy = shape{1}.shape.copy;                  
                        shape_copy.move([ix*x, iy*y]);
                        obj.add_to_layer(shape{1}.layer, shape_copy);  
                    end
                end
            end
        end

        function plot(obj)
            for shape=obj.shapes
                shape_to_plot = shape{1};
                try
                    figure(obj.fig.Number);
                catch
                    obj.fig = figure(1);
                    hold on
                end
                shape_to_plot.shape.plot;
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
                mark.pgon = mark.pgon.addboundary(data.(fieldname)*1e3);
                mark.pgon_py.insert(obj.pya.Polygon.from_s(Utilities.vertices_to_string(data.(fieldname)*1e3)));
            end
        end
    end
end