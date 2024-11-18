classdef HoneyCombLattice < Lattice
    % Class to represent a honeycomb lattice with rectangle bounding box
    % The number of horizontal and vertical unit cells is fixed
    properties
        hexagonal_lattice % base hexagonal lattice
        M     % coordinates of M symmetry point in reciprocal space
        K     % coordinates of K (Dirac) symmetry point in reciprocal space
    end
    methods
        function obj = HoneyCombLattice(a, nw, nh)
            % Constructor to initialize the honeycomb lattice
            % a: lattice constant
            % nw: number of unit cells in the width
            % nh: number of unit cells in the height
            
            % Call parent class constructor
            obj = obj@Lattice(a, nw, nh);
            % Create a hexagonal lattice
            obj.hexagonal_lattice = HexagonalLattice(obj.a, obj.nw, obj.nh);
            % Compute nodes coordinates
            obj.nodes = obj.computeGeometry("HoneyComb");
        end
        function lattice_nodes = computeHoneyCombGeometry(obj)
            % Create the structure for sublattices
            lattice_nodes = struct();
            % Store site A of HoneyCombLattice in structure
            lattice_nodes.sublatticeA = obj.hexagonal_lattice.nodes;
            % Generate and store site B from site A
            sublatticeB(:, :, 1) = lattice_nodes.sublatticeA(:, :, 1) + obj.a / 2;
            sublatticeB(:, :, 2) = lattice_nodes.sublatticeA(:, :, 2) + obj.a/2/sqrt(3);
            lattice_nodes.sublatticeB = sublatticeB;
            % Generate hexagonal lattice of center of honeycomb hexagons
            % and store as a sublattice (convenient, no physics here)
            hexagon_centers(:, :, 1) = lattice_nodes.sublatticeA(:, :, 1);
            hexagon_centers(:, :, 2) = lattice_nodes.sublatticeA(:, :, 2) + obj.a / sqrt(3);
            lattice_nodes.hexagon_centers = hexagon_centers;
        end
        function y = get.M(obj)
            y = obj.hexagonal_lattice.M;
        end
        function y = get.K(obj)
            y = obj.hexagonal_lattice.K;
        end
    end
end
