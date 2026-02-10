classdef LayerSpec < handle
    % LayerSpec maps a logical layer to GDS and COMSOL workplane settings.
    properties
        name
        gds_layer
        gds_datatype
        comsol_workplane
    end
    methods
        function obj = LayerSpec(name, args)
            arguments
                name {mustBeTextScalar}
                args.gds_layer double = 1
                args.gds_datatype double = 0
                args.comsol_workplane {mustBeTextScalar} = "wp1"
            end
            obj.name = string(name);
            obj.gds_layer = args.gds_layer;
            obj.gds_datatype = args.gds_datatype;
            obj.comsol_workplane = string(args.comsol_workplane);
        end
    end
end
