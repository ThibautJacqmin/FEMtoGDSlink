function s = vertices_to_string(matlab_vertices)
%  Get formated string for Klayout .from_s method used to
%  initialize shapes (polygons, etc).
%  vertices is a matlab nx2 array containing polygon vertices
%  s is a matlab string in the form '(1, 0;2, 3;2, 8;...)'
s = string(matlab_vertices);
s = s.join(',');
s = s.join(';');
s = '(' + s + ')';
end

