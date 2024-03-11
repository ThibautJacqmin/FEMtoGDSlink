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
                args.center (2, 1) double
                args.width double {mustBePositive}
                args.height double {mustBePositive}
                args.left double
                args.right double
                args.top double
                args.bottom double
                args.top_left (2, 1) double
                args.top_right (2, 1) double
                args.bottom_left (2, 1) double
                args.bottom_right (2, 1) double
                args.vertices (4, 2) double
            end
            fields = string(fieldnames(args));
            if length(intersect(fields, ["center", "width", "height"]))==3
                obj.set_center_height_width(args.center, args.height, args.width);
            elseif length(intersect(fields, ["left", "right", "bottom", "top"]))==4
                obj.set_left_right_bottom_top(args.left, args.right, args.bottom, args.top);
            elseif length(intersect(fields, ["bottom-left", "top-right"]))==2
                obj.set_bottomleft_topright(args.bottom_left, args.top_right);
            elseif length(intersect(fields, ["bottom-right", "top_left"]))==2
                obj.set_topleft_bottomright(args.bottom_right, args.top_left);
            elseif length(intersect(fields, "vertices"))==1
                obj.Vertices = args.vertices;
            end
        end
        function c = get.center(obj)
            x = obj.left + obj.width/2;
            y = obj.bottom + obj.height/2;
            c = [x, y];
        end
        function set.center(obj, val)
            obj.set_center_height_width(val, obj.height, obj.width)
        end
        function w = get.width(obj)
            w = obj.right-obj.left;
        end
        function set.width(obj, width)
            obj.set_center_height_width(obj.center, obj.height, width)
        end
        function h = get.height(obj)
            h = obj.top-obj.bottom;
        end
        function set.height(obj, height)
            obj.set_center_height_width(obj.center, height, obj.width)
        end
        function l = get.left(obj)
            l = obj.Vertices(1, 1);
        end
        function r = get.right(obj)
            r = obj.Vertices(3, 1);
        end
        function b = get.bottom(obj)
            b = obj.Vertices(1, 2);
        end
        function t = get.top(obj)
            t = obj.Vertices(3, 2);
        end
        function tl = get.top_left(obj)
            tl = [obj.left, obj.top];
        end
        function tr = get.top_right(obj)
            tr = [obj.right, obj.top];
        end
        function bl = get.bottom_left(obj)
            bl = [obj.left, obj.bottom];
        end
        function br = get.bottom_right(obj)
            br = [obj.right, obj.bottom];
        end
        function fillet_polygons = get_fillets(obj)
            fillet_polygons = {};

            p0 = [obj.right, obj.bottom];
            p1 = [obj.right + obj.fillet_width, obj.bottom];
            p2 = [obj.right, obj.bottom + obj.fillet_height];
            fillet_points = Utilities.bezier_fillet(p0, p1, p2);
            fillet_polygon = Polygon(vertices=fillet_points);
            fillet_polygon.Vertices(end+1, :) = p0;
            fillet_polygons{end+1} = fillet_polygon; 

            fillet_polygon_1 = copy(fillet_polygon);
            fillet_polygon_1.flip_horizontally((obj.left+obj.right)/2);
            fillet_polygons{end+1} = fillet_polygon_1;

            fillet_polygon_2 = copy(fillet_polygon);
            fillet_polygon_2.flip_vertically((obj.top+obj.bottom)/2);
            fillet_polygons{end+1} = fillet_polygon_2;  

            fillet_polygon_3 = copy(fillet_polygon_2);
            fillet_polygon_3.flip_horizontally((obj.left+obj.right)/2);
            fillet_polygons{end+1} = fillet_polygon_3;  

        end
    end
    methods (Access=private)
        function set_center_height_width(obj, center, height, width)
            l = center(1)-width/2;
            r = center(1)+width/2;
            t = center(2)+height/2;
            b = center(2)-height/2;
            obj.Vertices = [l, b; l, t; r, t; r, b];
        end
        function set_left_right_bottom_top(obj, l, r, b, t)
            obj.Vertices = [l, b; l, t; r, t; r, b];
        end
        function set_bottomleft_topright(obj, bottom_left, top_right)
            l = bottom_left(1);
            r = top_right(1);
            t = top_right(2);
            b = bottom_left(2);
            obj.Vertices = [l, b; l, t; r, t; r, b];
        end
        function set_topleft_bottomright(obj, bottom_right, top_left)
            l = top_left(1);
            r = bottom_right(1);
            t = top_left(2);
            b = bottom_right(2);
            obj.Vertices = [l, b; l, t; r, t; r, b];
        end
    end
end