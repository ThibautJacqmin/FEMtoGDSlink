classdef AdaptorSpec
    properties
        enabled logical = false
        style string = "linear"   % currently: "linear"
        length_nm double = NaN
        slope double = 0.5
    end

    methods
        function obj = AdaptorSpec(args)
            arguments
                args.enabled logical = false
                args.style {mustBeTextScalar} = "linear"
                args.length_nm double = NaN
                args.slope double = 0.5
            end
            obj.enabled = args.enabled;
            obj.style = string(args.style);
            obj.length_nm = args.length_nm;
            obj.slope = args.slope;
        end
    end
end
