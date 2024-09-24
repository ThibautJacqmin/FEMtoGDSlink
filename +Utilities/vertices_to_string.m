function s = vertices_to_string(matlab_vertices, args)
%  Get formated string for Klayout .from_s method used to
%  initialize shapes (polygons, etc), or for Comsol Polygons
%  vertices is a matlab nx2 array containing polygon vertices
%  s is a matlab string in the form '(1, 0;2, 3;2, 8;...)' for Klayout
% and 
arguments
    matlab_vertices
    args.comsol_flag=false
    args.comsol_parameter_name=""
end
comsol_name = "*" + args.comsol_parameter_name;

s = string(matlab_vertices);
s = s.join(",");
s = s.join(';');

if args.comsol_flag
    s = s.insertBefore(",", comsol_name);
    s = s.insertBefore(";", comsol_name);
    s = s+comsol_name;
    s = '{' + s + '}';
else
    s = '(' + s + ')';
end

