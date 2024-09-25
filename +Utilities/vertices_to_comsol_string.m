function s = vertices_to_comsol_string(matlab_vertices, args)
%  Get formated string for Comsol Polygons vertices from matlab 
%  nx2 array containing polygon vertices

arguments
    matlab_vertices
    args.comsol_parameter_name=""
end
if args.comsol_parameter_name.strlength~=0
    comsol_name = "*" + args.comsol_parameter_name;
else
    comsol_name="";
end

s = string(matlab_vertices);
s = s.join(",");
s = s.join(';');
s = s.insertBefore(",", comsol_name);
s = s.insertBefore(";", comsol_name);
s = s+comsol_name;
s = s.split(",");
s = s.cellstr;



