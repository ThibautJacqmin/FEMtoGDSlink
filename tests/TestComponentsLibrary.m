classdef TestComponentsLibrary < matlab.unittest.TestCase
    methods (Test)
        function alignmentMarkLoads(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);

            mark = components.markers.alignment_mark(ctx, type=1, layer="default");

            testCase.verifyTrue(isa(mark, "core.GeomFeature"));
            if isa(mark, "ops.Union")
                testCase.verifyGreaterThan(numel(mark.members), 0);
            else
                testCase.verifyClass(mark, "primitives.Polygon");
            end
        end

        function twoInchWaferLoads(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);

            wafer = components.wafer.two_inch(ctx, layer="default");

            testCase.verifyClass(wafer, "primitives.Polygon");
            testCase.verifyGreaterThan(wafer.nvertices(), 2);
        end

        function alignmentMarkMissingTypeRaises(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);

            testCase.verifyError(@() components.markers.alignment_mark(ctx, type=9999, layer="default"), ...
                "components:markers:AlignmentMarkFileMissing");
        end
    end
end

