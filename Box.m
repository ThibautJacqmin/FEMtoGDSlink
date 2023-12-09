classdef Box < Shape
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
            l = obj.points(1, 1);
        end
        function r = get.right(obj)
            r = obj.points(3, 1);
        end
        function b = get.bottom(obj)
            b = obj.points(1, 2);
        end
        function t = get.top(obj)
            t = obj.points(3, 2);
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
    end
    methods (Access=private)
        function set_center_height_width(obj, center, height, width)
            l = center(1)-width/2;
            r = center(1)+width/2;
            t = center(2)+height/2;
            b = center(2)-height/2;
            obj.points = [l, b; l, t; r, t; r, b];
        end
        function set_left_right_bottom_top(obj, l, r, b, t)
            obj.points = [l, b; l, t; r, t; r, b];
        end
        function set_bottomleft_topright(obj, bottom_left, top_right)
            l = bottom_left(1);
            r = top_right(1);
            t = top_right(2);
            b = bottom_left(2);
            obj.points = [l, b; l, t; r, t; r, b];
        end
        function set_topleft_bottomright(obj, bottom_right, top_left)
            l = top_left(1);
            r = bottom_right(1);
            t = top_left(2);
            b = bottom_right(2);
            obj.points = [l, b; l, t; r, t; r, b];
        end
    end
    methods (Hidden)
        function py_obj = get_python_obj(obj, pya)
            py_obj = pya.Box(obj.left, obj.bottom, obj.right, obj.top);
        end
    end
end