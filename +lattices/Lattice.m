classdef Lattice < handle
    properties
        nodes % Coordinates of the lattice nodes
        a % lattice constant
        a1 % real space base vector 1
        a2 % real space base vector 2
        b % Lattice constant
        b1 % real space base vector 1
        b2 % real space base vector 2
        nw % number of unit cells in the width of the square structure
        nh % number of unit cells in the height of the square structure
        Gamma = [0, 0] % coordinates of Gamma symmetry point in reciprocal space
        unitCellContour % Vertices of unit cell contour
        irreducibleBrillouinZoneContour % Vertices of irreducible Brillouin Zone
    end
    methods
        function obj = Lattice(a, nw, nh)
            % Constructor to initialize the lattice
            arguments
                a {mustBeNumeric, mustBeReal, mustBeFinite, mustBePositive}
                nw {mustBeInteger, mustBePositive}
                nh {mustBeInteger, mustBePositive}
            end
            if ~(isscalar(a) && isscalar(nw) && isscalar(nh))
                error("Lattice constructor requires scalar inputs a, nw, nh.");
            end
            obj.a = a;
            obj.nw = nw;
            obj.nh = nh;
        end

        function y = get.a1(obj)
            % Real space base vector a1
            y = obj.a * [1, 0];
        end

        function y = get.a2(obj)
            % Real space base vector a2
            y = obj.a * [1/2, sqrt(3)/2];
        end

        function y = get.b(obj)
            % Reciprocal space norm of base vector
            y = 4*pi/sqrt(3)/obj.a;
        end

        function y = get.b1(obj)
            % Reciprocal lattice vector b1
            y = obj.b * [1/2, -sqrt(3)/2];
        end

        function y = get.b2(obj)
            % Reciprocal lattice vector b2
            y = obj.b * [1/2, sqrt(3)/2];
        end

        function y = get.irreducibleBrillouinZoneContour(obj)
            % Coordinates of the corners of the irreducible BZ
            y = [obj.Gamma; obj.M; obj.K; obj.Gamma];
        end

        function c = get.unitCellContour(obj)
            x = [0, obj.a1(1), obj.a1(1) + obj.a2(1), obj.a2(1), 0];
            y = [0, obj.a1(2), obj.a1(2) + obj.a2(2), obj.a2(2), 0];
            c = [x; y]';
        end

        function lattice_nodes = computeGeometry(obj, name)
            arguments
                obj
                name {mustBeTextScalar}
            end
            canonical_name = lattices.Lattice.canonical_lattice_name(name);
            lattice_nodes = obj.("compute" + canonical_name + "Geometry");
        end

        function sites = get_sites(obj, args)
            % Return lattice sites as Nx2 coordinates (default) or native grid.
            arguments
                obj
                args.which {mustBeTextScalar} = "all"
                args.as_grid logical = false
            end

            key = lower(string(args.which));
            if isstruct(obj.nodes)
                switch key
                    case {"a", "sitea", "sublatticea"}
                        sites = lattices.Lattice.extract_site_field(obj.nodes, "sublatticeA", args.as_grid);
                    case {"b", "siteb", "sublatticeb"}
                        sites = lattices.Lattice.extract_site_field(obj.nodes, "sublatticeB", args.as_grid);
                    case {"center", "centers", "hexagon_center", "hexagon_centers"}
                        sites = lattices.Lattice.extract_site_field(obj.nodes, "hexagon_centers", args.as_grid);
                    case {"all", "*"}
                        sites = struct();
                        sites.A = lattices.Lattice.extract_site_field(obj.nodes, "sublatticeA", args.as_grid);
                        sites.B = lattices.Lattice.extract_site_field(obj.nodes, "sublatticeB", args.as_grid);
                        sites.centers = lattices.Lattice.extract_site_field(obj.nodes, "hexagon_centers", args.as_grid);
                    otherwise
                        error("Unknown site selector '%s' for multi-sublattice lattice.", ...
                            char(string(args.which)));
                end
            else
                if ~(key == "all" || key == "sites" || key == "*")
                    error("Unknown site selector '%s' for single-sublattice lattice.", ...
                        char(string(args.which)));
                end
                sites = lattices.Lattice.flatten_nodes(obj.nodes, args.as_grid);
            end
        end

        function plotRealSpace(obj)
            % Create the plot
            figure;
            hold on;
            % Plot real-space lattice vectors
            quiver(0, 0, obj.a1(1), obj.a1(2), 0, 'r', 'LineWidth', 1.5, 'DisplayName', 'a1');
            quiver(0, 0, obj.a2(1), obj.a2(2), 0, 'b', 'LineWidth', 1.5, 'DisplayName', 'a2');
            % Draw unit cell
            fill(obj.unitCellContour(:, 1), obj.unitCellContour(:, 2), 'g', 'FaceAlpha', 0.2, ...
                'EdgeColor', 'none', 'HandleVisibility', 'off');
            % Add labels and legend
            xlabel('x');
            ylabel('y');
            legend('Location', 'best');
            grid on;
            axis equal;
            % Add title
            title('Real space');
            % Check if many sublattices or single lattice
            markerlist = ['o', '+', '*', 'x', 'v', 'd'];
            colorlist = ['r', 'b', 'k', 'g', 'c', 'y'];
            i = 1;
            if isstruct(obj.nodes)
                for sublattice = string(fieldnames(obj.nodes))'
                    p = obj.plotRS(obj.nodes.(sublattice), sublattice);
                    p.Marker = markerlist(i);
                    p.MarkerEdgeColor = colorlist(i);
                    i = i+1;
                end
            else
                obj.plotRS(obj.nodes);
            end
        end

        function plotReciprocalSpace(obj)
            % Plot the reciprocal lattice and symmetry points

            % Define the reciprocal lattice hexagon vertices
            bz_vertices = [obj.b1; obj.b1+obj.b2; obj.b2; -obj.b1; -obj.b1-obj.b2; -obj.b2; obj.b1]./2;

            % Create the plot
            figure;
            hold on;

            % Plot reciprocal lattice vectors
            quiver(0, 0, obj.b1(1), obj.b1(2), 0, 'r', 'LineWidth', 1.5, 'DisplayName', 'b1');
            quiver(0, 0, obj.b2(1), obj.b2(2), 0, 'b', 'LineWidth', 1.5, 'DisplayName', 'b2');

            % Plot the Brillouin zone (hexagon)
            plot(bz_vertices(:, 1), bz_vertices(:, 2), 'k-', 'LineWidth', 1.2, ...
                'HandleVisibility', 'off');

            % Plot symmetry points
            scatter([obj.Gamma(1), obj.M(1), obj.K(1)], ...
                [obj.Gamma(2), obj.M(2), obj.K(2)], 50, 'k', 'filled', ...
                'DisplayName', 'Symmetry Points');
            text(obj.Gamma(1), obj.Gamma(2), '\Gamma', 'VerticalAlignment', 'bottom');
            text(obj.M(1), obj.M(2), 'M', 'VerticalAlignment', 'top');
            text(obj.K(1), obj.K(2), 'K', 'VerticalAlignment', 'bottom');

            % Fill the triangle formed by Gamma, M, and K
            fill(obj.irreducibleBrillouinZoneContour(:,1), ...
                obj.irreducibleBrillouinZoneContour(:,2), 'g', 'FaceAlpha', 0.2, ...
                'EdgeColor', 'none', 'HandleVisibility', 'off');

            % Label axes
            xlabel('k_x');
            ylabel('k_y');
            title('Hexagonal lattice: Reciprocal space');
            axis equal;

            % Adjust axis limits
            b_norm = norm(obj.b1);
            xlim([-b_norm * 1.5, b_norm * 1.5]);
            ylim([-b_norm * 1.5, b_norm * 1.5]);

            legend('Location', 'best');
            grid on;
            hold off;
        end
    end

    methods (Static)
        function lattice = from_name(name, a, nw, nh)
            % Construct a lattice object from a user-facing lattice name.
            arguments
                name {mustBeTextScalar}
                a {mustBeNumeric, mustBeReal, mustBeFinite, mustBePositive}
                nw {mustBeInteger, mustBePositive}
                nh {mustBeInteger, mustBePositive}
            end

            canonical_name = lattices.Lattice.canonical_lattice_name(name);
            switch canonical_name
                case "Hexagonal"
                    lattice = lattices.HexagonalLattice(a, nw, nh);
                case "Honeycomb"
                    lattice = lattices.HoneyCombLattice(a, nw, nh);
                otherwise
                    error("Unsupported lattice type '%s'.", char(string(name)));
            end
        end

        function [feature, lattice] = createLattice(args)
            % Create a lattice object and replicate seed feature(s) at its sites.
            %
            % Hexagonal usage:
            %   [f, lat] = Lattice.createLattice(lattice="Hexagonal", a=..., nw=..., nh=..., ...
            %       seed=myFeature, a_parameter=a_param, layer="metal1");
            %
            % Honeycomb usage with two site types:
            %   [f, lat] = Lattice.createLattice(lattice="HoneyComb", a=..., nw=..., nh=..., ...
            %       seedA=featureA, seedB=featureB, sublattice="AB", ...
            %       a_parameter=a_param, layer="metal1");
            %
            % 'ctx' is optional: if omitted, context is inferred from seed feature(s).
            arguments
                args.lattice {mustBeTextScalar}
                args.a {mustBeNumeric, mustBeReal, mustBeFinite, mustBePositive}
                args.nw {mustBeInteger, mustBePositive}
                args.nh {mustBeInteger, mustBePositive}
                args.ctx core.GeometrySession = core.GeometrySession.empty
                args.seed = []
                args.seedA = []
                args.seedB = []
                args.seedCenters = []
                args.sublattice {mustBeTextScalar} = "AB"
                args.layer = []
                args.a_parameter = []
                args.offset = [0, 0]
            end

            lattice = lattices.Lattice.from_name(args.lattice, args.a, args.nw, args.nh);
            if isa(lattice, "lattices.HexagonalLattice")
                if isempty(args.seed)
                    error("Lattice.createLattice for Hexagonal lattice requires 'seed'.");
                end
                feature = lattice.latticeFromFeature(seed=args.seed, ctx=args.ctx, ...
                    layer=args.layer, a_parameter=args.a_parameter, offset=args.offset);
                return;
            end

            if isa(lattice, "lattices.HoneyCombLattice")
                if isempty(args.seed) && isempty(args.seedA) && isempty(args.seedB) && isempty(args.seedCenters)
                    error("Lattice.createLattice for HoneyComb lattice requires seed or seedA/seedB/seedCenters.");
                end
                feature = lattice.latticeFromFeature(ctx=args.ctx, seed=args.seed, ...
                    seedA=args.seedA, seedB=args.seedB, seedCenters=args.seedCenters, ...
                    sublattice=args.sublattice, layer=args.layer, ...
                    a_parameter=args.a_parameter);
                return;
            end

            error("Lattice.createLattice does not support class '%s'.", class(lattice));
        end

    end

    methods (Access=private, Static)
        function p = plotRS(nodes, lattice_name)
            arguments
                nodes
                lattice_name = "Lattice"
            end
            % Plot the lattice in real space
            nodes_x = nodes(:, :, 1);
            nodes_y = nodes(:, :, 2);
            p = plot(nodes_x(:), nodes_y(:), 'ro', 'DisplayName', lattice_name);
        end

        function out = flatten_nodes(nodes, as_grid)
            % Flatten nodes array from NxMx2 to (N*M)x2 unless grid is requested.
            if as_grid
                out = nodes;
                return;
            end
            nodes_x = nodes(:, :, 1);
            nodes_y = nodes(:, :, 2);
            out = [nodes_x(:), nodes_y(:)];
        end

        function out = extract_site_field(nodes_struct, field_name, as_grid)
            % Extract one field from a lattice site struct and flatten if needed.
            if ~isfield(nodes_struct, field_name)
                error("Missing field '%s' in lattice node struct.", char(field_name));
            end
            out = lattices.Lattice.flatten_nodes(nodes_struct.(field_name), as_grid);
        end

        function name = canonical_lattice_name(raw_name)
            % Normalize lattice naming variants to canonical method suffix.
            key = lower(string(raw_name));
            key = replace(key, " ", "");
            key = replace(key, "_", "");
            switch key
                case {"honeycomb", "honeycomblattice"}
                    name = "Honeycomb";
                case {"hexagonal", "hexagonallattice"}
                    name = "Hexagonal";
                otherwise
                    error("Unknown lattice name '%s'. Use 'Honeycomb' or 'Hexagonal'.", ...
                        char(string(raw_name)));
            end
        end
    end
end
