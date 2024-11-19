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
                a double   % a: lattice constant
                nw {mustBeInteger}  % nw: number of unit cells in the width
                nh {mustBeInteger}   % nh: number of unit cells in the height
            end
            obj.a = a; obj.nw = nw; obj.nh = nh;
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
            y = obj.b*[1/2, sqrt(3)/2];
        end
        function y = get.irreducibleBrillouinZoneContour(obj)
            % Coordinates of the corners of the irreducible BZ
            y = [obj.Gamma; obj.M; obj.K; obj.Gamma];
        end
        function c = get.unitCellContour(obj)
            x = [0, obj.a1(1), obj.a1(1) + obj.a2(1), obj.a2(1), 0];
            y = [0, obj.a1(2), obj.a1(2) + obj.a2(2), obj.a2(2), 0];
            c = [x;y]';
        end
        function lattice_nodes = computeGeometry(obj, name)
            arguments
                obj
                name {mustBeMember(name, ["HoneyComb", "Hexagonal"])}
            end
            lattice_nodes = obj.("compute"+name+"Geometry");
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
                for sublattice=string(fieldnames(obj.nodes))'
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
            f = figure;
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
    methods (Access=private, Static)
        function p = plotRS(nodes, lattice_name)
            arguments
                nodes
                lattice_name = "Lattice"
            end
            % Plot the lattice in real space
            % Extract lattice points
            nodes_x = nodes(:, :, 1);
            nodes_y = nodes(:, :, 2);
            % Plot the lattice points
            p = plot(nodes_x(:), nodes_y(:), 'ro', 'DisplayName', lattice_name);
        end
    end

end