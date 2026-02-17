classdef Square < primitives.Rectangle
    % Square primitive with COMSOL-compatible base/angle semantics.
    properties (Dependent)
        side
        size
    end
    methods
        function obj = Square(ctx, args)
            % Create a square from center/corner and one side length.
            arguments
                ctx core.GeometrySession = core.GeometrySession.empty
                args.center = [0, 0]
                args.corner = []
                args.base {mustBeTextScalar} = "center"
                args.side = []
                args.size = []
                args.width = []
                args.height = []
                args.angle = 0
                args.layer = "default"
                args.fillet_width = 1
                args.fillet_height = 1
            end

            s = primitives.Square.resolve_side( ...
                side=args.side, size=args.size, width=args.width, height=args.height);
            obj@primitives.Rectangle(ctx, ...
                center=args.center, ...
                corner=args.corner, ...
                base=args.base, ...
                width=s, ...
                height=s, ...
                angle=args.angle, ...
                layer=args.layer, ...
                fillet_width=args.fillet_width, ...
                fillet_height=args.fillet_height);
        end

        function set.side(obj, val)
            p = core.GeomFeature.coerce_parameter(val, "side");
            obj.set_param("width", p);
            obj.set_param("height", p);
        end

        function val = get.side(obj)
            val = obj.width;
        end

        function set.size(obj, val)
            obj.side = val;
        end

        function val = get.size(obj)
            val = obj.side;
        end
    end
    methods (Static, Access=private)
        function s = resolve_side(args)
            arguments
                args.side = []
                args.size = []
                args.width = []
                args.height = []
            end

            vals = cell(0, 1);
            labels = strings(0, 1);
            [vals, labels] = primitives.Square.append_candidate(vals, labels, args.side, "side");
            [vals, labels] = primitives.Square.append_candidate(vals, labels, args.size, "size");
            [vals, labels] = primitives.Square.append_candidate(vals, labels, args.width, "width");
            [vals, labels] = primitives.Square.append_candidate(vals, labels, args.height, "height");

            if isempty(vals)
                s = 1;
                return;
            end

            s = vals{1};
            s_val = primitives.Square.scalar_value_local(s, labels(1));
            for i = 2:numel(vals)
                vi = primitives.Square.scalar_value_local(vals{i}, labels(i));
                if abs(vi - s_val) > 1e-12
                    error("Square expects side/size/width/height values to be equal.");
                end
            end
        end

        function [vals, labels] = append_candidate(vals, labels, val, label)
            if ~isempty(val)
                vals{end+1, 1} = val; %#ok<AGROW>
                labels(end+1, 1) = string(label); %#ok<AGROW>
            end
        end

        function y = scalar_value_local(val, context)
            if isa(val, 'types.Parameter')
                y = val.value;
            else
                y = val;
            end
            if ~(isscalar(y) && isnumeric(y) && isfinite(y))
                error("%s must resolve to a finite scalar.", char(string(context)));
            end
        end
    end
end
