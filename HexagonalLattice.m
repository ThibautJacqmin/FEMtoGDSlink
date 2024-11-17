classdef HexagonalLattice < handle
    % Class to represent a hexagonal (triangular) lattice with rectangular bounding box

    properties
        lattice_points % Coordinates of the lattice points
        a % lattice constant
        a1 % Real space base vector 1
        a2 % Real space base vector 2
        b % Reciprocal lattice constant
        b1 % Reciprocal space base vector 1
        b2 % Reciprocal space base vector 2
        nw % Number of unit cells along the width
        nh % Number of unit cells along the height
        Gamma % Coordinates of Gamma symmetry point in reciprocal space
        M     % Coordinates of M symmetry point in reciprocal space
        K     % Coordinates of K symmetry point in reciprocal space
        irreducibleBZ % Vertices of irreducible Brillouin Zone
    end

    methods
        function obj = HexagonalLattice(a, nw, nh)
            % Constructor to initialize the hexagonal lattice
            % a: lattice constant
            % nw: number of unit cells in the width
            % nh: number of unit cells in the height
            arguments
                a double
                nw {mustBeInteger}
                nh {mustBeInteger}
            end

            obj.a = a;
            obj.nw = nw;
            obj.nh = nh;

            % Compute lattice points
            obj.computeLatticeGeometry;

            % Set default symmetry point
            obj.Gamma = [0, 0];
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
        function y = get.irreducibleBZ(obj)
            % Coordinates of the corners of the irreducible BZ
            y = [obj.Gamma; obj.M; obj.K; obj.Gamma];
        end

        function computeLatticeGeometry(obj)
            % Compute the lattice points of the hexagonal lattice to fill a rectangle

            % Create a rectangular grid
            [i, j] = ndgrid(0:(obj.nw - 1), 0:(obj.nh - 1));

            % Apply zig-zag alignment for alternating rows
            lattice_x = obj.a1(1) * i + mod(j, 2) * (obj.a / 2);
            lattice_y = obj.a2(2) * j;

            % Center the structure around (0, 0)
            lattice_x = lattice_x - mean(lattice_x(:));
            lattice_y = lattice_y - mean(lattice_y(:));

            % Store results
            obj.lattice_points = cat(3, lattice_x, lattice_y);
        end

        function y = get.M(obj)
            % Coordinates of M symmetry point
            y = obj.b.*[sqrt(3), 1]/2/(2/sqrt(3))/2;
        end
        function y = get.K(obj)
            % oordinate of Dirac point symmetry point
            y = obj.b.*[1, 0]/2;
        end

        function plotLattice(obj)
            % Plot the lattice in real space

            % Extract lattice points
            lattice_x = obj.lattice_points(:, :, 1);
            lattice_y = obj.lattice_points(:, :, 2);

            % Create the plot
            figure;
            hold on;

            % Plot the lattice points
            plot(lattice_x(:), lattice_y(:), 'ro', 'DisplayName', 'Lattice Points'); % Red circles

            % Plot real-space lattice vectors
            quiver(0, 0, obj.a1(1), obj.a1(2), 0, 'r', 'LineWidth', 1.5, 'DisplayName', 'a1');
            quiver(0, 0, obj.a2(1), obj.a2(2), 0, 'b', 'LineWidth', 1.5, 'DisplayName', 'a2');

            % Draw unit cell
            unit_cell_x = [0, obj.a1(1), obj.a1(1) + obj.a2(1), obj.a2(1), 0];
            unit_cell_y = [0, obj.a1(2), obj.a1(2) + obj.a2(2), obj.a2(2), 0];
            plot(unit_cell_x, unit_cell_y, '--k', 'DisplayName', 'Unit Cell'); % Dashed black line

            % Add labels and legend
            xlabel('x');
            ylabel('y');
            title('Hexagonal lattice: real space');
            legend('Location', 'best');
            grid on;
            axis equal;
        end

        function plotReciprocalLattice(obj)
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
            fill(obj.irreducibleBZ(:,1), obj.irreducibleBZ(:,2), 'g', 'FaceAlpha', 0.2, ...
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
end
