function matlab_vertices = get_vertices_from_klayout(python_polygon)
%  Get vertices array from Matlab from klayout polygon
arguments
    python_polygon
end
s = string(python_polygon.to_s);
s = s.extractAfter("(");
s = s.extractBefore(")");
s = s.split(";");
s = s.split(",");
matlab_vertices = str2double(s);
