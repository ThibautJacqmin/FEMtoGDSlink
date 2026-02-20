classdef TestComponentsCpw < matlab.unittest.TestCase
    methods (Test)
        function edgeLaunchBuilds(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.add_layer("metal1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");
            ctx.add_layer("gap", gds_layer=2, gds_datatype=0, comsol_workplane="wp1");

            s = components.cpw.spec(14, 34);
            p = components.cpw.port("p0", [0,0], [1,0], s);
            out = components.cpw.edge_launch(ctx, p, name="L0");

            testCase.verifyTrue(isfield(out, "wide_port"));
            testCase.verifyEqual(numel(out.features), 2);
        end

        function meanderLineReachesTarget(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.add_layer("metal1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");
            ctx.add_layer("gap", gds_layer=2, gds_datatype=0, comsol_workplane="wp1");

            s = components.cpw.spec(14, 34);
            p1 = components.cpw.port("m1", [0, 0], [1, 0], s);
            p2 = components.cpw.port("m2", [700, 0], [-1, 0], s);

            out = components.cpw.meander_line(ctx, p1, p2, ...
                name="M0", fillet=12, target_nm=1200);

            testCase.verifyTrue(out.achieved_target);
            testCase.verifyGreaterThan(out.length_nm, 1000);
            testCase.verifyGreaterThan(size(out.route.points, 1), 5);
        end

        function connectorAndRoutedLineBuild(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.add_layer("metal1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");
            ctx.add_layer("gap", gds_layer=2, gds_datatype=0, comsol_workplane="wp1");

            s = components.cpw.spec(14, 34);
            p1 = components.cpw.port("a", [0, 0], [1, 0], s);
            p2 = components.cpw.port("b", [350, 70], [-1, 0], s);
            p3 = components.cpw.port("c", [700, 20], [-1, 0], s);

            r1 = components.cpw.routed_line(ctx, p1, p2, name="R0", fillet=10);
            r2 = components.cpw.connector(ctx, p2, p3, name="C0", fillet=10);

            testCase.verifyGreaterThan(r1.length_nm, 0);
            testCase.verifyGreaterThan(r2.length_nm, 0);
            testCase.verifyTrue(isa(r1.cable, "routing.Cable"));
            testCase.verifyTrue(isa(r2.cable, "routing.Cable"));
        end
    end
end
