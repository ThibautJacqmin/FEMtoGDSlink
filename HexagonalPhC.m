classdef HexagonalPhC < Polygon
    properties
        scale = 0.3
        correction = 0.5e-6/sin(pi/6)
        bridge_width = 2.5e-6
        bridge_width_center = 2.5e-6
        structure_a = 45e-6
        pad_radius = 11e-6
        center_pad_radius = 18e-6
        triangle_angle_radius = 5e-6
        rhombus_angle_radius = 7e-6
        y_size = 17
        x_size
        frame_size
        offset = [-0.1, 0.5]
        coordinates

    end
    methods
        function obj = HexagonalPhC(args)
            arguments

            end
            % Comsol
            obj.comsol_modeler = args.comsol_modeler;
            obj.comsol_flag = ~isempty(obj.comsol_modeler);
        end

    end
    methods (Hidden)
        function set_comsol_rectangle(obj)
            if obj.comsol_flag

            end
        end
    end
end