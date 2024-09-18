function matlab_vertices = string_to_vertices(python_string)
%  Get vertices array from Matlab from .to_s klayout method used to
%  retrieve the polygon vertices in string format
arguments
    python_string
end

s = string(python_string);
s = s.extractAfter("(");
s = s.extractBefore(")");
s = s.split(";");
s = s.split(",");
matlab_vertices = str2double(s);
