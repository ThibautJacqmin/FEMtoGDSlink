function s = vertices_to_klayout_string(matlab_vertices)
%  Get formated string for Klayout .from_s method used to
%  initialize shapes (polygons, etc)
arguments
    matlab_vertices
end
s = string(matlab_vertices);
s = s.join(",");
s = s.join(';');
s = '(' + s + ')';
end

