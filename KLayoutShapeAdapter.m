classdef KLayoutShapeAdapter < handle
    % Adapter encapsulating KLayout specific operations for geometry
    % primitives. By funnelling all Python interactions through this
    % helper, shape classes can remain mostly backend agnostic in their
    % logic while still benefiting from the rich KLayout API.
    properties (SetAccess = private)
        pya
        shape
    end

    methods
        function obj = KLayoutShapeAdapter(pyaModule)
            if nargin < 1
                pyaModule = [];
            end
            obj.pya = pyaModule;
        end

        function flag = isActive(obj)
            flag = ~isempty(obj.pya);
        end

        function adoptShape(obj, shapeHandle)
            if obj.isActive()
                obj.shape = shapeHandle;
            end
        end

        function newAdapter = spawn(obj, shapeHandle)
            if nargin < 2
                shapeHandle = [];
            end
            newAdapter = KLayoutShapeAdapter(obj.pya);
            if ~isempty(shapeHandle)
                newAdapter.adoptShape(shapeHandle);
            elseif obj.canOperate()
                newAdapter.adoptShape(obj.shape);
            end
        end

        function module = getPya(obj)
            module = obj.pya;
        end

        function initializePolygon(obj, vertices)
            if ~obj.isActive() || isempty(vertices)
                return;
            end
            obj.shape = obj.pya.Polygon.from_s(vertices.klayout_string);
        end

        function initializeRectangleFromBounds(obj, left, right, bottom, top)
            if ~obj.isActive()
                return;
            end
            rect = obj.pya.Box(left, bottom, right, top);
            obj.shape = obj.pya.Polygon(rect);
        end

        function move(obj, vector)
            if ~obj.canOperate()
                return;
            end
            obj.shape.move(vector.value(1), vector.value(2));
        end

        function rotate(obj, angle, reference_point)
            if nargin < 3
                reference_point = [0, 0];
            end
            if ~obj.canOperate()
                return;
            end
            obj.shape.move(-reference_point(1), -reference_point(2));
            rotation = obj.pya.CplxTrans(1, angle.value, py.bool(0), 0, 0);
            obj.shape.transform(rotation);
            obj.shape.move(reference_point(1), reference_point(2));
        end

        function scale(obj, scaling_factor)
            if ~obj.canOperate()
                return;
            end
            scaling = obj.pya.CplxTrans(scaling_factor.value);
            obj.shape.transform(scaling);
        end

        function mirrorHorizontal(obj, axis)
            if ~obj.canOperate()
                return;
            end
            obj.shape.move(-axis.value, 0);
            mirrorX = obj.pya.Trans.M90;
            obj.shape.transform(mirrorX);
            obj.shape.move(axis.value, 0);
        end

        function mirrorVertical(obj, axis)
            if ~obj.canOperate()
                return;
            end
            obj.shape.move(0, -axis.value);
            mirrorY = obj.pya.Trans.M0;
            obj.shape.transform(mirrorY);
            obj.shape.move(0, axis.value);
        end

        function adapterCopy = copy(obj)
            adapterCopy = KLayoutShapeAdapter(obj.pya);
            if ~obj.canOperate()
                return;
            end
            adapterCopy.adoptShape(obj.duplicateShape());
        end

        function replaceShape(obj, newShape)
            if ~obj.isActive()
                return;
            end
            obj.shape = newShape;
        end
    end

    methods (Access = private)
        function flag = canOperate(obj)
            flag = obj.isActive() && ~isempty(obj.shape);
        end

        function duplicate = duplicateShape(obj)
            if isa(obj.shape, 'py.klayout.dbcore.Region')
                duplicate = obj.pya.Region();
                duplicate.insert(obj.shape);
                duplicate.flatten;
                duplicate.merge;
            else
                duplicate = obj.pya.Polygon.from_s(obj.shape.to_s);
            end
        end
    end
end
