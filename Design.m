classdef Design < handle
    methods (Access=private)
        function addParameters(obj, args)
            % Function that store input args structure into object properties
            for h=string(fieldnames(args))'
                obj.(h) = args.(h);
            end
        end
    end
end