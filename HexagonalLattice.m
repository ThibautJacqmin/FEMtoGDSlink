classdef HexagonalLattice < Lattice
    % Class to represent a hexagonal (triangular) lattice with rectangular bounding box

    properties
        M     % coordinates of M symmetry point in reciprocal space
        K     % coordinates of K (Dirac) symmetry point in reciprocal space
    end

    methods
        function obj = HexagonalLattice(a, nw, nh)
            % Constructor to initialize the hexagonal lattice
            % a: lattice constant
            % nw: number of unit cells in the width
            % nh: number of unit cells in the height
            
            % Call parent class constructor
            obj = obj@Lattice(a, nw, nh);
            % Compute nodes coordinates
            obj.nodes = obj.computeGeometry("Hexagonal");
        end        
        function y = get.M(obj)
            % Coordinates of M symmetry point
            y = obj.b.*[sqrt(3), 1]/2/(2/sqrt(3))/2;
        end
        function y = get.K(obj)
            % Coordinates of Dirac symmetry point
            y = obj.b.*[1, 0]/2;
        end
        function lattice_nodes = computeHexagonalGeometry(obj)
            % Compute the nodes coordinates
            % Hexagonal lattice bounded by a rectangle
            % nw : number of unit cells in the width
            % nh : number of unit cell in the height

            % Create a rectangular grid
            [i, j] = ndgrid(0:obj.nw, 0:obj.nh);
            center_x = floor(obj.nw/2);
            center_y = floor(obj.nh/2);
            % Apply zig-zag alignment for alternating rows
            nodes_x = obj.a1(1) * (i-center_x) + mod(j-center_y, 2) * (obj.a / 2);
            nodes_y = obj.a2(2) * (j-center_y);
    
            % Store results
            lattice_nodes = cat(3, nodes_x, nodes_y);
        end
    end
end
