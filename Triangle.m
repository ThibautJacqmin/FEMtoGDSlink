classdef Triangle < Polygon

    properties
        center
    end

    methods
        function obj = Triangle(args)
            arguments
                args.vertices Vertices=Vertices.empty
                args.comsol_modeler ComsolModeler=ComsolModeler.empty
            end
            obj = obj@Polygon(vertices=args.vertices, comsol_modeler=args.comsol_modeler);
        end

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end