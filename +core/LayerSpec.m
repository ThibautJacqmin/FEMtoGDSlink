classdef LayerSpec < handle
    % LayerSpec maps a logical layer to GDS and COMSOL workplane settings.
    properties
        % Logical layer name used in feature constructors.
        name
        % GDS layer number for stream export.
        gds_layer
        % GDS datatype number for stream export.
        gds_datatype
        % COMSOL workplane tag (empty means GDS-only layer).
        comsol_workplane
        % Cumulative COMSOL selection label/tag base for this layer.
        comsol_selection
        % COMSOL selection visibility/entity scope token (all/dom/bnd/edg/pnt/off).
        comsol_selection_state
        % Whether cumulative selections are created/updated in COMSOL.
        comsol_enable_selection logical = true
        % Whether features on this layer are emitted to COMSOL.
        comsol_emit logical = false
    end
    methods
        function obj = LayerSpec(name, args)
            % Construct one layer mapping record for GDS + optional COMSOL.
            arguments
                name {mustBeTextScalar}
                args.gds_layer double = 1
                args.gds_datatype double = 0
                args.comsol_workplane {mustBeTextScalar} = ""
                args.comsol_selection {mustBeTextScalar} = ""
                args.comsol_selection_state {mustBeTextScalar} ...
                    { mustBeMember(lower(string(comsol_selection_state)), ...
                    ["all","domain","boundary","edge","point","off"]) }
                args.comsol_enable_selection logical = true
                args.comsol_emit = []
            end
            obj.name = string(name);
            obj.gds_layer = args.gds_layer;
            obj.gds_datatype = args.gds_datatype;
            obj.comsol_workplane = string(args.comsol_workplane);
            obj.comsol_selection = string(args.comsol_selection);
            if strlength(obj.comsol_selection) == 0
                obj.comsol_selection = obj.name;
            end
            obj.comsol_selection_state = core.LayerSpec.normalize_selection_state(args.comsol_selection_state);
            obj.comsol_enable_selection = args.comsol_enable_selection;
            if isempty(args.comsol_emit)
                obj.comsol_emit = strlength(strtrim(obj.comsol_workplane)) > 0;
            else
                obj.comsol_emit = logical(args.comsol_emit);
            end
        end
    end
end
