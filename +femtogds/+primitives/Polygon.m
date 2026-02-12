classdef Polygon < femtogds.core.GeomFeature
    % Polygon primitive represented by an ordered list of 2D vertices.
    %
    % The class has two modes:
    % 1) Feature mode (with a femtogds.core.GeometrySession): registers as a graph node.
    % 2) Lightweight mode (no active session): plain container used by
    %    legacy GDS helper utilities that only need `pgon_py` and `vertices`.
    properties (Dependent)
        vertices
    end
    properties
        pgon_py = []
        comsol_modeler = femtogds.core.ComsolModeler.empty
        comsol_shape = []
        comsol_name = ""
    end
    properties (Access=private)
        vertices_ femtogds.types.Vertices = femtogds.types.Vertices.empty
    end
    methods
        function obj = Polygon(varargin)
            obj@femtogds.core.GeomFeature();
            if nargin == 0
                obj.inputs = {};
                obj.params = struct();
                obj.output = true;
                obj.is_initialized = true;
                return;
            end

            [ctx, args] = Polygon.parse_inputs(varargin{:});
            if isempty(ctx)
                % No active session: behave as a lightweight data container.
                obj.inputs = {};
                obj.params = struct();
                obj.output = logical(args.output);
                obj.layer = string(args.layer);
                if ~isempty(args.vertices)
                    obj.vertices = args.vertices;
                end
                obj.comsol_modeler = args.comsol_modeler;
                obj.is_initialized = true;
                return;
            end

            obj.initialize_feature(ctx, args.layer);
            obj.output = logical(args.output);
            obj.vertices = args.vertices;
            if isempty(obj.vertices) || obj.vertices.nvertices < 3
                error("Polygon requires at least 3 vertices.");
            end
            obj.finalize();
        end

        function set.vertices(obj, val)
            if isempty(val)
                obj.vertices_ = femtogds.types.Vertices.empty;
                return;
            end
            v = femtogds.core.GeomFeature.coerce_vertices(val);
            if size(v.array, 2) ~= 2
                error("Polygon vertices must be an Nx2 coordinate array.");
            end
            obj.vertices_ = v;
        end

        function val = get.vertices(obj)
            val = obj.vertices_;
        end

        function y = nvertices(obj)
            if isempty(obj.vertices)
                y = 0;
            else
                y = obj.vertices.nvertices;
            end
        end

        function y = vertices_value(obj)
            if isempty(obj.vertices)
                y = zeros(0, 2);
            else
                y = obj.vertices.value;
            end
        end

        function tf = comsol_flag(obj)
            tf = ~isempty(obj.comsol_modeler);
        end
    end
    methods (Static, Access=private)
        function [ctx, args] = parse_inputs(varargin)
            if ~isempty(varargin) && isa(varargin{1}, 'femtogds.core.GeometrySession')
                ctx = varargin{1};
                nv = varargin(2:end);
            else
                ctx = femtogds.core.GeometrySession.get_current();
                nv = varargin;
            end
            args = Polygon.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.vertices = []
                args.layer = "default"
                args.output logical = true
                % Legacy compatibility: accepted but unused in feature mode.
                args.comsol_modeler = femtogds.core.ComsolModeler.empty
            end
            parsed = args;
        end
    end
end




