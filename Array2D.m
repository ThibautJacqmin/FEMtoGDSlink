classdef Array2D < GeomFeature
    % 2D array of one geometry feature from two displacement directions.
    properties (Dependent)
        target
        ncopies_x
        ncopies_y
        delta_x
        delta_y
    end
    methods
        function obj = Array2D(varargin)
            % Build a 2D array from a target feature and two lattice vectors.
            [ctx, target, args] = Array2D.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@GeomFeature(ctx, layer);
            obj.output = args.output;
            obj.add_input(target);
            obj.ncopies_x = args.ncopies_x;
            obj.ncopies_y = args.ncopies_y;
            obj.delta_x = args.delta_x;
            obj.delta_y = args.delta_y;
            obj.finalize();
        end

        function set.ncopies_x(obj, val)
            obj.set_param("ncopies_x", GeomFeature.coerce_parameter(val, "ncopies_x", unit=""));
        end

        function val = get.ncopies_x(obj)
            val = obj.get_param("ncopies_x");
        end

        function set.ncopies_y(obj, val)
            obj.set_param("ncopies_y", GeomFeature.coerce_parameter(val, "ncopies_y", unit=""));
        end

        function val = get.ncopies_y(obj)
            val = obj.get_param("ncopies_y");
        end

        function set.delta_x(obj, val)
            obj.set_param("delta_x", GeomFeature.coerce_vertices(val));
        end

        function val = get.delta_x(obj)
            val = obj.get_param("delta_x");
        end

        function set.delta_y(obj, val)
            obj.set_param("delta_y", GeomFeature.coerce_vertices(val));
        end

        function val = get.delta_y(obj)
            val = obj.get_param("delta_y");
        end

        function val = get.target(obj)
            val = obj.inputs{1};
        end
    end
    methods (Static, Access=private)
        function [ctx, target, args] = parse_inputs(varargin)
            if nargin < 1
                error("Array2D requires a target feature.");
            end
            if isa(varargin{1}, 'GeometrySession')
                ctx = varargin{1};
                if numel(varargin) < 2
                    error("Array2D requires a target feature.");
                end
                target = varargin{2};
                nv = varargin(3:end);
            else
                target = varargin{1};
                if isa(target, 'GeomFeature')
                    ctx = target.context();
                else
                    ctx = GeometrySession.require_current();
                end
                nv = varargin(2:end);
            end
            if ~isa(target, 'GeomFeature')
                error("Array2D target must be a GeomFeature.");
            end
            p = inputParser;
            p.addParameter('ncopies_x', 1);
            p.addParameter('ncopies_y', 1);
            p.addParameter('delta_x', [1, 0]);
            p.addParameter('delta_y', [0, 1]);
            p.addParameter('layer', []);
            p.addParameter('output', true);
            p.parse(nv{:});
            args = p.Results;
        end
    end
end
