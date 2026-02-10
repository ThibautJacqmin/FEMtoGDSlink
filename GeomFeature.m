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
    end
    properties (Access=protected)
        ctx
        layer_
    end
    methods
        function obj = GeomFeature(ctx, layer)
            if nargin < 1
                return;
            end
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

        function set.layer(obj, val)
            if isempty(obj.ctx)
                obj.layer_ = val;
            else
                obj.layer_ = obj.ctx.resolve_layer(val);
            end
        end

        function val = get.layer(obj)
            val = obj.layer_;
        end

        function ctx = context(obj)
            ctx = obj.ctx;
        end

        function add_input(obj, feature)
            obj.inputs{end+1} = feature;
        end

        function set_param(obj, name, value)
            obj.params.(char(name)) = value;
        end

        function value = get_param(obj, name, default)
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
    end
end
