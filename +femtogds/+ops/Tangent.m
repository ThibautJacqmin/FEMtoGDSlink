classdef Tangent < femtogds.core.GeomFeature
    % Tangent line segment to one or two edges.
    properties (Dependent)
        target
        type
        coord
        start
        start2
        edge2
        point_target
        edge_index
        edge2_index
        point_index
        width
    end
    methods
        function obj = Tangent(varargin)
            [ctx, target, args] = femtogds.ops.Tangent.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@femtogds.core.GeomFeature(ctx, layer);
            obj.add_input(target);
            if ~isempty(args.edge2)
                if ~isa(args.edge2, 'femtogds.core.GeomFeature')
                    error("Tangent edge2 must be a femtogds.core.GeomFeature.");
                end
                obj.add_input(args.edge2);
            end
            if ~isempty(args.point_target)
                if ~isa(args.point_target, 'femtogds.core.GeomFeature')
                    error("Tangent point_target must be a femtogds.core.GeomFeature.");
                end
                obj.add_input(args.point_target);
            end

            obj.type = args.type;
            obj.coord = args.coord;
            obj.start = args.start;
            obj.start2 = args.start2;
            obj.edge2 = args.edge2;
            obj.point_target = args.point_target;
            obj.edge_index = args.edge_index;
            obj.edge2_index = args.edge2_index;
            obj.point_index = args.point_index;
            obj.width = args.width;
            obj.finalize();
        end

        function val = get.target(obj)
            val = obj.inputs{1};
        end

        function set.type(obj, val)
            t = femtogds.ops.Tangent.normalize_type(val);
            obj.set_param("type", t);
        end

        function val = get.type(obj)
            val = obj.get_param("type", "coord");
        end

        function set.coord(obj, val)
            v = femtogds.core.GeomFeature.coerce_vertices(val);
            if size(v.array, 1) ~= 1 || size(v.array, 2) ~= 2
                error("Tangent coord must be a single [x y] coordinate.");
            end
            obj.set_param("coord", v);
        end

        function val = get.coord(obj)
            val = obj.get_param("coord", femtogds.types.Vertices([1, 0]));
        end

        function set.start(obj, val)
            p = femtogds.core.GeomFeature.coerce_parameter(val, "", unit="");
            if ~(isscalar(p.value) && isfinite(p.value))
                error("Tangent start must be a finite real scalar.");
            end
            obj.set_param("start", p);
        end

        function val = get.start(obj)
            val = obj.get_param("start", femtogds.types.Parameter(0.5, "", unit=""));
        end

        function set.start2(obj, val)
            p = femtogds.core.GeomFeature.coerce_parameter(val, "", unit="");
            if ~(isscalar(p.value) && isfinite(p.value))
                error("Tangent start2 must be a finite real scalar.");
            end
            obj.set_param("start2", p);
        end

        function val = get.start2(obj)
            val = obj.get_param("start2", femtogds.types.Parameter(0.5, "", unit=""));
        end

        function set.edge2(obj, val)
            if ~isempty(val) && ~isa(val, 'femtogds.core.GeomFeature')
                error("Tangent edge2 must be empty or a femtogds.core.GeomFeature.");
            end
            obj.set_param("edge2", val);
        end

        function val = get.edge2(obj)
            val = obj.get_param("edge2", []);
        end

        function set.point_target(obj, val)
            if ~isempty(val) && ~isa(val, 'femtogds.core.GeomFeature')
                error("Tangent point_target must be empty or a femtogds.core.GeomFeature.");
            end
            obj.set_param("point_target", val);
        end

        function val = get.point_target(obj)
            val = obj.get_param("point_target", []);
        end

        function set.edge_index(obj, val)
            p = femtogds.core.GeomFeature.coerce_parameter(val, "", unit="");
            n = round(double(p.value));
            if ~(isscalar(n) && isfinite(n) && n >= 1)
                error("Tangent edge_index must be an integer >= 1.");
            end
            obj.set_param("edge_index", femtogds.types.Parameter(n, "", unit=""));
        end

        function val = get.edge_index(obj)
            val = obj.get_param("edge_index", femtogds.types.Parameter(1, "", unit=""));
        end

        function set.edge2_index(obj, val)
            p = femtogds.core.GeomFeature.coerce_parameter(val, "", unit="");
            n = round(double(p.value));
            if ~(isscalar(n) && isfinite(n) && n >= 1)
                error("Tangent edge2_index must be an integer >= 1.");
            end
            obj.set_param("edge2_index", femtogds.types.Parameter(n, "", unit=""));
        end

        function val = get.edge2_index(obj)
            val = obj.get_param("edge2_index", femtogds.types.Parameter(1, "", unit=""));
        end

        function set.point_index(obj, val)
            p = femtogds.core.GeomFeature.coerce_parameter(val, "", unit="");
            n = round(double(p.value));
            if ~(isscalar(n) && isfinite(n) && n >= 1)
                error("Tangent point_index must be an integer >= 1.");
            end
            obj.set_param("point_index", femtogds.types.Parameter(n, "", unit=""));
        end

        function val = get.point_index(obj)
            val = obj.get_param("point_index", femtogds.types.Parameter(1, "", unit=""));
        end

        function set.width(obj, val)
            p = femtogds.core.GeomFeature.coerce_parameter(val, "", unit="");
            if ~(isscalar(p.value) && isfinite(p.value) && p.value > 0)
                error("Tangent width must be a finite real scalar > 0.");
            end
            obj.set_param("width", p);
        end

        function val = get.width(obj)
            val = obj.get_param("width", femtogds.types.Parameter(1, "", unit=""));
        end
    end
    methods (Static, Access=private)
        function [ctx, target, args] = parse_inputs(varargin)
            [ctx, target, nv] = femtogds.core.GeomFeature.parse_target_context("Tangent", varargin{:});
            args = femtogds.ops.Tangent.parse_options(nv{:});
        end

        function parsed = parse_options(args)
            arguments
                args.type {mustBeTextScalar} = "coord"
                args.coord = [1, 0]
                args.start = 0.5
                args.start2 = 0.5
                args.edge2 = []
                args.point_target = []
                args.edge_index = 1
                args.edge2_index = 1
                args.point_index = 1
                args.width = 1
                args.layer = []
            end
            parsed = args;
        end

        function t = normalize_type(val)
            t = lower(string(val));
            if ~any(t == ["edge", "point", "coord"])
                error("Tangent type must be 'edge', 'point', or 'coord'.");
            end
        end
    end
end



