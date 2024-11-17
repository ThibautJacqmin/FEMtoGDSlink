classdef HoneyCombLattice < handle
    % Class to represent a honeycomb lattice with rectangle bounding box
    % The number of horizontal and vertical unit cells is fixed
    properties
        sublatticeA % Coordinates for sublattice A
        sublatticeB % Coordinates for sublattice B
        hexagon_centers % Coordinates of the hexagon centers
        a % lattice constant
        a1 % real space base vector 1
        a2 % real space base vector 2
        b % Lattice constant
        b1 % real space base vector 1
        b2 % real space base vector 2
        nw % number of unit cells in the width of the square structure
        nh % number of unit cells in the height of the square structure
        Gamma % coordinates of Gamma symmetry point in reciprocal space
        M     % coordinates of M symmetry point in reciprocal space
        K     % coordinates of K (Dirac) symmetry point in reciprocal space
        irreducibleBZ % Vertices of irreducible Brillouin Zone
    end

    methods
        function obj = HoneyCombLattice(a, nw, nh)
            % Constructor to initialize the honeycomb lattice
            % a: lattice constant
            % n: number of horizontal unit cells
            % m: number of vertical unit cells
            % center: 'A', 'B', or 'Hexagon' to set the origin at (0, 0)
            arguments
                a double
                nw {mustBeInteger}
                nh {mustBeInteger}
            end

            obj.a = a; obj.nw = nw; obj.nh = nh;
            obj.computeLatticeGeometry;
            obj.Gamma = [0, 0];
        end
        function y = get.a1(obj)
            % Real space base vector a1
            y = obj.a*[1, 0];
        end
        function y = get.a2(obj)
            % Real space base vector a2
            y = obj.a*[1/2, sqrt(3)/2];
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
        function computeLatticeGeometry(obj)
            % Create grid indices for the lattice
            [i, j] = ndgrid(0:(obj.nw-1), 0:(obj.nh-1)); % Unit cell indices

            % Sublattice A
            sublatticeA_x = obj.a1(1) * i + mod(j, 2) * (obj.a / 2); % Offset alternate rows
            sublatticeA_y = obj.a2(2) * j;

            % Sublattice B - Offset from Sublattice A
            sublatticeB_x = sublatticeA_x + obj.a / 2; % Offset horizontally
            sublatticeB_y = sublatticeA_y + obj.a / (2 * sqrt(3)); % Offset vertically

            % Hexagon centers
            hexagon_centers_x = sublatticeA_x; % Same x as sublattice A
            hexagon_centers_y = sublatticeA_y + obj.a / sqrt(3); % Vertical offset

            % Store results
            obj.sublatticeA = cat(3, sublatticeA_x, sublatticeA_y);
            obj.sublatticeB = cat(3, sublatticeB_x, sublatticeB_y);
            obj.hexagon_centers = cat(3, hexagon_centers_x, hexagon_centers_y);
        end
        function y = get.M(obj)
            % Coordinates of M symmetry point
            y = obj.b.*[sqrt(3), 1]/2/(2/sqrt(3))/2;  
        end
        function y = get.K(obj)    
            % oordinate of Dirac point symmetry point
            y = obj.b.*[1, 0]/2;                     
        end
        function y = get.irreducibleBZ(obj)
            % Coordinates of the corners of the irreducible BZ
            y = [obj.Gamma; obj.M; obj.K; obj.Gamma]; 
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
            quiver(obj.a, obj.a/sqrt(3), obj.a1(1), obj.a1(2), 0, 'r', 'LineWidth', 1.5, 'DisplayName', 'a1');
            quiver(obj.a, obj.a/sqrt(3), obj.a2(1), obj.a2(2), 0, 'b', 'LineWidth', 1.5, 'DisplayName', 'a2');

            % Draw unit cell
            unit_cell_x = [0, obj.a1(1), obj.a1(1)+obj.a2(1), obj.a2(1), 0]+obj.a;
            unit_cell_y = [0, obj.a1(2), obj.a1(2)+obj.a2(2), obj.a2(2), 0]+obj.a/sqrt(3);
            plot(unit_cell_x, unit_cell_y, '--k', 'DisplayName', 'Unit Cell'); % Dashed black line

            % Add labels and legend
            xlabel('x');
            ylabel('y');
            title('Honeycomb lattice: real space');
            legend('Location', 'best');
            grid on;
            axis equal;
        end
        function plotReciprocalLattice(obj)
            % Define the hexagon vertices
            bz_vertices = [obj.b1; obj.b1+obj.b2; obj.b2; -obj.b1; -obj.b1-obj.b2; -obj.b2; obj.b1]./2;

            figure;
            hold on;
            grid on;

            % Plot reciprocal lattice vectors
            quiver(0, 0, obj.b1(1), obj.b1(2), 0, 'r', 'LineWidth', 1.5, 'DisplayName', 'b1');
            quiver(0, 0, obj.b2(1), obj.b2(2), 0, 'b', 'LineWidth', 1.5, 'DisplayName', 'b2');

            % Plot hexagon
            plot(bz_vertices(:,1), bz_vertices(:,2), 'k-', 'LineWidth', 1.2, ...
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
            title('Honeycomb lattice: Reciprocal space');
            axis equal;

            % Adjust axes limits
            xlim([-obj.b, obj.b]); % Add padding
            ylim([-obj.b, obj.b]); % Add padding

            legend('Location', 'best');
            hold off;
        end
    end
end
