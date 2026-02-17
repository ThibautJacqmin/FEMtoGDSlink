classdef ConnectionResult
    properties
        route routing.Route
        cable routing.Cable
        adaptor_in cell = {}
        adaptor_out cell = {}
        length_nm double = NaN
        achieved_target logical = true
    end

    methods
        function obj = ConnectionResult(args)
            arguments
                args.route routing.Route
                args.cable routing.Cable
                args.adaptor_in cell = {}
                args.adaptor_out cell = {}
                args.length_nm double = NaN
                args.achieved_target logical = true
            end
            obj.route = args.route;
            obj.cable = args.cable;
            obj.adaptor_in = args.adaptor_in;
            obj.adaptor_out = args.adaptor_out;
            obj.length_nm = args.length_nm;
            obj.achieved_target = args.achieved_target;
        end
    end
end
