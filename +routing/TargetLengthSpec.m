classdef TargetLengthSpec
    properties
        enabled logical = false
        length_nm double = NaN
        tolerance_nm double = 1.0
    end

    methods
        function obj = TargetLengthSpec(args)
            arguments
                args.enabled logical = false
                args.length_nm double = NaN
                args.tolerance_nm double = 1.0
            end
            obj.enabled = args.enabled;
            obj.length_nm = args.length_nm;
            obj.tolerance_nm = args.tolerance_nm;
        end
    end

    methods (Static)
        function obj = disabled()
            obj = routing.TargetLengthSpec(enabled=false);
        end
    end
end
