classdef MeanderSpec
    properties
        enabled logical = false
        segment_indices double = []   % indices on centerline to meander
        amplitude_nm double = NaN
        pitch_nm double = NaN
        count double = NaN
    end

    methods
        function obj = MeanderSpec(args)
            arguments
                args.enabled logical = false
                args.segment_indices double = []
                args.amplitude_nm double = NaN
                args.pitch_nm double = NaN
                args.count double = NaN
            end
            obj.enabled = args.enabled;
            obj.segment_indices = args.segment_indices;
            obj.amplitude_nm = args.amplitude_nm;
            obj.pitch_nm = args.pitch_nm;
            obj.count = args.count;
        end
    end

    methods (Static)
        function obj = disabled()
            obj = routing.MeanderSpec(enabled=false);
        end
    end
end
