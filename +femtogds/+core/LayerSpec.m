classdef LayerSpec < handle
    % LayerSpec maps a logical layer to GDS and COMSOL workplane settings.
    properties
        name
        gds_layer
        gds_datatype
        comsol_workplane
        comsol_selection
        comsol_selection_state
        comsol_enable_selection logical = true
        comsol_emit logical = true
    end
    methods
        function obj = LayerSpec(name, args)
            arguments
                name {mustBeTextScalar}
                args.gds_layer double = 1
                args.gds_datatype double = 0
                args.comsol_workplane {mustBeTextScalar} = "wp1"
                args.comsol_selection {mustBeTextScalar} = ""
                args.comsol_selection_state {mustBeTextScalar} = "all"
                args.comsol_enable_selection logical = true
                args.comsol_emit logical = true
            end
            obj.name = string(name);
            obj.gds_layer = args.gds_layer;
            obj.gds_datatype = args.gds_datatype;
            obj.comsol_workplane = string(args.comsol_workplane);
            obj.comsol_selection = string(args.comsol_selection);
            if strlength(obj.comsol_selection) == 0
                obj.comsol_selection = obj.name;
            end
            obj.comsol_selection_state = femtogds.core.LayerSpec.normalize_selection_state(args.comsol_selection_state);
            obj.comsol_enable_selection = args.comsol_enable_selection;
            obj.comsol_emit = args.comsol_emit;
        end
    end
    methods (Static, Access=private)
        function state = normalize_selection_state(raw_state)
            state = lower(string(raw_state));
            allowed = ["all", "domain", "domains", "dom", "boundary", "boundaries", ...
                "bnd", "edge", "edges", "edg", "point", "points", "pnt", "off", "none"];
            if ~any(state == allowed)
                error("Unknown comsol_selection_state '%s'.", char(state));
            end
        end
    end
end
