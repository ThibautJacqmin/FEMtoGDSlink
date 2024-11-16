classdef HoneyCombLattice < handle
    % Class to represent a honeycomb lattice truncated by a rectangle

    properties
        sublatticeA % Coordinates for sublattice A
        sublatticeB % Coordinates for sublattice B
        hexagon_centers % Coordinates of the hexagon centers
        lattice_constant % Lattice constant
    end

    methods
        function obj = HoneyCombLattice(a, n, m)
    % Constructor to initialize the honeycomb lattice
    % a: lattice constant
    % n: number of horizontal unit cells
    % m: number of vertical unit cells
    % center: 'A', 'B', or 'Hexagon' to set the origin at (0, 0)

    obj.lattice_constant = a; % Store lattice constant

    % Hexagonal lattice geometry
    deltaX = a;  % Horizontal distance between adjacent unit cells
    deltaY = a * sqrt(3) / 2; % Vertical distance between adjacent rows

    % Create grid indices for the lattice
    [i, j] = ndgrid(0:(n-1), 0:(m-1)); % Unit cell indices

    % Sublattice A
    sublatticeA_x = deltaX * i + mod(j, 2) * (a / 2); % Offset alternate rows
    sublatticeA_y = deltaY * j;

    % Sublattice B - Offset from Sublattice A
    sublatticeB_x = sublatticeA_x + a / 2; % Offset horizontally
    sublatticeB_y = sublatticeA_y + a / (2 * sqrt(3)); % Offset vertically

    % Hexagon centers
    hexagon_centers_x = sublatticeA_x; % Same x as sublattice A
    hexagon_centers_y = sublatticeA_y + a / sqrt(3); % Vertical offset

    % Store results
    obj.sublatticeA = cat(3, sublatticeA_x, sublatticeA_y);
    obj.sublatticeB = cat(3, sublatticeB_x, sublatticeB_y);
    obj.hexagon_centers = cat(3, hexagon_centers_x, hexagon_centers_y);
end

        function plotLattice(obj)
            % Plot the lattice in real space

            % Extract the coordinates for sublattices
            sublatticeA_x = obj.sublatticeA(:, :, 1);
            sublatticeA_y = obj.sublatticeA(:, :, 2);
            sublatticeB_x = obj.sublatticeB(:, :, 1);
            sublatticeB_y = obj.sublatticeB(:, :, 2);

            % Extract the coordinates for hexagon_centers
            hexagon_centers_x = obj.hexagon_centers(:, :, 1);
            hexagon_centers_y = obj.hexagon_centers(:, :, 2);

            % Create the plot
            figure;
            hold on;

            % Plot the two sublattices
            plot(sublatticeA_x(:), sublatticeA_y(:), 'ro', 'DisplayName', 'Sublattice A'); % Red circles
            plot(sublatticeB_x(:), sublatticeB_y(:), 'bo', 'DisplayName', 'Sublattice B'); % Blue circles

            % Plot the hexagon centers
            plot(hexagon_centers_x(:), hexagon_centers_y(:), 'kx', 'DisplayName', 'Hexagon Centers'); % Black crosses

            % Plot real-space lattice vectors
            a = obj.lattice_constant;
            a1 = a * [1, 0];
            a2 = a * ([1/2, sqrt(3)/2]);
            quiver(a, a/sqrt(3), a1(1), a1(2), 0, 'r', 'LineWidth', 1.5, 'DisplayName', 'a1');
            quiver(a, a/sqrt(3), a2(1), a2(2), 0, 'b', 'LineWidth', 1.5, 'DisplayName', 'a2');

            % Draw unit cell
            unit_cell_x = [0, a1(1), a1(1)+a2(1), a2(1), 0]+a;
            unit_cell_y = [0, a1(2), a1(2)+a2(2), a2(2), 0]+a/sqrt(3);
            plot(unit_cell_x, unit_cell_y, '--k', 'DisplayName', 'Unit Cell'); % Dashed black line

            % Add labels and legend
            xlabel('x');
            ylabel('y');
            title('Honeycomb lattice: real space');
            legend('Location', 'best');
            grid on;
            axis equal;
        end
        function [b1, b2, Gamma, M, K] = computeReciprocalLattice(obj)
            % Compute reciprocal lattice vectors and key symmetry points
            b = 2*pi/sqrt(3)/obj.lattice_constant;
            % Reciprocal lattice vectors
            b1 = b * [1, -sqrt(3)];  % Reciprocal lattice vector b1
            b2 = b * [1, sqrt(3)];   % Reciprocal lattice vector b2

            % Symmetry points
            Gamma = [0, 0];                     % Center of the Brillouin zone
            M = b.*[sqrt(3), 1]/2/(2/sqrt(3));  % Midpoint of horizontal edge
            K = b.*[1, 0];                      % Dirac point
        end

        function plotReciprocalLattice(obj)
            % Plot reciprocal lattice and symmetry points
            [b1, b2, Gamma, M, K] = obj.computeReciprocalLattice;

            % Define the hexagon vertices
            bz_vertices = [b1; b1+b2; b2; -b1; -b1-b2; -b2; b1]./2;

            figure;
            hold on;
            grid on;

            % Plot reciprocal lattice vectors
            quiver(0, 0, b1(1), b1(2), 0, 'r', 'LineWidth', 1.5, 'DisplayName', 'b1');
            quiver(0, 0, b2(1), b2(2), 0, 'b', 'LineWidth', 1.5, 'DisplayName', 'b2');

            % Plot hexagon
            plot(bz_vertices(:,1), bz_vertices(:,2), 'k-', 'LineWidth', 1.2, ...
                'HandleVisibility', 'off');

            % Plot symmetry points
            scatter([Gamma(1), M(1), K(1)], ...
                [Gamma(2), M(2), K(2)], 50, 'k', 'filled', ...
                'DisplayName', 'Symmetry Points');
            text(Gamma(1), Gamma(2), '\Gamma', 'VerticalAlignment', 'bottom');
            text(M(1), M(2), 'M', 'VerticalAlignment', 'top');
            text(K(1), K(2), 'K', 'VerticalAlignment', 'bottom');

            % Draw lines connecting Gamma, M, and K
            irreducible_BZ = [Gamma; M; K; Gamma]; % Coordinates of the triangle vertices
            plot(irreducible_BZ(:,1), irreducible_BZ(:,2), 'g-', 'LineWidth', 1.5, ...
                'DisplayName', 'Triangle (\Gamma, M, K)');

            % Fill the triangle formed by Gamma, M, and K
            fill(irreducible_BZ(:,1), irreducible_BZ(:,2), 'g', 'FaceAlpha', 0.2, ...
                'EdgeColor', 'none', 'HandleVisibility', 'off');

            % Label axes
            xlabel('k_x');
            ylabel('k_y');
            title('Honeycomb lattice: Reciprocal space');
            axis equal;

            % Adjust axes limits
            b = norm(b1);
            xlim([-b, b]); % Add padding
            ylim([-b, b]); % Add padding

            legend('Location', 'best');
            hold off;
        end



    end
end
