classdef KlayoutCodec
    methods (Static)
        function s = vertices_to_klayout_string(vertices)
            arguments
                vertices (:, 2) double
            end

            if isempty(vertices)
                s = "";
                return;
            end

            verts = round(vertices);
            rows = strings(size(verts, 1), 1);
            for i = 1:size(verts, 1)
                rows(i) = sprintf("%d,%d", int64(verts(i, 1)), int64(verts(i, 2)));
            end
            s = char("(" + join(rows, ";") + ")");
        end

        function verts = get_vertices_from_klayout(shape_obj)
            % Extract integer coordinate pairs from a KLayout to_s text.
            if ~py.hasattr(shape_obj, "to_s")
                error("core.KlayoutCodec.get_vertices_from_klayout requires a KLayout object with to_s().");
            end

            raw = char(string(shape_obj.to_s()));
            tokens = regexp(raw, "(-?\d+)\s*,\s*(-?\d+)", "tokens");
            if isempty(tokens)
                verts = zeros(0, 2);
                return;
            end

            verts = zeros(numel(tokens), 2);
            for i = 1:numel(tokens)
                verts(i, 1) = str2double(tokens{i}{1});
                verts(i, 2) = str2double(tokens{i}{2});
            end
        end
    end
end
