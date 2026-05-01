classdef TestGeometryPipelineUtils < matlab.unittest.TestCase
    % Unit tests for GeometryPipeline static utility behavior.
    methods (TestMethodTeardown)
        function clearCurrentContext(~)
            core.GeometryPipeline.set_current([]);
        end
    end

    methods (Test)
        function addLayerInfersComsolEmitFromWorkplane(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);

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
            ctx_live = core.GeometryPipeline( ...
                enable_comsol=false, enable_gds=false, ...
                preview_klayout=true, ...
                snap_on_grid=false);
            ctx_batch = core.GeometryPipeline( ...
                enable_comsol=false, enable_gds=false, ...
                preview_klayout=false, ...
                snap_on_grid=false);

            testCase.verifyTrue(ctx_live.preview_klayout);
            testCase.verifyFalse(ctx_live.preview_live_active);
            testCase.verifyEqual(string(ctx_live.preview_live_filename), "");

            testCase.verifyFalse(ctx_batch.preview_klayout);
        end

        function nodeKeepsInputsReadsFeatureFlag(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            rect = primitives.Rectangle(ctx, center=[0 0], width=20, height=10, layer="default");

            keep_node = ops.Move(ctx, rect, delta=[10 0], keep_input_objects=true, layer="default");
            consume_node = ops.Move(ctx, rect, delta=[20 0], keep_input_objects=false, layer="default");

            testCase.verifyTrue(core.GeometryPipeline.node_keeps_inputs(keep_node));
            testCase.verifyFalse(core.GeometryPipeline.node_keeps_inputs(consume_node));
            testCase.verifyFalse(core.GeometryPipeline.node_keeps_inputs(rect));
        end

        function rectangleAndSquareExposeBezierFilletHelpers(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);

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

        function geomFeatureBooleanOperatorSugarMapsToOps(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            r1 = primitives.Rectangle(ctx, center=[0 0], width=20, height=10, layer="default");
            r2 = primitives.Rectangle(ctx, center=[8 0], width=20, height=10, layer="default");

            u_plus = r1 + r2;
            d_minus = r1 - r2;
            i_and = r1 & r2;
            u_or = r1 | r2;
            i_fn = intersect(r1, r2);

            testCase.verifyClass(u_plus, "ops.Union");
            testCase.verifyClass(d_minus, "ops.Difference");
            testCase.verifyClass(i_and, "ops.Intersection");
            testCase.verifyClass(u_or, "ops.Union");
            testCase.verifyClass(i_fn, "ops.Intersection");

            testCase.verifyEqual(numel(u_plus.inputs), 2);
            testCase.verifyEqual(int32(d_minus.base.id), int32(r1.id));
            testCase.verifyEqual(int32(d_minus.tools{1}.id), int32(r2.id));
        end

        function layerBooleanMergeConsumesSourcesByDefault(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            l1 = ctx.add_layer("m1", gds_layer=10, gds_datatype=0);
            l2 = ctx.add_layer("m2", gds_layer=11, gds_datatype=0);
            l3 = ctx.add_layer("m3", gds_layer=12, gds_datatype=0);

            a = primitives.Rectangle(ctx, center=[0 0], width=20, height=10, layer=l1);
            b = primitives.Rectangle(ctx, center=[8 0], width=20, height=10, layer=l2);
            out = ctx.merge_layers(l1, l2, output_layer=l3);

            testCase.verifyClass(out, "ops.Union");
            testCase.verifyEqual(string(out.layer.name), "m3");

            terminal_ids = cellfun(@(n) int32(n.id), ctx.terminal_nodes());
            testCase.verifyEqual(sort(terminal_ids), int32(out.id));
            testCase.verifyFalse(ismember(int32(a.id), terminal_ids));
            testCase.verifyFalse(ismember(int32(b.id), terminal_ids));
        end

        function layerBooleanPreserveSourcesKeepsInputs(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.add_layer("m1", gds_layer=10, gds_datatype=0);
            ctx.add_layer("m2", gds_layer=11, gds_datatype=0);
            ctx.add_layer("m3", gds_layer=12, gds_datatype=0);

            a = primitives.Rectangle(ctx, center=[0 0], width=20, height=10, layer="m1");
            b = primitives.Rectangle(ctx, center=[8 0], width=20, height=10, layer="m2");
            out = ctx.intersect_layers("m1", "m2", output_layer="m3", preserve_sources=true);

            terminal_ids = cellfun(@(n) int32(n.id), ctx.terminal_nodes());
            testCase.verifyTrue(ismember(int32(a.id), terminal_ids));
            testCase.verifyTrue(ismember(int32(b.id), terminal_ids));
            testCase.verifyTrue(ismember(int32(out.id), terminal_ids));
        end

        function layerBooleanScopeAllIncludesConsumedNodes(testCase)
            ctx_terminal = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx_terminal.add_layer("m1", gds_layer=10, gds_datatype=0);
            ctx_terminal.add_layer("m2", gds_layer=11, gds_datatype=0);
            ctx_terminal.add_layer("m3", gds_layer=12, gds_datatype=0);
            seed_t = primitives.Rectangle(ctx_terminal, center=[0 0], width=20, height=10, layer="m1");
            ops.Move(ctx_terminal, seed_t, delta=[30 0], layer="m1");
            primitives.Rectangle(ctx_terminal, center=[10 0], width=20, height=10, layer="m2");
            out_terminal = ctx_terminal.merge_layers("m1", "m2", scope="terminal", output_layer="m3");

            m1_union_terminal = out_terminal.inputs{1};
            testCase.verifyEqual(numel(m1_union_terminal.inputs), 1);

            ctx_all = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx_all.add_layer("m1", gds_layer=10, gds_datatype=0);
            ctx_all.add_layer("m2", gds_layer=11, gds_datatype=0);
            ctx_all.add_layer("m3", gds_layer=12, gds_datatype=0);
            seed_a = primitives.Rectangle(ctx_all, center=[0 0], width=20, height=10, layer="m1");
            ops.Move(ctx_all, seed_a, delta=[30 0], layer="m1");
            primitives.Rectangle(ctx_all, center=[10 0], width=20, height=10, layer="m2");
            out_all = ctx_all.merge_layers("m1", "m2", scope="all", output_layer="m3");

            m1_union_all = out_all.inputs{1};
            testCase.verifyEqual(numel(m1_union_all.inputs), 2);
        end

        function layerBooleanRejectsEmptyInputByDefault(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.add_layer("m1", gds_layer=10, gds_datatype=0);
            ctx.add_layer("m2", gds_layer=11, gds_datatype=0);
            primitives.Rectangle(ctx, center=[0 0], width=20, height=10, layer="m1");

            testCase.verifyError(@() ctx.merge_layers("m1", "m2"), ...
                "GeometryPipeline:LayerBooleanEmptyInput");
        end

        function layerBooleanAllowEmptySubtractWorks(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.add_layer("m1", gds_layer=10, gds_datatype=0);
            ctx.add_layer("m2", gds_layer=11, gds_datatype=0);
            ctx.add_layer("m3", gds_layer=12, gds_datatype=0);
            primitives.Rectangle(ctx, center=[0 0], width=20, height=10, layer="m1");

            out = ctx.subtract_layers("m1", "m2", allow_empty=true, output_layer="m3");
            testCase.verifyEqual(string(out.layer.name), "m3");
            testCase.verifyClass(out, "ops.Move");
        end

        function layerBooleanRejectsWorkplaneMismatchWhenComsolRequested(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.comsol = struct('mock', true); % Enable COMSOL-only validation path without server startup.
            ctx.add_layer("m1", gds_layer=10, gds_datatype=0, comsol_workplane="wp1");
            ctx.add_layer("m2", gds_layer=11, gds_datatype=0, comsol_workplane="wp2");
            primitives.Rectangle(ctx, center=[0 0], width=20, height=10, layer="m1");
            primitives.Rectangle(ctx, center=[8 0], width=20, height=10, layer="m2");

            testCase.verifyError(@() ctx.merge_layers("m1", "m2"), ...
                "GeometryPipeline:LayerBooleanWorkplaneMismatch");
        end

        function copyLayerCopiesToExistingOutputLayer(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            src = ctx.add_layer("src", gds_layer=20, gds_datatype=0);
            dst = ctx.add_layer("dst", gds_layer=21, gds_datatype=0);

            r1 = primitives.Rectangle(ctx, center=[0 0], width=20, height=10, layer=src);
            r2 = primitives.Rectangle(ctx, center=[30 0], width=20, height=10, layer=src);
            src_union = ops.Union(ctx, {r1, r2}, layer=src, keep_input_objects=false);
            out = ctx.copy_layer(src, dst);

            testCase.verifyClass(out, "ops.Union");
            testCase.verifyEqual(string(out.layer.name), "dst");

            copied_move = out.inputs{1};
            testCase.verifyClass(copied_move, "ops.Move");
            testCase.verifyEqual(int32(copied_move.target.id), int32(src_union.id));

            terminal_ids = cellfun(@(n) int32(n.id), ctx.terminal_nodes());
            testCase.verifyTrue(ismember(int32(src_union.id), terminal_ids));
            testCase.verifyTrue(ismember(int32(out.id), terminal_ids));
        end

        function copyLayerAllowEmptyReturnsEmptyFeature(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.add_layer("src", gds_layer=20, gds_datatype=0);
            ctx.add_layer("dst", gds_layer=21, gds_datatype=0);

            out = ctx.copy_layer("src", "dst", allow_empty=true, add_to_comsol=false);
            testCase.verifyClass(out, "ops.Union");
            testCase.verifyEqual(string(out.layer.name), "dst");
            testCase.verifyEqual(numel(out.inputs), 0);
        end

        function copyLayerRejectsEmptySourceByDefault(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.add_layer("src", gds_layer=20, gds_datatype=0);
            ctx.add_layer("dst", gds_layer=21, gds_datatype=0);

            testCase.verifyError(@() ctx.copy_layer("src", "dst"), ...
                "GeometryPipeline:LayerCopyEmptyInput");
        end

        function copyLayerRejectsWorkplaneMismatchWhenComsolRequested(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.comsol = struct('mock', true); % Enable COMSOL-only validation path without server startup.
            ctx.add_layer("src", gds_layer=20, gds_datatype=0, comsol_workplane="wp1");
            ctx.add_layer("dst", gds_layer=21, gds_datatype=0, comsol_workplane="wp2");
            primitives.Rectangle(ctx, center=[0 0], width=20, height=10, layer="src");

            testCase.verifyError(@() ctx.copy_layer("src", "dst"), ...
                "GeometryPipeline:LayerBooleanWorkplaneMismatch");
        end

        function buildSkipsDisabledBackends(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            out = ctx.build(report=false);

            testCase.verifyFalse(out.built_gds);
            testCase.verifyFalse(out.built_comsol);
            testCase.verifyEqual(string(out.gds_filename), "");
        end

        function buildInfersDefaultGdsFilenameFromCallerFile(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=true, ...
                preview_klayout=false, snap_on_grid=false);
            primitives.Rectangle(ctx, center=[0 0], width=20, height=10, layer="default");

            out = ctx.build(report=false);
            gds_path = string(out.gds_filename);
            testCase.verifyTrue(endsWith(gds_path, "TestGeometryPipelineUtils.gds"));
            testCase.verifyTrue(isfile(gds_path));

            if isfile(gds_path)
                delete(gds_path);
            end
        end
    end
end
