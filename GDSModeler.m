classdef GDSModeler < Klayout
    properties
        pylayout
        pycell
        shapes = {}
        fig
    end
    properties (Constant)
        % Set unit length (1 is 1 µm, and default is 1 nm)
        pydbu = 0.001
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
            obj.shapes{end+1} = shape.pgon;
        end
        function resulting_shape = subtract_other_from_first(obj, first_shape, other_shapes, layer)
            % first_shape : SHape object
            % other_shapes : cellarray of Shape objects
            % layer : layer where to insert the result
            region1 = obj.pya.Region();
            region1.insert(first_shape.get_python_obj);
            region2 = obj.pya.Region();
            for shape=other_shapes
                region2.insert(shape{1}.get_python_obj);
            end
            resulting_shape = region1+region2;
            obj.pycell.shapes(layer).insert(resulting_shape);
        end
        function write(obj, filename)
            obj.pylayout.write(filename);
        end
        function plot(obj)
            for shape=obj.shapes
                shape = shape{1};
                figure(obj.fig.Number);
                shape.plot;
            end
        end
    end
    methods (Static)
        function mark = add_alignment_mark(args)
            arguments
                args.type = 1
            end
            data = load(fullfile("Library", "alignment_mark_type_" + num2str(args.type) +".mat"));
            mark = Polygon;
            for fieldname=string(fieldnames(data))'
                mark.p = mark.p.addboundary(data.(fieldname));
            end
        end
    end
end