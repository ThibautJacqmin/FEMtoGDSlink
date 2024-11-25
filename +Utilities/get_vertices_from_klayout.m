function matlab_vertices = get_vertices_from_klayout(python_polygon)
%  Get vertices array from Matlab from klayout polygon
arguments
    python_polygon
end
s = string(python_polygon.to_s);
s = s.extractAfter("(");
s = s.extractBefore(")");
s = s.split(";");
% Find mistakes in polygons after region operations like
% 2367, 0/1872983, 7683 (three components, keep only the 2 first ones
% and floatize rational number
indices = find(s.contains("/"));
if ~isempty(indices)
    for i=indices'
        t = s(i).split(",");
        t = t(1:2, 1);
        t(2) = floor(eval(t(2)));
        s(i) = t.join(",");
    end
end
s = s.split(",");
matlab_vertices = str2double(s);
