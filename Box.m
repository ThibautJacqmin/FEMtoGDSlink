classdef Box < Polygon
    properties (Dependent)
        center
        height
        width
        left
        right
        top
        bottom
        top_right
        top_left
        bottom_right
        bottom_left
    end
    properties
        fillet_width
        fillet_height
    end
    methods
        function obj = Box(args)
            arguments
                args.center Vertices = Vertices.empty
                args.width Parameter = Parameter.empty
                args.height Parameter = Parameter.empty
                args.left Parameter = Parameter.empty
                args.right Parameter = Parameter.empty
                args.top Parameter = Parameter.empty
                args.bottom Parameter = Parameter.empty
                args.top_left Vertices = Vertices.empty
                args.top_right Vertices = Vertices.empty
                args.bottom_left Vertices = Vertices.empty
                args.bottom_right Vertices = Vertices.empty
                args.vertices Vertices = Vertices.empty
                args.fillet_width Parameter = Parameter(1, "")
                args.fillet_height Parameter = Parameter(1, "")
                args.comsol_modeler ComsolModeler = ComsolModeler.empty
            end
            obj@Polygon(vertices=Vertices.empty, ...
                comsol_modeler=args.comsol_modeler, initialize_comsol=false);

            obj.fillet_height = args.fillet_height;
            obj.fillet_width = args.fillet_width;

            if ~isempty(args.vertices)
                obj.vertices = args.vertices;
                obj.klayout_adapter.initializePolygon(args.vertices);
                obj.sync_klayout_shape();
                obj.update_comsol_rectangle(args.vertices.value);
            elseif ~isempty(args.center) && ~isempty(args.width) && ~isempty(args.height)
                obj.set_center_height_width(obj.extractCoordinate(args.center), ...
                    obj.extractNumeric(args.height), obj.extractNumeric(args.width));
            elseif ~isempty(args.left) && ~isempty(args.right) && ~isempty(args.bottom) && ~isempty(args.top)
                obj.set_left_right_bottom_top(obj.extractNumeric(args.left), ...
                    obj.extractNumeric(args.right), obj.extractNumeric(args.bottom), obj.extractNumeric(args.top));
            elseif ~isempty(args.bottom_left) && ~isempty(args.top_right)
                obj.set_bottomleft_topright(obj.extractCoordinate(args.bottom_left), ...
                    obj.extractCoordinate(args.top_right));
            elseif ~isempty(args.bottom_right) && ~isempty(args.top_left)
                obj.set_topleft_bottomright(obj.extractCoordinate(args.bottom_right), ...
                    obj.extractCoordinate(args.top_left));
            else
                obj.vertices = Vertices([0, 0; 0, 0; 0, 0; 0, 0]);
                obj.klayout_adapter.initializePolygon(obj.vertices);
                obj.sync_klayout_shape();
                obj.update_comsol_rectangle(obj.vertices.value);
            end
        end
        function c = get.center(obj)
            x = obj.left.value + obj.width.value/2;
            y = obj.bottom.value + obj.height.value/2;
            c = Vertices([x, y]);
        end
        function set.center(obj, val)
            obj.set_center_height_width(obj.extractCoordinate(val), obj.height.value, obj.width.value);
        end
        function w = get.width(obj)
            w = obj.right-obj.left;
            w.name = "width";
        end
        function set.width(obj, width)
            obj.set_center_height_width(obj.center.value, obj.height.value, obj.extractNumeric(width));
        end
        function h = get.height(obj)
            h = obj.top-obj.bottom;
            h.name = "height";
        end
        function set.height(obj, height)
            obj.set_center_height_width(obj.center.value, obj.extractNumeric(height), obj.width.value);
        end
        function l = get.left(obj)
            l = Parameter(obj.vertices.value(1, 1), "left");
        end
        function r = get.right(obj)
            r = Parameter(obj.vertices.value(3, 1), "right");
        end
        function b = get.bottom(obj)
            b = Parameter(obj.vertices.value(1, 2), "bottom");
        end
        function t = get.top(obj)
            t = Parameter(obj.vertices.value(3, 2), "top");
        end
        function tl = get.top_left(obj)
            tl = [obj.left.value, obj.top.value];
        end
        function tr = get.top_right(obj)
            tr = [obj.right.value, obj.top.value];
        end
        function bl = get.bottom_left(obj)
            bl = [obj.left.value, obj.bottom.value];
        end
        function br = get.bottom_right(obj)
            br = [obj.right.value, obj.bottom.value];
        end
        function fillet_polygons = get_fillets(obj)
            fillet_polygons = {};

            p0 = [obj.right.value, obj.bottom.value];
            p1 = [obj.right.value + obj.fillet_width.value, obj.bottom.value];
            p2 = [obj.right.value, obj.bottom.value + obj.fillet_height.value];
            fillet_points = Utilities.bezier_fillet(p0, p1, p2);
            fillet_points(end+1, :) = p2;
            fillet_points(end+1, :) = p0;
            fillet_points(end+1, :) = p1;
            fillet_polygon = Polygon(vertices=Vertices(fillet_points), ...
                comsol_modeler=obj.comsol_modeler);
            fillet_polygons{end+1} = fillet_polygon;

            fillet_polygon_1 = fillet_polygon.copy;
            fillet_polygon_1.flip_horizontally((obj.left+obj.right)./2);
            fillet_polygons{end+1} = fillet_polygon_1;

            fillet_polygon_2 = fillet_polygon.copy;
            fillet_polygon_2.flip_vertically((obj.top+obj.bottom)./2);
            fillet_polygons{end+1} = fillet_polygon_2;

            fillet_polygon_3 = fillet_polygon_2.copy;
            fillet_polygon_3.flip_horizontally((obj.left+obj.right)./2);
            fillet_polygons{end+1} = fillet_polygon_3;
        end
        function y = copy(obj)
            y = Box(vertices=obj.vertices.copy, comsol_modeler=obj.comsol_modeler, ...
                fillet_width=obj.fillet_width, fillet_height=obj.fillet_height);
        end
    end
    methods
        function set_center_height_width(obj, center, height, width)
            l = center(1) - width/2;
            r = center(1) + width/2;
            t = center(2) + height/2;
            b = center(2) - height/2;
            obj.set_vertices([l, b; l, t; r, t; r, b]);
        end
        function set_left_right_bottom_top(obj, l, r, b, t)
            obj.set_vertices([l, b; l, t; r, t; r, b]);
        end
        function set_bottomleft_topright(obj, bottom_left, top_right)
            l = bottom_left(1);
            r = top_right(1);
            t = top_right(2);
            b = bottom_left(2);
            obj.set_vertices([l, b; l, t; r, t; r, b]);
        end
        function set_topleft_bottomright(obj, bottom_right, top_left)
            l = top_left(1);
            r = bottom_right(1);
            t = top_left(2);
            b = bottom_right(2);
            obj.set_vertices([l, b; l, t; r, t; r, b]);
        end
    end
    methods (Access = private)
        function set_vertices(obj, coordinates)
            obj.vertices = Vertices(coordinates);
            obj.klayout_adapter.initializePolygon(obj.vertices);
            obj.sync_klayout_shape();
            obj.update_comsol_rectangle(obj.vertices.value);
        end
        function update_comsol_rectangle(obj, values)
            if obj.comsol_flag && size(values, 1) >= 4
                left = values(1, 1);
                right = values(3, 1);
                bottom = values(1, 2);
                top = values(3, 2);
                obj.comsol_adapter.initializeRectangleFromBounds(left, right, bottom, top);
                obj.sync_comsol_shape();
            end
        end
        function value = extractNumeric(~, input)
            if isa(input, 'Parameter')
                value = input.value;
            elseif isnumeric(input)
                value = input;
            else
                error('Box:UnsupportedType', 'Unsupported value type "%s".', class(input));
            end
        end
        function coords = extractCoordinate(obj, input)
            if isa(input, 'Vertices')
                coords = input.value;
            else
                coords = obj.extractNumeric(input);
            end
        end
    end
end
