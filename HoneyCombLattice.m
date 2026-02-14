classdef HoneyCombLattice < Lattice
    % Class to represent a honeycomb lattice with rectangular bounding box.
    properties
        hexagonal_lattice % base hexagonal lattice
        M     % coordinates of M symmetry point in reciprocal space
        K     % coordinates of K (Dirac) symmetry point in reciprocal space
        siteA % coordinates of site A in single unit cell
        siteB % coordinates of site B in single unit cell
    end
    methods
        function obj = HoneyCombLattice(a, nw, nh)
            % Constructor to initialize the honeycomb lattice.
            obj = obj@Lattice(a, nw, nh);
            obj.hexagonal_lattice = HexagonalLattice(obj.a, obj.nw, obj.nh);
            obj.nodes = obj.computeGeometry("Honeycomb");
        end

        function lattice_nodes = computeHoneycombGeometry(obj)
            % Compute coordinates of A/B sublattices and hexagon centers.
            lattice_nodes = struct();
            lattice_nodes.sublatticeA = obj.hexagonal_lattice.nodes;

            sublatticeB = zeros(size(lattice_nodes.sublatticeA));
            sublatticeB(:, :, 1) = lattice_nodes.sublatticeA(:, :, 1) + obj.a / 2;
            sublatticeB(:, :, 2) = lattice_nodes.sublatticeA(:, :, 2) + obj.a/2/sqrt(3);
            lattice_nodes.sublatticeB = sublatticeB;

            hexagon_centers = zeros(size(lattice_nodes.sublatticeA));
            hexagon_centers(:, :, 1) = lattice_nodes.sublatticeA(:, :, 1);
            hexagon_centers(:, :, 2) = lattice_nodes.sublatticeA(:, :, 2) + obj.a / sqrt(3);
            lattice_nodes.hexagon_centers = hexagon_centers;
        end

        function lattice_nodes = computeHoneyCombGeometry(obj)
            % Backward-compatible legacy spelling alias.
            lattice_nodes = obj.computeHoneycombGeometry();
        end

        function y = get.M(obj)
            y = obj.hexagonal_lattice.M;
        end

        function y = get.K(obj)
            y = obj.hexagonal_lattice.K;
        end

        function z = get.siteA(obj)
            c = obj.unitCellContour;
            x = c(1, 1) + (obj.a1(1)+obj.a2(1))/3;
            y = c(1, 2) + (obj.a1(2)+obj.a2(2))/3;
            z = [x, y];
        end

        function z = get.siteB(obj)
            x = obj.siteA(1) + (obj.a1(1)+obj.a2(1))/3;
            y = obj.siteA(2) + (obj.a1(2)+obj.a2(2))/3;
            z = [x, y];
        end

        function feature = circleArray(obj, args)
            % Build circles on honeycomb sublattices using parameterized Array features.
            arguments
                obj
                args.ctx femtogds.core.GeometrySession = femtogds.core.GeometrySession.empty
                args.radius = 1
                args.npoints = 96
                args.layer = "default"
                args.a_parameter = []
                args.sublattice {mustBeTextScalar} = "AB"
            end

            if isempty(args.ctx)
                ctx = femtogds.core.GeometrySession.require_current();
            else
                ctx = args.ctx;
            end

            seed = femtogds.primitives.Circle(ctx, center=[0, 0], ...
                radius=args.radius, npoints=args.npoints, layer=args.layer);
            feature = obj.arrayFromFeature(ctx=ctx, seed=seed, sublattice=args.sublattice, ...
                layer=args.layer, a_parameter=args.a_parameter);
        end

        function feature = arrayFromFeature(obj, args)
            % Replicate feature(s) on selected honeycomb site families.
            arguments
                obj
                args.ctx femtogds.core.GeometrySession = femtogds.core.GeometrySession.empty
                args.seed = []
                args.seedA = []
                args.seedB = []
                args.seedCenters = []
                args.sublattice {mustBeTextScalar} = "AB"
                args.layer = []
                args.a_parameter = []
            end

            [ctx, layer, seedA, seedB, seedCenters] = obj.resolve_seeds(args);
            key = lower(string(args.sublattice));
            switch key
                case {"a", "sublatticea", "sitea"}
                    feature = obj.hexagonal_lattice.arrayFromFeature(ctx=ctx, seed=seedA, ...
                        layer=layer, a_parameter=args.a_parameter, offset=[0, 0]);
                case {"b", "sublatticeb", "siteb"}
                    feature = obj.hexagonal_lattice.arrayFromFeature(ctx=ctx, seed=seedB, ...
                        layer=layer, a_parameter=args.a_parameter, offset=[0.5, 1/(2*sqrt(3))]);
                case {"ab", "all", "*"}
                    arr_A = obj.hexagonal_lattice.arrayFromFeature(ctx=ctx, seed=seedA, ...
                        layer=layer, a_parameter=args.a_parameter, offset=[0, 0]);
                    arr_B = obj.hexagonal_lattice.arrayFromFeature(ctx=ctx, seed=seedB, ...
                        layer=layer, a_parameter=args.a_parameter, offset=[0.5, 1/(2*sqrt(3))]);
                    feature = femtogds.ops.Union(ctx, {arr_A, arr_B}, layer=layer);
                case {"centers", "hexagon_centers", "center"}
                    feature = obj.hexagonal_lattice.arrayFromFeature(ctx=ctx, seed=seedCenters, ...
                        layer=layer, a_parameter=args.a_parameter, offset=[0, 1/sqrt(3)]);
                otherwise
                    error("Unknown honeycomb sublattice selector '%s'.", char(string(args.sublattice)));
            end
        end
    end
    methods (Access=private)
        function [ctx, layer, seedA, seedB, seedCenters] = resolve_seeds(~, args)
            seed_default = args.seed;
            seedA = args.seedA;
            seedB = args.seedB;
            seedCenters = args.seedCenters;

            if isempty(seedA), seedA = seed_default; end
            if isempty(seedB), seedB = seed_default; end
            if isempty(seedCenters), seedCenters = seed_default; end
            if isempty(seedA) && isempty(seedB) && isempty(seedCenters)
                error("HoneyCombLattice arrayFromFeature requires seed or seedA/seedB/seedCenters.");
            end

            if isempty(args.ctx)
                ctx = [];
                if ~isempty(seedA), ctx = seedA.context(); end
                if isempty(ctx) && ~isempty(seedB), ctx = seedB.context(); end
                if isempty(ctx) && ~isempty(seedCenters), ctx = seedCenters.context(); end
            else
                ctx = args.ctx;
            end
            if isempty(ctx)
                error("HoneyCombLattice arrayFromFeature requires a valid GeometrySession context.");
            end

            seeds = {seedA, seedB, seedCenters};
            for i = 1:numel(seeds)
                s = seeds{i};
                if isempty(s)
                    continue;
                end
                if ~isa(s, "femtogds.core.GeomFeature")
                    error("HoneyCombLattice seeds must be GeomFeature objects.");
                end
                if ~isequal(s.context(), ctx)
                    error("HoneyCombLattice seed contexts must match provided ctx.");
                end
            end

            if isempty(args.layer)
                if ~isempty(seedA)
                    layer = seedA.layer;
                elseif ~isempty(seedB)
                    layer = seedB.layer;
                else
                    layer = seedCenters.layer;
                end
            else
                layer = args.layer;
            end
        end
    end
end
