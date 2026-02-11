classdef GeomFeature < handle
    % Base class for geometry features in the feature graph.
    properties (Dependent)
        layer
    end
    properties
        id
        inputs
        params
        output logical = true
        is_initialized logical = false
    end
    properties (Access=protected)
        ctx
        layer_
    end
    methods
        function obj = GeomFeature(ctx, layer)
            % Construct a graph node bound to a GeometrySession context.
            if nargin < 1
                return;
            end
            obj.initialize_feature(ctx, layer);
        end

        function set.layer(obj, val)
            % Resolve and store layer mapping for this node.
            if isempty(obj.ctx)
                obj.layer_ = val;
            else
                obj.layer_ = obj.ctx.resolve_layer(val);
            end
        end

        function val = get.layer(obj)
            % Return resolved layer spec for this node.
            val = obj.layer_;
        end

        function ctx = context(obj)
            % Return owning GeometrySession.
            ctx = obj.ctx;
        end

        function add_input(obj, feature)
            % Append an upstream dependency node.
            obj.inputs{end+1} = feature;
        end

        function set_param(obj, name, value)
            % Set a named parameter payload on this node.
            obj.params.(char(name)) = value;
        end

        function value = get_param(obj, name, default)
            % Read a named parameter payload with optional default.
            if nargin < 3
                default = [];
            end
            key = char(name);
            if isfield(obj.params, key)
                value = obj.params.(key);
            else
                value = default;
            end
        end

        function finalize(obj)
            % Mark node initialized and trigger optional immediate emission.
            if obj.is_initialized
                return;
            end
            obj.is_initialized = true;
            if ~isempty(obj.ctx)
                obj.ctx.node_initialized(obj);
            end
        end
    end
    methods (Access=protected)
        function initialize_feature(obj, ctx, layer)
            % Initialize context/layer/parameter storage and register node.
            if isempty(ctx)
                ctx = GeometrySession.require_current();
            end
            obj.ctx = ctx;
            obj.inputs = {};
            obj.params = struct();
            if nargin >= 2 && ~isempty(layer)
                obj.layer = layer;
            else
                obj.layer = "default";
            end
            if ~isempty(ctx)
                ctx.register(obj);
            end
        end
    end
    methods (Static, Access=protected)
        function p = coerce_parameter(val, default_name, args)
            % Coerce scalar or Parameter to Parameter with optional unit override.
            arguments
                val
                default_name {mustBeTextScalar} = ""
                args.unit {mustBeTextScalar} = "nm"
            end
            if isa(val, 'Parameter')
                p = val;
                return;
            end
            p = Parameter(val, default_name, unit=args.unit);
        end

        function v = coerce_vertices(val)
            % Coerce numeric 2D value or Vertices to Vertices instance.
            if isa(val, 'Vertices')
                v = val;
                return;
            end
            v = Vertices(val);
        end
    end
end
