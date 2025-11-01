classdef ComsolShapeAdapter < handle
    % Adapter responsible for applying operations on COMSOL geometry
    % features. It centralizes all the backend specific logic so that
    % geometry primitives can remain mostly backend agnostic.
    properties (SetAccess = private)
        modeler ComsolModeler
        shape
    end

    methods
        function obj = ComsolShapeAdapter(modeler)
            if nargin < 1
                modeler = ComsolModeler.empty;
            end
            obj.modeler = modeler;
        end

        function flag = isActive(obj)
            flag = ~isempty(obj.modeler);
        end

        function adoptShape(obj, shapeHandle)
            if obj.isActive()
                obj.shape = shapeHandle;
            end
        end

        function newAdapter = spawn(obj)
            % Create a lightweight adapter that references the current
            % shape. This is useful when we want to start a new COMSOL
            % feature based on an existing shape without mutating it.
            newAdapter = ComsolShapeAdapter(obj.modeler);
            if obj.isActive()
                newAdapter.adoptShape(obj.shape);
            end
        end

        function modeler = getModeler(obj)
            modeler = obj.modeler;
        end

        function initializePolygon(obj, vertices)
            if ~obj.isActive() || isempty(vertices)
                return;
            end
            polygon = obj.modeler.create_comsol_object("Polygon");
            polygon.set('x', vertices.comsol_string_x);
            polygon.set('y', vertices.comsol_string_y);
            obj.shape = polygon;
        end

        function initializeRectangleFromBounds(obj, left, right, bottom, top)
            if ~obj.isActive()
                return;
            end
            rectangle = obj.modeler.create_comsol_object("Rectangle");
            rectangle.set('base', 'corner');
            rectangle.set('x', left);
            rectangle.set('y', bottom);
            rectangle.set('size', [abs(right - left), abs(top - bottom)]);
            obj.shape = rectangle;
        end

        function move(obj, vector)
            if ~obj.canOperate()
                return;
            end
            obj.applyTransform("Move", struct( ...
                'displx', vector.value(1), ...
                'disply', vector.value(2)));
        end

        function rotate(obj, angle, reference_point)
            if ~obj.canOperate()
                return;
            end
            obj.applyTransform("Rotate", struct( ...
                'rot', angle, ...
                'pos', reference_point));
        end

        function scale(obj, scaling_factor)
            if ~obj.canOperate()
                return;
            end
            obj.applyTransform("Scale", struct('factor', scaling_factor));
        end

        function mirrorHorizontal(obj, axis)
            if ~obj.canOperate()
                return;
            end
            position = {axis, 0};
            obj.applyTransform("Mirror", struct( ...
                'pos', position, ...
                'axis', [1, 0]));
        end

        function mirrorVertical(obj, axis)
            if ~obj.canOperate()
                return;
            end
            position = {0, axis};
            obj.applyTransform("Mirror", struct( ...
                'pos', position, ...
                'axis', [0, 1]));
        end

        function fillet(obj, fillet_radius, vertices_indices)
            if ~obj.canOperate()
                return;
            end
            obj.applyTransform("Fillet", struct('radius', fillet_radius), ...
                'point', {vertices_indices});
        end

        function linearArray(obj, ncopies, vertex)
            if ~obj.canOperate()
                return;
            end
            obj.shape = obj.modeler.make_1D_array(ncopies, vertex, obj.shape);
        end

        function finalizeArray(obj)
            if ~obj.canOperate()
                return;
            end
            union_shape = obj.modeler.create_comsol_object("Union");
            union_shape.selection('input').set(obj.tag());
            obj.shape = union_shape;
        end

        function difference(obj, other)
            if ~obj.canOperate()
                return;
            end
            otherTags = obj.collectTags(other);
            if isempty(otherTags)
                return;
            end
            new_shape = obj.modeler.create_comsol_object("Difference");
            new_shape.selection('input').set(obj.tag());
            new_shape.selection('input2').set(otherTags);
            obj.shape = new_shape;
        end

        function unite(obj, other)
            if ~obj.canOperate()
                return;
            end
            otherTags = obj.collectTags(other);
            if isempty(otherTags)
                return;
            end
            tags = [obj.tag(); otherTags];
            union_shape = obj.modeler.create_comsol_object("Union");
            union_shape.selection('input').set(tags);
            obj.shape = union_shape;
        end

        function intersect(obj, other)
            if ~obj.canOperate()
                return;
            end
            otherTags = obj.collectTags(other);
            if isempty(otherTags)
                return;
            end
            tags = [obj.tag(); otherTags];
            intersection_shape = obj.modeler.create_comsol_object("Intersection");
            intersection_shape.selection('input').set(tags);
            obj.shape = intersection_shape;
        end

        function copyAdapter = copy(obj, args)
            arguments
                obj
                args.keep logical = true
            end
            copyAdapter = ComsolShapeAdapter(obj.modeler);
            if ~obj.canOperate()
                return;
            end
            copy_shape = obj.modeler.create_comsol_object("Copy");
            copy_shape.selection('input').set(obj.tag());
            if ~args.keep
                copy_shape.set('keep', false);
            end
            copyAdapter.adoptShape(copy_shape);
        end

        function copyPositions(obj, args)
            arguments
                obj
                args.vertex_to_copy
                args.new_positions Vertices
            end
            if ~obj.canOperate()
                return;
            end
            copy_shape = obj.modeler.create_comsol_object("Copy");
            copy_shape.set('keep', false);
            copy_shape.selection('input').set(obj.tag());
            copy_shape.set("specify", "pos");
            copy_shape.set("oldpos", "coord");
            copy_shape.set("newpos", "coord");
            copy_shape.set("oldposcoord", obj.convertValue(args.vertex_to_copy));
            copy_shape.set("newposx", obj.convertValue(args.new_positions.xvalue));
            copy_shape.set("newposy", obj.convertValue(args.new_positions.yvalue));
            obj.shape = copy_shape;
        end

        function name = tag(obj)
            if isempty(obj.shape)
                name = "";
            else
                name = string(obj.shape.tag);
            end
        end
    end

    methods (Access = private)
        function flag = canOperate(obj)
            flag = obj.isActive() && ~isempty(obj.shape);
        end

        function applyTransform(obj, operation, params, selectionType, extraArgs)
            if nargin < 4 || isempty(selectionType)
                selectionType = 'input';
            end
            if nargin < 5
                extraArgs = {};
            end
            previous = obj.tag();
            new_shape = obj.modeler.create_comsol_object(operation);
            if nargin >= 3 && ~isempty(params)
                fields = fieldnames(params);
                for iField = 1:numel(fields)
                    fieldName = fields{iField};
                    new_shape.set(fieldName, obj.convertValue(params.(fieldName)));
                end
            end
            selection_args = [{previous}, extraArgs];
            selection_args = obj.convertCell(selection_args);
            new_shape.selection(selectionType).set(selection_args{:});
            obj.shape = new_shape;
        end

        function value = convertValue(obj, input)
            if isa(input, 'Parameter') || isa(input, 'Variable') || isa(input, 'DependentParameter')
                value = char(input.name);
            elseif isa(input, 'Vertices')
                value = input.comsol_string;
            elseif iscell(input)
                value = cellfun(@(item) obj.convertValue(item), input, 'UniformOutput', false);
            elseif isstring(input)
                value = char(input);
            elseif isnumeric(input) || islogical(input)
                value = input;
            elseif ischar(input)
                value = input;
            else
                error('Unsupported COMSOL value type: %s', class(input));
            end
        end

        function values = convertCell(obj, items)
            values = cellfun(@(item) obj.convertValue(item), items, 'UniformOutput', false);
        end

        function tags = collectTags(obj, other)
            if isa(other, 'ComsolShapeAdapter')
                tags = obj.tagFromAdapter(other);
            elseif isa(other, 'Polygon')
                tags = obj.tagFromAdapter(other.comsol_adapter);
            elseif iscell(other)
                collected = cellfun(@(item) obj.collectTags(item), other, 'UniformOutput', false);
                tags = vertcat(collected{:});
            elseif isstring(other) || ischar(other)
                tags = string(other);
            else
                tags = string(other.tag);
            end
        end

        function tagValue = tagFromAdapter(~, adapter)
            if isempty(adapter) || isempty(adapter.shape)
                tagValue = string.empty(0, 1);
            else
                tagValue = string(adapter.shape.tag);
            end
        end
    end
end
