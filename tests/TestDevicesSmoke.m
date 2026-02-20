classdef TestDevicesSmoke < matlab.unittest.TestCase
    methods (Test)
        function stubsReturnStruct(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            o1 = devices.transmon_basic(ctx);
            o2 = devices.fluxonium_basic(ctx);
            o3 = devices.resonator_hanger(ctx);
            testCase.verifyTrue(isstruct(o1) && isstruct(o2) && isstruct(o3));
        end
    end
end
