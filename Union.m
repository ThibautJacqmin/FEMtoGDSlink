classdef Union < GeomFeature
    % Union boolean operation on multiple features.
    properties (Dependent)
        members
    end
    methods
        function obj = Union(ctx, members, args)
            arguments
                ctx GeometrySession
                members
                args.layer = []
                args.output logical = true
            end
            members = Union.normalize_inputs(members);
            if isempty(args.layer) && ~isempty(members)
                layer = members{1}.layer;
            else
                layer = args.layer;
            end
            obj@GeomFeature(ctx, layer);
            obj.output = args.output;
            for i = 1:numel(members)
                obj.add_input(members{i});
            end
        end

        function val = get.members(obj)
            val = obj.inputs;
        end
    end
    methods (Static, Access=private)
        function inputs = normalize_inputs(members)
            if iscell(members)
                inputs = members;
            else
                inputs = num2cell(members);
            end
        end
    end
end
