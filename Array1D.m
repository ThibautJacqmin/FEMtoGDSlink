classdef Array1D < GeomFeature
    % Linear array of one geometry feature.
    properties (Dependent)
        target
        ncopies
        delta
    end
    methods
        function obj = Array1D(varargin)
            % Build a 1D array from a target feature and displacement vector.
            [ctx, target, args] = Array1D.parse_inputs(varargin{:});
            if isempty(args.layer)
                layer = target.layer;
            else
                layer = args.layer;
            end
            obj@GeomFeature(ctx, layer);
            obj.output = args.output;
            obj.add_input(target);
            obj.ncopies = args.ncopies;
            obj.delta = args.delta;
            obj.finalize();
        end

        function set.ncopies(obj, val)
            obj.set_param("ncopies", GeomFeature.coerce_parameter(val, "ncopies", unit=""));
        end

        function val = get.ncopies(obj)
            val = obj.get_param("ncopies");
        end

        function set.delta(obj, val)
            obj.set_param("delta", GeomFeature.coerce_vertices(val));
        end

        function val = get.delta(obj)
            val = obj.get_param("delta");
        end

        function val = get.target(obj)
            val = obj.inputs{1};
        end
    end
    methods (Static, Access=private)
        function [ctx, target, args] = parse_inputs(varargin)
            if nargin < 1
                error("Array1D requires a target feature.");
            end
            if isa(varargin{1}, 'GeometrySession')
                ctx = varargin{1};
                if numel(varargin) < 2
                    error("Array1D requires a target feature.");
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
                error("Array1D target must be a GeomFeature.");
            end
            p = inputParser;
            p.addParameter('ncopies', 1);
            p.addParameter('delta', [1, 0]);
            p.addParameter('layer', []);
            p.addParameter('output', true);
            p.parse(nv{:});
            args = p.Results;
        end
    end
end
