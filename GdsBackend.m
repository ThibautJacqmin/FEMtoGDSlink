classdef GdsBackend < handle
    % GDS backend for emitting feature graph into a GDS layout.
    properties
        session
        modeler
        regions
        emitted
    end
    methods
        function obj = GdsBackend(session)
            obj.session = session;
            obj.modeler = session.gds;
            obj.regions = containers.Map('KeyType', 'int32', 'ValueType', 'any');
            obj.emitted = containers.Map('KeyType', 'int32', 'ValueType', 'logical');
        end

        function emit_all(obj, nodes)
            for i = 1:numel(nodes)
                obj.emit(nodes{i});
            end
        end

        function emit(obj, node)
            region = obj.region_for(node);
            if ~node.output
                return;
            end
            id = int32(node.id);
            if isKey(obj.emitted, id)
                return;
            end
            layer = node.layer;
            layer_id = obj.modeler.create_layer(layer.gds_layer, layer.gds_datatype);
            poly = Polygon;
            poly.pgon_py = region;
            obj.modeler.add_to_layer(layer_id, poly);
            obj.emitted(id) = true;
        end

        function region = region_for(obj, node)
            id = int32(node.id);
            if isKey(obj.regions, id)
                region = obj.regions(id);
                return;
            end
            method = "build_" + class(node);
            if ismethod(obj, method)
                region = obj.(method)(node);
            else
                error("No GDS emitter for feature '" + class(node) + "'.");
            end
            obj.regions(id) = region;
        end

        function region = build_Rectangle(obj, node)
            verts = obj.session.gds_integer(node.vertices(), "Rectangle vertices");
            poly = obj.modeler.pya.Polygon.from_s(Utilities.vertices_to_klayout_string(verts));
            region = obj.modeler.pya.Region();
            region.insert(poly);
            region.merge();
        end

        function region = build_Move(obj, node)
            base = obj.region_for(node.target);
            delta = obj.gds_length_vector(node.delta, "Move delta");
            t = obj.modeler.pya.Trans(obj.modeler.pya.Point(delta(1), delta(2)));
            region = base.transformed(t);
        end

        function region = build_Rotate(obj, node)
            base = obj.region_for(node.target);
            origin = obj.gds_length_vector(node.origin, "Rotate origin");
            angle = obj.scalar_value(node.angle);
            region = obj.apply_translate(base, -origin(1), -origin(2));
            rot = obj.modeler.pya.CplxTrans(1, angle, py.bool(0), 0, 0);
            region = region.transformed(rot);
            region = obj.apply_translate(region, origin(1), origin(2));
        end

        function region = build_Scale(obj, node)
            base = obj.region_for(node.target);
            origin = obj.gds_length_vector(node.origin, "Scale origin");
            factor = obj.scalar_value(node.factor);
            region = obj.apply_translate(base, -origin(1), -origin(2));
            sca = obj.modeler.pya.CplxTrans(factor);
            region = region.transformed(sca);
            region = obj.apply_translate(region, origin(1), origin(2));
        end

        function region = build_Mirror(obj, node)
            base = obj.region_for(node.target);
            point = obj.gds_length_vector(node.point, "Mirror point");
            axis = obj.vector_value(node.axis);
            if numel(axis) ~= 2
                error("Mirror axis must be a 2D vector.");
            end
            if axis(1) ~= 0 && axis(2) ~= 0
                error("Mirror supports only horizontal or vertical axes.");
            end
            if axis(1) ~= 0
                region = obj.apply_translate(base, -point(1), 0);
                region = region.transformed(obj.modeler.pya.Trans.M90);
                region = obj.apply_translate(region, point(1), 0);
            else
                region = obj.apply_translate(base, 0, -point(2));
                region = region.transformed(obj.modeler.pya.Trans.M0);
                region = obj.apply_translate(region, 0, point(2));
            end
        end

        function region = build_Union(obj, node)
            if isempty(node.inputs)
                region = obj.modeler.pya.Region();
                return;
            end
            region = obj.region_for(node.inputs{1});
            for i = 2:numel(node.inputs)
                region = region + obj.region_for(node.inputs{i});
            end
            region.merge();
        end

        function region = build_Difference(obj, node)
            base = obj.region_for(node.base);
            region = base;
            tools = node.tools;
            for i = 1:numel(tools)
                region = region - obj.region_for(tools{i});
            end
            region.merge();
        end

        function region = build_Intersection(obj, node)
            if isempty(node.inputs)
                region = obj.modeler.pya.Region();
                return;
            end
            region = obj.region_for(node.inputs{1});
            for i = 2:numel(node.inputs)
                region = region.and_(obj.region_for(node.inputs{i}));
            end
            region.merge();
        end

        function region = build_Array1D(obj, node)
            base = obj.region_for(node.target);
            n = obj.copy_count(node.ncopies, "Array1D ncopies");
            delta = obj.gds_length_vector(node.delta, "Array1D delta");
            region = obj.modeler.pya.Region();
            for i = 0:(n-1)
                shifted = obj.apply_translate(base, i*delta(1), i*delta(2));
                region = region + shifted;
            end
            region.merge();
        end

        function region = build_Array2D(obj, node)
            base = obj.region_for(node.target);
            nx = obj.copy_count(node.ncopies_x, "Array2D ncopies_x");
            ny = obj.copy_count(node.ncopies_y, "Array2D ncopies_y");
            dx = obj.gds_length_vector(node.delta_x, "Array2D delta_x");
            dy = obj.gds_length_vector(node.delta_y, "Array2D delta_y");
            region = obj.modeler.pya.Region();
            for ix = 0:(nx-1)
                for iy = 0:(ny-1)
                    shift = ix*dx + iy*dy;
                    shifted = obj.apply_translate(base, shift(1), shift(2));
                    region = region + shifted;
                end
            end
            region.merge();
        end

        function region = build_Fillet(obj, node)
            base = obj.region_for(node.target);
            radius = obj.gds_length_scalar(node.radius, "Fillet radius");
            npoints = obj.scalar_value(node.npoints);
            region = base;
            if py.hasattr(region, "round_corners")
                region = region.round_corners(radius, radius, npoints);
            else
                warning("GDS fillet not supported by this KLayout build; skipping.");
            end
        end
    end
    methods (Access=private)
        function v = vector_value(obj, val)
            if isa(val, 'Vertices')
                v = val.value;
            else
                v = val;
            end
        end

        function v = scalar_value(obj, val)
            if isa(val, 'Parameter')
                v = val.value;
                return;
            end
            if isobject(val) && ismethod(val, 'value')
                v = val.value();
                return;
            end
            v = val;
        end

        function region = apply_translate(obj, region, dx, dy)
            t = obj.modeler.pya.Trans(obj.modeler.pya.Point(dx, dy));
            region = region.transformed(t);
        end

        function vec = gds_length_vector(obj, val, context)
            vec = obj.vector_value(val);
            vec = obj.session.gds_integer(vec, context);
        end

        function s = gds_length_scalar(obj, val, context)
            s = obj.scalar_value(val);
            s = obj.session.gds_integer(s, context);
        end

        function n = copy_count(obj, val, context)
            n = obj.scalar_value(val);
            n = obj.session.gds_integer(n, context);
            n = round(double(n));
            if ~(isscalar(n) && isfinite(n) && n >= 1)
                error("%s must be a scalar >= 1.", char(string(context)));
            end
        end
    end
end
