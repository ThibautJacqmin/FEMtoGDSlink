classdef Intersection < GeomFeature
    % Intersection boolean operation on multiple features.
    properties (Dependent)
        members
    end
    methods
        function obj = Intersection(varargin)
            [ctx, members, args] = Intersection.parse_inputs(varargin{:});
            members = Intersection.normalize_inputs(members);
            if isempty(args.layer) && ~isempty(members)
                layer = members{1}.layer;
            else
                layer = args.layer;
            end
            obj@GeomFeature(ctx, layer);
            obj.output = args.output;
            for i = 1:numel(members)
                obj.add_input(members{i});
            end
        end

        function val = get.members(obj)
            val = obj.inputs;
        end
    end
    methods (Static, Access=private)
        function [ctx, members, args] = parse_inputs(varargin)
            if nargin < 1
                error("Intersection requires member features.");
            end
            if isa(varargin{1}, 'GeometrySession')
                ctx = varargin{1};
                if numel(varargin) < 2
                    error("Intersection requires member features.");
                end
                members = varargin{2};
                nv = varargin(3:end);
            else
                members = varargin{1};
                members_norm = Intersection.normalize_inputs(members);
                if ~isempty(members_norm) && isa(members_norm{1}, 'GeomFeature')
                    ctx = members_norm{1}.context();
                else
                    ctx = GeometrySession.require_current();
                end
                nv = varargin(2:end);
            end
            p = inputParser;
            p.addParameter('layer', []);
            p.addParameter('output', true);
            p.parse(nv{:});
            args = p.Results;
        end

        function inputs = normalize_inputs(members)
            if iscell(members)
                inputs = members;
            else
                inputs = num2cell(members);
            end
        end
    end
end
