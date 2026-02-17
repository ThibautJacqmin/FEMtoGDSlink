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

        function [ymax, ymin] = bond_params(obj)
            [ymax, ymin] = obj.spec.outer_bounds_value();
        end

        function tris = marker_triangles(obj, args)
            % Build one triangular launch marker per track.
            arguments
                obj
                args.tip_length = []
                args.tip_scale double = 1/3
            end
            n = obj.spec.ntracks;
            tris = cell(1, n);
            pref = obj.pos.prefactor;
            if abs(pref.value) <= 1e-15
                error("PortRef position prefactor must be non-zero.");
            end
            for i = 1:n
                width_i = obj.spec.width_value(i);
                if isempty(args.tip_length)
                    tip_i = args.tip_scale * width_i;
                else
                    tip_i = routing.PortRef.scalar_value(args.tip_length, "tip_length");
                end
                off_i = obj.spec.offset_value(i);
                [p_top, p_bottom] = obj.track_edges(i, 0);
                p_tip = obj.local_point(tip_i, off_i);
                tri_val = [p_top; p_tip; p_bottom];
                tris{i} = types.Vertices(tri_val / pref.value, pref);
            end
        end

        function features = draw_markers(obj, args)
            % Emit triangular launch markers as Polygon primitives.
            arguments
                obj
                args.ctx core.GeometrySession = core.GeometrySession.empty
                args.layer = "port"
                args.tip_length = []
                args.tip_scale double = 1/3
            end
            if isempty(args.ctx)
                ctx = core.GeometrySession.require_current();
            else
                ctx = args.ctx;
            end
            tris = obj.marker_triangles(tip_length=args.tip_length, tip_scale=args.tip_scale);
            features = cell(1, numel(tris));
            for i = 1:numel(tris)
                features{i} = primitives.Polygon(ctx, vertices=tris{i}, layer=args.layer);
            end
        end

        function ports = split(obj, args)
            % Split selected tracks into CPW-style two-track PortRef objects.
            arguments
                obj
                args.subnames = []
                args.gap = []
                args.gap_layer {mustBeTextScalar} = "gap"
            end
            idx = routing.PortRef.select_tracks(obj.spec.subnames, args.subnames);
            ports = cell(1, numel(idx));
            nrm = obj.normal();
            pref = obj.pos.prefactor;
            for k = 1:numel(idx)
                i = idx(k);
                width_i = obj.spec.widths{i};
                width_i_v = obj.spec.width_value(i);
                if isempty(args.gap)
                    gap_i = width_i;
                else
                    if isa(args.gap, 'types.Parameter')
                        gap_i = args.gap;
                    else
                        gap_i_v = routing.PortRef.scalar_value(args.gap, "gap");
                        gap_i = types.Parameter(gap_i_v, "", ...
                            unit=width_i.unit, auto_register=false);
                    end
                end
                spec_i = routing.PortSpec( ...
                    widths={width_i, width_i + 2 * gap_i}, ...
                    offsets={0, 0}, ...
                    layers=[obj.spec.layers(i), string(args.gap_layer)], ...
                    subnames=["track", "gap"]);
                pos_i_val = obj.position_value() + obj.spec.offset_value(i) * nrm;
                pos_i = types.Vertices(pos_i_val / pref.value, pref);
                name_i = obj.name + "_" + obj.spec.subnames(i);
                ports{k} = routing.PortRef(name=name_i, pos=pos_i, ori=obj.ori, spec=spec_i);
            end
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

        function y = scalar_value(val, label)
            if isa(val, 'types.Parameter')
                y = val.value;
            else
                y = val;
            end
            if ~(isscalar(y) && isnumeric(y) && isfinite(y))
                error("PortRef %s must resolve to a finite scalar.", char(string(label)));
            end
            y = double(y);
        end

        function idx = select_tracks(subnames, selected)
            n = numel(subnames);
            if isempty(selected)
                idx = 1:n;
                return;
            end
            if isnumeric(selected) && isscalar(selected) && selected == -1
                idx = 1:max(0, n - 1);
                return;
            end
            names = string(selected);
            idx = zeros(1, numel(names));
            for i = 1:numel(names)
                k = find(subnames == names(i), 1, "first");
                if isempty(k)
                    error("PortRef split subname '%s' not found.", char(names(i)));
                end
                idx(i) = k;
            end
        end
    end
end
