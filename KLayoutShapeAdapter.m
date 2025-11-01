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

        function arrayAdapter = make1DArray(obj, ownerPolygon, ncopies, displacement, gds_modeler, layer)
            arguments
                obj
                ownerPolygon Polygon
                ncopies {mustBeA(ncopies, {'Variable', 'Parameter', 'DependentParameter'})}
                displacement Vertices
                gds_modeler
                layer
            end
            if ~obj.canOperate() || isempty(gds_modeler) || displacement.nvertices < 1
                arrayAdapter = [];
                return;
            end
            intermediate_cell = gds_modeler.pylayout.create_cell('intermediate_cell');
            gds_modeler.add_to_layer(layer, ownerPolygon, intermediate_cell);
            transformation = obj.pya.Trans(obj.pya.Point(0, 0));
            cell_instance = obj.pya.CellInstArray(intermediate_cell.cell_index(), transformation, ...
                obj.pya.Vector(displacement.value(1), displacement.value(2)), obj.pya.Vector(0, 1), ncopies.value, 1);
            gds_modeler.pycell.insert(cell_instance);
            gds_modeler.pycell.flatten(-1);
            region = obj.captureLayerRegion(gds_modeler, layer);
            arrayAdapter = obj.spawn(region);
        end

        function arrayAdapter = make2DArray(obj, ownerPolygon, ncopies_x, ncopies_y, spacing, gds_modeler, layer)
            arguments
                obj
                ownerPolygon Polygon
                ncopies_x {mustBeA(ncopies_x, {'Variable', 'Parameter', 'DependentParameter'})}
                ncopies_y {mustBeA(ncopies_y, {'Variable', 'Parameter', 'DependentParameter'})}
                spacing Vertices
                gds_modeler
                layer
            end
            if ~obj.canOperate() || isempty(gds_modeler) || spacing.nvertices < 2
                arrayAdapter = [];
                return;
            end
            intermediate_cell_1 = gds_modeler.pylayout.create_cell('intermediate_cell_1');
            gds_modeler.add_to_layer(layer, ownerPolygon, intermediate_cell_1);
            transformation = obj.pya.Trans(obj.pya.Point(0, 0));
            first_step = spacing.value(1, :);
            array_1 = obj.pya.CellInstArray(intermediate_cell_1.cell_index(), transformation, ...
                obj.pya.Vector(first_step(1), first_step(2)), obj.pya.Vector(0, 1), ncopies_x.value, 1);
            gds_modeler.pycell.insert(array_1);
            intermediate_cell_2 = gds_modeler.pylayout.create_cell('intermediate_cell_2');
            intermediate_cell_2.insert(array_1);
            second_step = spacing.value(2, :);
            array_2 = obj.pya.CellInstArray(intermediate_cell_2.cell_index(), transformation, ...
                obj.pya.Vector(second_step(1), second_step(2)), obj.pya.Vector(1, 0), ncopies_y.value, 1);
            gds_modeler.pycell.insert(array_2);
            gds_modeler.pycell.flatten(-1);
            region = obj.captureLayerRegion(gds_modeler, layer);
            arrayAdapter = obj.spawn(region);
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

        function region = captureLayerRegion(obj, gds_modeler, layer)
            region = obj.pya.Region();
            region.insert(gds_modeler.pycell.shapes(layer), py.int(0));
            region.merge();
        end
    end
end
