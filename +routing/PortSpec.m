classdef PortSpec
    % Port cross-section definition as multiple parallel tracks.
    properties
        widths cell
        offsets cell
        layers string
        subnames string
    end
    properties (Dependent)
        ntracks
    end
    methods
        function obj = PortSpec(args)
            arguments
                args.widths = 1
                args.offsets = 0
                args.layers = "default"
                args.subnames = string.empty(1, 0)
            end

            widths_local = routing.PortSpec.normalize_parameter_list(args.widths, "widths");
            if isempty(widths_local)
                error("PortSpec widths cannot be empty.");
            end
            for i = 1:numel(widths_local)
                if widths_local{i}.value <= 0
                    error("PortSpec widths must be > 0.");
                end
            end

            n = numel(widths_local);
            offsets_local = routing.PortSpec.normalize_parameter_list(args.offsets, "offsets");
            offsets_local = routing.PortSpec.broadcast_parameter_list(offsets_local, n, "offsets");

            layers_local = string(args.layers);
            if isscalar(layers_local) && n > 1
                layers_local = repmat(layers_local, 1, n);
            end
            if numel(layers_local) ~= n
                error("PortSpec layers must be scalar or match widths length (%d).", n);
            end
            layers_local = reshape(layers_local, 1, []);

            subnames_local = string(args.subnames);
            if isempty(subnames_local)
                subnames_local = strings(1, n);
                for i = 1:n
                    subnames_local(i) = "track" + string(i);
                end
            end
            if isscalar(subnames_local) && n > 1
                error("PortSpec subnames must be empty or match widths length (%d).", n);
            end
            if numel(subnames_local) ~= n
                error("PortSpec subnames must be empty or match widths length (%d).", n);
            end
            subnames_local = reshape(subnames_local, 1, []);

            obj.widths = widths_local;
            obj.offsets = offsets_local;
            obj.layers = layers_local;
            obj.subnames = subnames_local;
        end

        function n = get.ntracks(obj)
            n = numel(obj.widths);
        end

        function y = width_value(obj, i)
            y = routing.PortSpec.parameter_or_numeric_value(obj.widths{i}, "width");
        end

        function y = offset_value(obj, i)
            y = routing.PortSpec.parameter_or_numeric_value(obj.offsets{i}, "offset");
        end

        function y = widths_value(obj)
            y = zeros(1, obj.ntracks);
            for i = 1:obj.ntracks
                y(i) = obj.width_value(i);
            end
        end

        function y = offsets_value(obj)
            y = zeros(1, obj.ntracks);
            for i = 1:obj.ntracks
                y(i) = obj.offset_value(i);
            end
        end

        function [top, bottom] = outer_bounds_value(obj)
            top = -inf;
            bottom = inf;
            for i = 1:obj.ntracks
                oi = obj.offset_value(i);
                wi = obj.width_value(i);
                top = max(top, oi + wi / 2);
                bottom = min(bottom, oi - wi / 2);
            end
        end

        function out = reversed(obj)
            offsets_local = cell(1, obj.ntracks);
            for i = 1:obj.ntracks
                offsets_local{i} = routing.PortSpec.negate_parameter(obj.offsets{i});
            end
            out = routing.PortSpec( ...
                widths=obj.widths, ...
                offsets=offsets_local, ...
                layers=obj.layers, ...
                subnames=obj.subnames);
        end

        function out = with_mask(obj, args)
            arguments
                obj
                args.layer = "mask"
                args.gap = 0
                args.subname {mustBeTextScalar} = "mask"
            end
            gap_p = routing.PortSpec.coerce_parameter(args.gap, "gap");
            top = obj.offsets{1} + obj.widths{1} / 2;
            bottom = obj.offsets{1} - obj.widths{1} / 2;
            top_v = top.value;
            bottom_v = bottom.value;
            for i = 2:obj.ntracks
                ti = obj.offsets{i} + obj.widths{i} / 2;
                bi = obj.offsets{i} - obj.widths{i} / 2;
                if ti.value > top_v
                    top = ti;
                    top_v = ti.value;
                end
                if bi.value < bottom_v
                    bottom = bi;
                    bottom_v = bi.value;
                end
            end

            mask_width = top - bottom + 2 * gap_p;
            mask_offset = (top + bottom) / 2;

            widths_local = [obj.widths, {types.Parameter(mask_width, "", ...
                unit=mask_width.unit, expression=mask_width.expr, auto_register=false)}];
            offsets_local = [obj.offsets, {types.Parameter(mask_offset, "", ...
                unit=mask_offset.unit, expression=mask_offset.expr, auto_register=false)}];
            layers_local = [obj.layers, string(args.layer)];
            subnames_local = [obj.subnames, string(args.subname)];
            out = routing.PortSpec( ...
                widths=widths_local, ...
                offsets=offsets_local, ...
                layers=layers_local, ...
                subnames=subnames_local);
        end

        function tf = is_compatible(obj, other, args)
            arguments
                obj
                other routing.PortSpec
                args.check_widths logical = true
                args.check_offsets logical = true
                args.tol double = 1e-12
            end
            if obj.ntracks ~= other.ntracks
                tf = false;
                return;
            end
            if any(string(obj.layers) ~= string(other.layers))
                tf = false;
                return;
            end
            if args.check_widths
                if any(abs(obj.widths_value() - other.widths_value()) > args.tol)
                    tf = false;
                    return;
                end
            end
            if args.check_offsets
                if any(abs(obj.offsets_value() - other.offsets_value()) > args.tol)
                    tf = false;
                    return;
                end
            end
            tf = true;
        end
    end
    methods (Static, Access=private)
        function p = coerce_parameter(val, label)
            if isa(val, 'types.Parameter')
                p = val;
                return;
            end
            if ~(isscalar(val) && isnumeric(val) && isfinite(val))
                error("PortSpec %s must be a finite scalar or types.Parameter.", char(string(label)));
            end
            p = types.Parameter(val, "", unit="", auto_register=false);
        end

        function q = negate_parameter(p)
            if ~isa(p, 'types.Parameter')
                q = types.Parameter(-double(p), "", unit="", auto_register=false);
                return;
            end
            token = string(p.expression_token());
            expr = "-(" + token + ")";
            q = types.Parameter(-p.value, "", unit=p.unit, expression=expr, auto_register=false);
        end

        function values = normalize_parameter_list(raw, label)
            if isa(raw, 'types.Parameter')
                seq = {raw};
            elseif isnumeric(raw)
                if isscalar(raw)
                    seq = {raw};
                else
                    seq = num2cell(raw(:).');
                end
            elseif iscell(raw)
                seq = raw;
            else
                error("PortSpec %s must be scalar/vector numeric, types.Parameter, or cell.", ...
                    char(string(label)));
            end

            values = cell(1, numel(seq));
            for i = 1:numel(seq)
                values{i} = routing.PortSpec.coerce_parameter(seq{i}, label);
            end
        end

        function values = broadcast_parameter_list(values, n, label)
            if numel(values) == 1 && n > 1
                values = repmat(values, 1, n);
                return;
            end
            if numel(values) ~= n
                error("PortSpec %s must be scalar or match widths length (%d).", ...
                    char(string(label)), n);
            end
        end

        function y = parameter_or_numeric_value(val, label)
            if isa(val, 'types.Parameter')
                y = val.value;
            else
                y = val;
            end
            if ~(isscalar(y) && isnumeric(y) && isfinite(y))
                error("PortSpec %s must resolve to a finite scalar.", char(string(label)));
            end
            y = double(y);
        end
    end
end
