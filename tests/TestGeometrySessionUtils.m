classdef TestGeometrySessionUtils < matlab.unittest.TestCase
    % Unit tests for GeometrySession static utility behavior.
    methods (TestMethodTeardown)
        function clearCurrentContext(~)
            core.GeometrySession.set_current([]);
        end
    end

    methods (Test)
        function addLayerInfersComsolEmitFromWorkplane(testCase)
            ctx = core.GeometrySession(enable_comsol=false, enable_gds=false, snap_on_grid=false);

            gds_only = ctx.add_layer("gds_only", gds_layer=7, gds_datatype=0);
            comsol_layer = ctx.add_layer("m2", gds_layer=8, gds_datatype=0, ...
                comsol_workplane="wp2");
            blank_wp = ctx.add_layer("blank_wp", gds_layer=9, gds_datatype=0, ...
                comsol_workplane="   ");

            testCase.verifyFalse(gds_only.comsol_emit);
            testCase.verifyEqual(string(gds_only.comsol_workplane), "");
            testCase.verifyTrue(comsol_layer.comsol_emit);
            testCase.verifyFalse(blank_wp.comsol_emit);
        end

        function previewFlagsAreStoredInSession(testCase)
            ctx_live = core.GeometrySession( ...
                enable_comsol=false, enable_gds=false, ...
                preview_klayout=true, ...
                snap_on_grid=false);
            ctx_batch = core.GeometrySession( ...
                enable_comsol=false, enable_gds=false, ...
                preview_klayout=false, ...
                snap_on_grid=false);

            testCase.verifyTrue(ctx_live.preview_klayout);
            testCase.verifyFalse(ctx_live.preview_live_active);
            testCase.verifyEqual(string(ctx_live.preview_live_filename), "");

            testCase.verifyFalse(ctx_batch.preview_klayout);
        end

        function nodeKeepsInputsReadsFeatureFlag(testCase)
            ctx = core.GeometrySession(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            rect = primitives.Rectangle(ctx, center=[0 0], width=20, height=10, layer="default");

            keep_node = ops.Move(ctx, rect, delta=[10 0], keep_input_objects=true, layer="default");
            consume_node = ops.Move(ctx, rect, delta=[20 0], keep_input_objects=false, layer="default");

            testCase.verifyTrue(core.GeometrySession.node_keeps_inputs(keep_node));
            testCase.verifyFalse(core.GeometrySession.node_keeps_inputs(consume_node));
            testCase.verifyFalse(core.GeometrySession.node_keeps_inputs(rect));
        end

        function rectangleAndSquareExposeBezierFilletHelpers(testCase)
            ctx = core.GeometrySession(enable_comsol=false, enable_gds=false, snap_on_grid=false);

            r = primitives.Rectangle(ctx, center=[10 5], width=8, height=4, layer="default");
            testCase.verifyEqual(r.left.value, 6, AbsTol=1e-12);
            testCase.verifyEqual(r.right.value, 14, AbsTol=1e-12);
            testCase.verifyEqual(r.bottom.value, 3, AbsTol=1e-12);
            testCase.verifyEqual(r.top.value, 7, AbsTol=1e-12);
            testCase.verifyEqual(r.top_left.value, [6, 7], AbsTol=1e-12);
            testCase.verifyEqual(r.top_right.value, [14, 7], AbsTol=1e-12);
            testCase.verifyEqual(r.bottom_left.value, [6, 3], AbsTol=1e-12);
            testCase.verifyEqual(r.bottom_right.value, [14, 3], AbsTol=1e-12);

            rf = r.get_fillets(fillet_width=2, fillet_height=1, npoints=6);
            testCase.verifyEqual(numel(rf), 4);
            for i = 1:numel(rf)
                testCase.verifyClass(rf{i}, "primitives.Polygon");
            end

            s = primitives.Square(ctx, center=[0 0], side=6, layer="default");
            testCase.verifyEqual(s.width.value, 6, AbsTol=1e-12);
            testCase.verifyEqual(s.height.value, 6, AbsTol=1e-12);
            s.size = 9;
            testCase.verifyEqual(s.width.value, 9, AbsTol=1e-12);
            testCase.verifyEqual(s.height.value, 9, AbsTol=1e-12);
            s.side = 12;
            testCase.verifyEqual(s.width.value, 12, AbsTol=1e-12);
            testCase.verifyEqual(s.height.value, 12, AbsTol=1e-12);

            sf = s.get_fillets(fillet_width=1.5, fillet_height=1.5, npoints=8);
            testCase.verifyEqual(numel(sf), 4);
        end

        function buildSkipsDisabledBackends(testCase)
            ctx = core.GeometrySession(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            out = ctx.build(report=false);

            testCase.verifyFalse(out.built_gds);
            testCase.verifyFalse(out.built_comsol);
            testCase.verifyEqual(string(out.gds_filename), "");
        end

        function buildInfersDefaultGdsFilenameFromCallerFile(testCase)
            ctx = core.GeometrySession(enable_comsol=false, enable_gds=true, ...
                preview_klayout=false, snap_on_grid=false);
            primitives.Rectangle(ctx, center=[0 0], width=20, height=10, layer="default");

            out = ctx.build(report=false);
            gds_path = string(out.gds_filename);
            testCase.verifyTrue(endsWith(gds_path, "TestGeometrySessionUtils.gds"));
            testCase.verifyTrue(isfile(gds_path));

            if isfile(gds_path)
                delete(gds_path);
            end
        end
    end
end
