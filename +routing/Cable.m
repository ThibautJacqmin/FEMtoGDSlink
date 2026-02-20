classdef Cable
    % Build multi-track cable geometry from two ports and one route.
    properties
        ctx
        name string
        port_in routing.PortRef
        port_out routing.PortRef
        route routing.Route
        raw_tracks cell
        features cell
        layers string
        centerlines cell
    end
    methods
        function obj = Cable(varargin)
            [ctx, port_in, port_out, args] = routing.Cable.parse_inputs(varargin{:});
            if isempty(ctx)
                ctx = core.GeometryPipeline.require_current();
            end
            obj.ctx = ctx;
            obj.name = string(args.name);
            obj.port_in = port_in;
            obj.port_out = port_out;

            pref = port_in.pos.prefactor;
            pref_out = port_out.pos.prefactor;
            if ~routing.Cable.prefactor_compatible(pref, pref_out)
                error("routing:Cable:InconsistentUnits", ...
                    "port_in and port_out positions must use compatible prefactors (same unit and scale).");
            end
            if abs(pref.value) <= 1e-15
                error("routing:Cable:InvalidPrefactor", ...
                    "Port position prefactor value must be non-zero.");
            end

            spec_in = port_in.spec;
            spec_out = port_out.spec;
            if args.require_matching_specs && ~spec_in.is_compatible(spec_out)
                error("routing:Cable:SpecMismatch", "%s", ...
                    "Port specs do not match. Use matching widths/offsets/layers or disable require_matching_specs and handle adaptors explicitly.");
            end

            if ~isempty(args.layer_override)
                layers = routing.Cable.normalize_layer_list(args.layer_override, spec_in.ntracks);
                spec_in = routing.PortSpec( ...
                    widths=spec_in.widths, ...
                    offsets=spec_in.offsets, ...
                    layers=layers, ...
                    subnames=spec_in.subnames);
            end

            if ~isempty(args.route)
                if ~isa(args.route, 'routing.Route')
                    error("routing:Cable:InvalidRoute", "route must be a routing.Route instance.");
                end
                route_local = args.route;
            elseif ~isempty(args.points)
                route_local = routing.Route(points=double(args.points), fillet=args.fillet);
            else
                route_local = routing.Route.manhattan( ...
                    port_in, port_out, ...
                    start_straight=args.start_straight, ...
                    end_straight=args.end_straight, ...
                    bend=args.bend, ...
                    fillet=args.fillet);
            end
            if lower(string(args.convexcorner)) == "fillet" && route_local.fillet > 1e-15
                min_fillet = 0.5 * max(spec_in.widths_value());
                if route_local.fillet < min_fillet - 1e-12
                    msg = sprintf([ ...
                        'Route fillet (%.3f nm) is too small for widest track (%.3f nm). ' ...
                        'Using %.3f nm so concave corners remain rounded.'], ...
                        route_local.fillet, max(spec_in.widths_value()), min_fillet);
                    warning("routing:Cable:FilletTooSmallForTrack", ...
                        "%s", msg);
                    route_local = routing.Route(points=route_local.points, fillet=min_fillet);
                end
            end
            obj.route = route_local;
            convex_mode = string(args.convexcorner);

            n = spec_in.ntracks;
            raw_local = cell(1, n);
            curves_local = cell(1, n);
            layer_local = strings(1, n);

            for i = 1:n
                layer_i = spec_in.layers(i);
                sub_i = spec_in.subnames(i);
                offset_i = spec_in.offset_value(i);
                width_i = spec_in.widths{i};

                pts_i = route_local.shifted_points(offset_i);
                curve_name = obj.name + "_" + sub_i + "_curve";
                curve_pts = types.Vertices(pts_i / pref.value, pref);
                curves_local{i} = primitives.InterpolationCurve(ctx, ...
                    points=curve_pts, type="open", width=1, layer=layer_i); %#ok<NASGU>
                raw_local{i} = ops.Thicken(ctx, curves_local{i}, ...
                    offset="symmetric", ...
                    totalthick=width_i, ...
                    ends=args.ends, ...
                    convexcorner=convex_mode, ...
                    keep_input_objects=args.keep_input_objects, ...
                    layer=layer_i);
                layer_local(i) = string(layer_i);
            end

            if args.merge_per_layer
                unique_layers = unique(layer_local, "stable");
                features_local = cell(1, numel(unique_layers));
                for k = 1:numel(unique_layers)
                    layer_k = unique_layers(k);
                    idx = find(layer_local == layer_k);
                    members = raw_local(idx);
                    if numel(members) == 1
                        features_local{k} = members{1};
                    else
                        features_local{k} = ops.Union(ctx, members, ...
                            keep_input_objects=args.keep_input_objects, ...
                            layer=layer_k);
                    end
                end
                obj.features = features_local;
                obj.layers = unique_layers;
            else
                obj.features = raw_local;
                obj.layers = layer_local;
            end

            obj.raw_tracks = raw_local;
            obj.centerlines = curves_local;
        end

        function y = length_nm(obj)
            y = obj.route.path_length();
        end

        function feats = terminal_features(obj)
            feats = obj.features;
        end
    end
    methods (Static)
        function obj = connect(varargin)
            obj = routing.Cable(varargin{:});
        end
    end
    methods (Static, Access=private)
        function [ctx, port_in, port_out, args] = parse_inputs(varargin)
            if isempty(varargin)
                error("routing:Cable:MissingInputs", ...
                    "Cable requires at least port_in and port_out.");
            end

            if isa(varargin{1}, 'core.GeometryPipeline')
                if numel(varargin) < 3
                    error("routing:Cable:MissingInputs", ...
                        "Cable(ctx, port_in, port_out, ...) requires port_in and port_out.");
                end
                ctx = varargin{1};
                port_in = varargin{2};
                port_out = varargin{3};
                nv = varargin(4:end);
            else
                if numel(varargin) < 2
                    error("routing:Cable:MissingInputs", ...
                        "Cable(port_in, port_out, ...) requires two ports.");
                end
                ctx = core.GeometryPipeline.get_current();
                port_in = varargin{1};
                port_out = varargin{2};
                nv = varargin(3:end);
            end

            if ~isa(port_in, 'routing.PortRef') || ~isa(port_out, 'routing.PortRef')
                error("routing:Cable:InvalidPorts", ...
                    "Cable expects routing.PortRef inputs for port_in and port_out.");
            end

            args = routing.Cable.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.route = []
                args.points = []
                args.fillet = 0
                args.start_straight = 0
                args.end_straight = []
                args.bend {mustBeTextScalar} = "auto"
                args.ends {mustBeTextScalar} = "straight"
                args.convexcorner {mustBeTextScalar} = "fillet"
                args.keep_input_objects logical = false
                args.merge_per_layer logical = true
                args.name {mustBeTextScalar} = "cable_0"
                args.layer_override = []
                args.require_matching_specs logical = true
            end
            parsed = args;
        end

        function layers = normalize_layer_list(raw_layers, n)
            layers = string(raw_layers);
            if isscalar(layers) && n > 1
                layers = repmat(layers, 1, n);
            end
            if numel(layers) ~= n
                error("layer_override must be scalar or match number of tracks (%d).", n);
            end
            layers = reshape(layers, 1, []);
        end

        function tf = prefactor_compatible(a, b)
            if ~isa(a, 'types.Parameter') || ~isa(b, 'types.Parameter')
                tf = false;
                return;
            end
            tf = abs(a.value - b.value) <= 1e-12 && string(a.unit) == string(b.unit);
        end
    end
end
