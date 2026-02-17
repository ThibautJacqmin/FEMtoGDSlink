classdef TestRoutingFacade < matlab.unittest.TestCase
    methods (Test)
        function connectReturnsResult(testCase)
            ctx = core.GeometrySession(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");
            spec = routing.PortSpec(widths=10, offsets=0, layers="m1", subnames="sig");
            p1 = routing.PortRef(name="a", pos=[0,0], ori=[1,0], spec=spec);
            p2 = routing.PortRef(name="b", pos=[100,50], ori=[-1,0], spec=spec);

            out = routing.connect(ctx, p1, p2, name="t0", fillet=8);
            testCase.verifyTrue(isa(out, "routing.ConnectionResult"));
            testCase.verifyGreaterThan(out.length_nm, 0);
        end

        function connectAutoDetoursWhenCornerTooTight(testCase)
            ctx = core.GeometrySession(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");
            spec = routing.PortSpec(widths=10, offsets=0, layers="m1", subnames="sig");
            p1 = routing.PortRef(name="in", pos=[0,0], ori=[1,0], spec=spec);
            p2 = routing.PortRef(name="out", pos=[300,25], ori=[-1,0], spec=spec);

            out = routing.connect(ctx, p1, p2, ...
                mode="auto", fillet=30, start_straight=80, end_straight=80, name="auto_detour");
            pts = out.route.points;
            seg = sqrt(sum(diff(pts, 1, 1).^2, 2));

            testCase.verifyGreaterThanOrEqual(size(pts, 1), 6);
            testCase.verifyGreaterThan(min(seg), 50);
        end

        function connectTargetAutoMeanderTuning(testCase)
            ctx = core.GeometrySession(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");
            spec = routing.PortSpec(widths=12, offsets=0, layers="m1", subnames="sig");
            p1 = routing.PortRef(name="a", pos=[0,0], ori=[1,0], spec=spec);
            p2 = routing.PortRef(name="b", pos=[650,70], ori=[-1,0], spec=spec);

            base = routing.connect(ctx, p1, p2, mode="auto", name="base");
            target = routing.TargetLengthSpec( ...
                enabled=true, ...
                length_nm=base.length_nm + 280, ...
                tolerance_nm=35);
            tuned = routing.connect(ctx, p1, p2, ...
                mode="auto", ...
                name="tuned", ...
                target=target);

            testCase.verifyTrue(tuned.achieved_target);
            testCase.verifyGreaterThan(tuned.length_nm, base.length_nm + 120);
            testCase.verifyGreaterThan(size(tuned.route.points, 1), size(base.route.points, 1));
        end

        function connectMismatchBuildsLinearAdaptors(testCase)
            ctx = core.GeometrySession(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");
            ctx.add_layer("gap", gds_layer=2, gds_datatype=0, comsol_workplane="wp1");

            s1 = routing.PortSpec( ...
                widths=[12, 32], offsets=[0, 0], ...
                layers=["m1", "gap"], subnames=["sig", "gap"]);
            s2 = routing.PortSpec( ...
                widths=[22, 54], offsets=[0, 0], ...
                layers=["m1", "gap"], subnames=["sig", "gap"]);
            p1 = routing.PortRef(name="in", pos=[0,0], ori=[1,0], spec=s1);
            p2 = routing.PortRef(name="out", pos=[700,50], ori=[-1,0], spec=s2);

            adp = routing.AdaptorSpec(enabled=true, style="linear", slope=0.35);
            out = routing.connect(ctx, p1, p2, ...
                mode="auto", ...
                allow_mismatch=true, ...
                adaptor=adp, ...
                name="mismatch");

            testCase.verifyEqual(numel(out.adaptor_in), 2);
            testCase.verifyEqual(numel(out.adaptor_out), 2);
            testCase.verifyGreaterThan(out.length_nm, out.cable.length_nm());

            d_in = norm(out.cable.port_in.position_value() - p1.position_value());
            d_out = norm(out.cable.port_out.position_value() - p2.position_value());
            testCase.verifyGreaterThan(d_in, 0);
            testCase.verifyGreaterThan(d_out, 0);
        end
    end
end
