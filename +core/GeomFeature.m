classdef GeomFeature < handle
    % Base class for geometry features in the feature graph.
    properties (Dependent)
        % Resolved layer spec associated with this feature node.
        layer
    end
    properties
        % Monotonic graph node id assigned by GeometrySession.register.
        id
        % Upstream dependencies used to build this feature.
        inputs
        % Generic name/value payload used by concrete feature subclasses.
        params
        % True after constructor/factory finished populating this node.
        is_initialized logical = false
    end
    properties (Access=protected)
        % Owning geometry session context.
        ctx
        % Backing storage for dependent `layer` property.
        layer_
    end
    methods
        function obj = GeomFeature(ctx, layer)
            % Construct a graph node bound to a core.GeometrySession context.
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
            % Return owning core.GeometrySession.
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
                ctx = core.GeometrySession.require_current();
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
            % Coerce scalar or types.Parameter to types.Parameter with optional unit override.
            arguments
                val
                default_name {mustBeTextScalar} = ""
                args.unit {mustBeTextScalar} = "nm"
            end
            default_name = string(default_name); %#ok<NASGU>
            if isa(val, 'types.Parameter')
                p = val;
                return;
            end
            % Keep auto-coerced numeric values anonymous to avoid accidental
            % global COMSOL parameter-name collisions across features.
            p = types.Parameter(val, "", unit=args.unit);
        end

        function v = coerce_vertices(val)
            % Coerce numeric 2D value or types.Vertices to types.Vertices instance.
            if isa(val, 'types.Vertices')
                v = val;
                return;
            end
            v = types.Vertices(val);
        end

        function [ctx, target, nv] = parse_target_context(op_name, varargin)
            % Parse [ctx] target and trailing name/value options.
            op = string(op_name);
            if isempty(varargin)
                error("%s requires a target feature.", char(op));
            end

            if isa(varargin{1}, 'core.GeometrySession')
                ctx = varargin{1};
                if numel(varargin) < 2
                    error("%s requires a target feature.", char(op));
                end
                target = varargin{2};
                nv = varargin(3:end);
            else
                target = varargin{1};
                if isa(target, 'core.GeomFeature')
                    ctx = target.context();
                else
                    ctx = core.GeometrySession.require_current();
                end
                nv = varargin(2:end);
            end

            if ~isa(target, 'core.GeomFeature')
                error("%s target must be a GeomFeature.", char(op));
            end
        end

        function [ctx, members, nv] = parse_members_context(op_name, varargin)
            % Parse [ctx] members and trailing name/value options.
            op = string(op_name);
            if isempty(varargin)
                error("%s requires member features.", char(op));
            end

            if isa(varargin{1}, 'core.GeometrySession')
                ctx = varargin{1};
                if numel(varargin) < 2
                    error("%s requires member features.", char(op));
                end
                members = varargin{2};
                nv = varargin(3:end);
            else
                members = varargin{1};
                members = core.GeomFeature.normalize_feature_inputs(members, op);
                if ~isempty(members)
                    ctx = members{1}.context();
                else
                    ctx = core.GeometrySession.require_current();
                end
                nv = varargin(2:end);
            end

            members = core.GeomFeature.normalize_feature_inputs(members, op);
        end

        function [ctx, base, tools, nv] = parse_base_tools_context(op_name, varargin)
            % Parse [ctx] base, tools and trailing name/value options.
            op = string(op_name);
            if numel(varargin) < 2
                error("%s requires base and tool features.", char(op));
            end

            if isa(varargin{1}, 'core.GeometrySession')
                ctx = varargin{1};
                base = varargin{2};
                if numel(varargin) < 3
                    error("%s requires tool features.", char(op));
                end
                tools = varargin{3};
                nv = varargin(4:end);
            else
                base = varargin{1};
                tools = varargin{2};
                if isa(base, 'core.GeomFeature')
                    ctx = base.context();
                else
                    ctx = core.GeometrySession.require_current();
                end
                nv = varargin(3:end);
            end

            if ~isa(base, 'core.GeomFeature')
                error("%s base must be a GeomFeature.", char(op));
            end
            tools = core.GeomFeature.normalize_feature_inputs(tools, op + " tool");
        end

        function inputs = normalize_feature_inputs(members, op_name)
            % Normalize feature inputs to a validated cell array.
            if iscell(members)
                inputs = members;
            else
                inputs = num2cell(members);
            end

            op = string(op_name);
            for i = 1:numel(inputs)
                if ~isa(inputs{i}, 'core.GeomFeature')
                    error("%s members must be GeomFeature objects.", char(op));
                end
            end
        end
    end
end





