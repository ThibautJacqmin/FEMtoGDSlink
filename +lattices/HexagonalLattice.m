classdef HexagonalLattice < lattices.Lattice
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
            obj = obj@lattices.Lattice(a, nw, nh);
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

        function feature = latticeFromFeature(obj, args)
            % Replicate one seed feature at each hexagonal lattice site using Array features.
            arguments
                obj
                args.seed core.GeomFeature
                args.ctx core.GeometrySession = core.GeometrySession.empty
                args.layer = []
                args.a_parameter = []
                args.offset = [0, 0] % coefficient in units of lattice constant
            end

            [ctx, layer] = obj.resolve_context_and_layer(args.seed, args.ctx, args.layer);
            a_param = obj.coerce_lattice_parameter(args.a_parameter);
            offset = obj.validate_offset(args.offset);
            nx = obj.nw + 1;
            delta_x = types.Vertices([1, 0], a_param);
            delta_y = types.Vertices([0, sqrt(3)], a_param);

            arrays = {};
            families = obj.row_family_specs();
            for i = 1:numel(families)
                fam = families(i);
                shift = [fam.x_coeff0 + offset(1), fam.y_coeff0 + offset(2)];
                arr = ops.Array2D(ctx, args.seed, ...
                    ncopies_x=nx, ncopies_y=fam.ny, ...
                    delta_x=delta_x, delta_y=delta_y, ...
                    layer=layer);
                if any(abs(shift) > 1e-12)
                    arr = ops.Move(ctx, arr, ...
                        delta=types.Vertices(shift, a_param), layer=layer);
                end
                arrays{end+1} = arr; %#ok<AGROW>
            end

            if isempty(arrays)
                error("HexagonalLattice has no rows to emit.");
            elseif isscalar(arrays)
                feature = arrays{1};
            else
                feature = ops.Union(ctx, arrays, layer=layer);
            end
        end

    end
    methods (Access=private)
        function p = coerce_lattice_parameter(obj, a_input)
            if isempty(a_input)
                p = types.Parameter(obj.a, "", auto_register=false);
            elseif isa(a_input, "types.Parameter")
                p = a_input;
            else
                p = types.Parameter(a_input, "", auto_register=false);
            end
            if ~(isscalar(p.value) && isfinite(p.value) && p.value > 0)
                error("HexagonalLattice lattice parameter must be a finite scalar > 0.");
            end
        end

        function off = validate_offset(~, offset)
            if ~(isnumeric(offset) && isequal(size(offset), [1, 2]))
                error("HexagonalLattice offset must be a numeric [x y] coefficient pair.");
            end
            off = double(offset);
        end

        function [ctx, layer] = resolve_context_and_layer(~, seed, ctx_in, layer_in)
            if isempty(ctx_in)
                ctx = seed.context();
            else
                ctx = ctx_in;
            end

            if isempty(ctx)
                error("HexagonalLattice arrayFromFeature requires a valid GeometrySession context.");
            end
            if ~isequal(seed.context(), ctx)
                error("HexagonalLattice seed feature context must match provided ctx.");
            end

            if isempty(layer_in)
                layer = seed.layer;
            else
                layer = layer_in;
            end
        end

        function families = row_family_specs(obj)
            % Build two row families that reproduce computeHexagonalGeometry indexing.
            center_x = floor(obj.nw / 2);
            center_y = floor(obj.nh / 2);
            dy_coeff = sqrt(3) / 2;

            families = struct('x_coeff0', {}, 'y_coeff0', {}, 'ny', {});
            for parity = 0:1
                k_min = ceil((0 - center_y - parity) / 2);
                k_max = floor((obj.nh - center_y - parity) / 2);
                ny = k_max - k_min + 1;
                if ny < 1
                    continue;
                end

                fam = struct();
                fam.x_coeff0 = -center_x + 0.5 * parity;
                fam.y_coeff0 = (parity + 2 * k_min) * dy_coeff;
                fam.ny = ny;
                families(end+1) = fam; %#ok<AGROW>
            end
        end
    end
end
