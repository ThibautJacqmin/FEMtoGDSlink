classdef GDSModeler < core.Klayout
    properties
        pylayout
        pycell
        shapes
        dbu_nm
    end
    methods
        function obj = GDSModeler(args)
            arguments
                args.dbu_nm double = 1
            end
            dbu_nm = double(args.dbu_nm);
            if ~(isscalar(dbu_nm) && isfinite(dbu_nm) && dbu_nm > 0)
                error("GDSModeler:InvalidDbuNm", ...
                    "dbu_nm must be a finite positive scalar in nm.");
            end
            obj.dbu_nm = dbu_nm;

            % Create layout
            obj.pylayout = obj.pya.Layout();
            % KLayout dbu is in um.
            obj.pylayout.dbu = obj.dbu_nm * 1e-3;

            % Create cell
            obj.pycell = obj.pylayout.create_cell("Main");
            obj.shapes = {};
        end
        function py_layer = create_layer(obj, number, datatype)
            if nargin < 3
                py_layer = obj.pylayout.layer(string(number));
            else
                py_layer = obj.pylayout.layer(int32(number), int32(datatype));
            end
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
            mark = primitives.Polygon;
            mark.pgon_py = obj.pya.Region();
            for fieldname=string(fieldnames(data))'
                mark.pgon_py.insert(obj.pya.Polygon.from_s(core.KlayoutCodec.vertices_to_klayout_string(data.(fieldname)*1e3)));
            end
            mark.vertices = types.Vertices(core.KlayoutCodec.get_vertices_from_klayout(mark.pgon_py));
        end
        function two_inch_wafer = add_two_inch_wafer(obj)
            arguments
                obj
            end
            data = load(fullfile(obj.get_folder, "Library", "two_inch_wafer.mat"));
            two_inch_wafer = primitives.Polygon;
            two_inch_wafer.pgon_py = obj.pya.Region();
            two_inch_wafer.pgon_py.insert(obj.pya.Polygon.from_s(core.KlayoutCodec.vertices_to_klayout_string(data.wafer_edge*1e3)));
            two_inch_wafer.vertices = types.Vertices(core.KlayoutCodec.get_vertices_from_klayout(two_inch_wafer.pgon_py));
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
