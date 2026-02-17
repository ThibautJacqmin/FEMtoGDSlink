classdef PortRef
    % Oriented port anchor carrying one routing.PortSpec cross-section.
    properties
        name string
        pos types.Vertices
        ori (1, 2) double
        spec routing.PortSpec
    end
    methods
        function obj = PortRef(args)
            arguments
                args.name {mustBeTextScalar} = "port_0"
                args.pos = [0, 0]
                args.ori = [1, 0]
                args.spec routing.PortSpec = routing.PortSpec(widths=1)
            end

            obj.name = string(args.name);
            obj.pos = routing.PortRef.coerce_single_position(args.pos);
            obj.ori = routing.PortRef.normalize_orientation(args.ori);
            obj.spec = args.spec;
        end

        function p = position_value(obj)
            p = obj.pos.value;
        end

        function n = normal(obj)
            n = [-obj.ori(2), obj.ori(1)];
        end

        function p = local_point(obj, along, cross)
            p = obj.position_value() + along * obj.ori + cross * obj.normal();
        end

        function c = track_center(obj, i, along)
            if nargin < 3
                along = 0;
            end
            c = obj.local_point(along, obj.spec.offset_value(i));
        end

        function [p_top, p_bottom] = track_edges(obj, i, along)
            if nargin < 3
                along = 0;
            end
            center = obj.track_center(i, along);
            half_w = 0.5 * obj.spec.width_value(i);
            n = obj.normal();
            p_top = center + half_w * n;
            p_bottom = center - half_w * n;
        end

        function out = reversed(obj, args)
            arguments
                obj
                args.name {mustBeTextScalar} = ""
                args.suffix {mustBeTextScalar} = "_r"
            end
            out_name = string(args.name);
            if strlength(out_name) == 0
                out_name = obj.name + string(args.suffix);
            end
            out = routing.PortRef( ...
                name=out_name, ...
                pos=obj.pos, ...
                ori=-obj.ori, ...
                spec=obj.spec.reversed());
        end
    end
    methods (Static, Access=private)
        function v = coerce_single_position(pos)
            if isa(pos, 'types.Vertices')
                v = pos;
            else
                v = types.Vertices(pos);
            end
            if v.nvertices ~= 1 || size(v.array, 2) ~= 2
                error("PortRef pos must be a single [x y] coordinate.");
            end
        end

        function o = normalize_orientation(ori)
            if isa(ori, 'types.Vertices')
                raw = ori.value;
            else
                raw = ori;
            end
            raw = double(raw);
            if numel(raw) ~= 2
                error("PortRef ori must be a 2D vector.");
            end
            o = reshape(raw, 1, 2);
            n = norm(o);
            if n <= 1e-15
                error("PortRef ori must be non-zero.");
            end
            o = o / n;
        end
    end
end

