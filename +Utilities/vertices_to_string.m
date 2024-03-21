function s = vertices_to_string(matlab_vertices, comsol_flag)
%  Get formated string for Klayout .from_s method used to
%  initialize shapes (polygons, etc), or for Comsol Polygons
%  vertices is a matlab nx2 array containing polygon vertices
%  s is a matlab string in the form '(1, 0;2, 3;2, 8;...)' for Klayout
% and 
arguments
    matlab_vertices
    comsol_flag=false
end
s = string(round(matlab_vertices));
s = s.join(',');
s = s.join(';');
if comsol_flag
    s = '{' + s + '}';
else
    s = '(' + s + ')';
end

