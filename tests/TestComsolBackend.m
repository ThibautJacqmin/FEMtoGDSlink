classdef TestComsolBackend < matlab.unittest.TestCase
    % Integration tests for COMSOL backend emission and shared model helpers.
    methods (TestMethodSetup)
        function requireComsolApi(testCase)
            % Skip this suite when COMSOL Java API is not available.
            testCase.assumeTrue(TestComsolBackend.hasComsolApi(), ...
                "Skipping: COMSOL API unavailable in this MATLAB session.");
        end
    end

    methods (TestMethodTeardown)
        function cleanupSharedComsol(~)
            % Ensure shared COMSOL state does not leak across tests.
            femtogds.core.GeometrySession.clear_shared_comsol();
            femtogds.core.GeometrySession.set_current([]);
        end
    end

    methods (Test)
        function emitGeometryGraphRegistersParametersAndSelections(testCase)
            % Verify emitted features, named parameters, and layer selections.
            ctx = femtogds.core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_mode="off", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p_pitch = femtogds.types.Parameter(40, "pitch_y");
            p_w0 = femtogds.types.Parameter(120, "tower_w0");
            p_dw = femtogds.types.Parameter(20, "tower_dw");
            p_h = femtogds.types.Parameter(60, "tower_h");
            p_rot = femtogds.types.Parameter(7, "tower_rot_deg", unit="");
            p_rect_rot = femtogds.types.Parameter(18, "rect_rot_deg", unit="");
            p_scale = femtogds.types.Parameter(0.95, "tower_scale", unit="");
            p_move = femtogds.types.Parameter(10, "tower_move_unit");
            p_rad = femtogds.types.Parameter(6, "fillet_r");
            p_n = femtogds.types.Parameter(@(x) max(8, round(2*x)), p_rad, "fillet_n", unit="");

            r1 = femtogds.primitives.Rectangle(ctx, center=femtogds.types.Vertices([0, 0], p_pitch), ...
                width=p_w0 - p_dw, height=p_h, layer="m1", output=false);
            r2 = femtogds.primitives.Rectangle(ctx, base="corner", corner=[5, -10], ...
                width=30, height=20, angle=p_rect_rot, layer="m1", output=false);
            u = femtogds.ops.Union(ctx, {r1, r2}, layer="m1", output=false);
            d = femtogds.ops.Difference(ctx, u, {r2}, layer="m1", output=false);
            m = femtogds.ops.Move(ctx, d, delta=femtogds.types.Vertices([1, 0], p_move), output=false);
            ro = femtogds.ops.Rotate(ctx, m, angle=p_rot, origin=femtogds.types.Vertices([0, 0], p_pitch), output=false);
            sc = femtogds.ops.Scale(ctx, ro, factor=p_scale, origin=femtogds.types.Vertices([0, 0], p_pitch), output=false);
            mi = femtogds.ops.Mirror(ctx, sc, point=femtogds.types.Vertices([0, 0], p_pitch), axis=[1, 0], output=false);
            i = femtogds.ops.Intersection(ctx, {mi, r1}, layer="m1", output=false);
            f = femtogds.ops.Fillet(ctx, i, radius=p_rad, npoints=p_n, points=[1 2 3 4], ...
                layer="m1", output=true);

            ctx.build_comsol();

            nodes = {r1, r2, u, d, m, ro, sc, mi, i, f};
            for k = 1:numel(nodes)
                testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(nodes{k}.id)));
            end

            expected = ["pitch_y", "tower_w0", "tower_dw", "tower_h", ...
                "tower_rot_deg", "rect_rot_deg", "tower_scale", "tower_move_unit", "fillet_r"];
            for k = 1:numel(expected)
                testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, string(expected(k))));
            end

            testCase.verifyTrue(isKey(ctx.comsol_backend.selection_tags, "wp1|metal1"));
            fil_tag = string(ctx.comsol_backend.feature_tags(int32(f.id)));
            testCase.verifyTrue(startsWith(fil_tag, "fil"));
            testCase.verifyEqual(r2.base, "corner");
            testCase.verifyEqual(r2.angle.value, p_rect_rot.value);
            testCase.verifyEqual(p_n.value, max(8, round(2*p_rad.value)));
        end

        function sharedModelerIsReusedAcrossSessions(testCase)
            % Verify with_shared_comsol reuses the same COMSOL model instance.
            femtogds.core.GeometrySession.clear_shared_comsol();
            ctx1 = femtogds.core.GeometrySession.with_shared_comsol(enable_gds=false, snap_mode="off", ...
                reset_model=true);
            tag1 = string(ctx1.comsol.model_tag);

            ctx2 = femtogds.core.GeometrySession.with_shared_comsol(enable_gds=false, snap_mode="off", ...
                reset_model=true);
            tag2 = string(ctx2.comsol.model_tag);

            testCase.verifyEqual(tag2, tag1);
            testCase.verifyTrue(isequal(ctx1.comsol, ctx2.comsol));
        end

        function clearSharedCreatesNewModel(testCase)
            % Verify clearing shared COMSOL forces creation of a new model tag.
            femtogds.core.GeometrySession.clear_shared_comsol();
            ctx1 = femtogds.core.GeometrySession.with_shared_comsol(enable_gds=false, snap_mode="off", ...
                reset_model=true);
            tag1 = string(ctx1.comsol.model_tag);

            femtogds.core.GeometrySession.clear_shared_comsol();
            ctx2 = femtogds.core.GeometrySession.with_shared_comsol(enable_gds=false, snap_mode="off", ...
                reset_model=true);
            tag2 = string(ctx2.comsol.model_tag);

            testCase.verifyNotEqual(tag1, tag2);
        end

        function resetWorkspaceClearsSnappedParameters(testCase)
            % Verify shared reset clears old snp* parameters.
            ctx1 = femtogds.core.GeometrySession.with_shared_comsol(enable_gds=true, snap_mode="strict", ...
                emit_on_create=false, reset_model=true);
            ctx1.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");

            p_w = femtogds.types.Parameter(120, "w");
            p_h = femtogds.types.Parameter(60, "h");
            r = femtogds.primitives.Rectangle(ctx1, center=[0 0], width=p_w, height=p_h, layer="m1", output=true); %#ok<NASGU>
            ctx1.build_comsol();

            names_before = TestComsolBackend.paramNames(ctx1.comsol.model);
            testCase.verifyTrue(any(startsWith(names_before, "snp")));

            ctx2 = femtogds.core.GeometrySession.with_shared_comsol(enable_gds=true, snap_mode="off", ...
                emit_on_create=false, reset_model=true);
            names_after = TestComsolBackend.paramNames(ctx2.comsol.model);
            testCase.verifyFalse(any(startsWith(names_after, "snp")));
        end

        function emitArrayFeatures(testCase)
            % Verify COMSOL backend emits 1D/2D array features and params.
            ctx = femtogds.core.GeometrySession.with_shared_comsol( ...
                enable_gds=true, emit_on_create=false, snap_mode="off", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p_nx = femtogds.types.Parameter(4, "arr_nx", unit="");
            p_ny = femtogds.types.Parameter(3, "arr_ny", unit="");
            p_pitch_x = femtogds.types.Parameter(200, "arr_pitch_x");
            p_pitch_y = femtogds.types.Parameter(140, "arr_pitch_y");

            base = femtogds.primitives.Rectangle(ctx, center=[0 0], width=80, height=40, layer="m1", output=false);
            a1 = femtogds.ops.Array1D(ctx, base, ncopies=p_nx, delta=femtogds.types.Vertices([1, 0], p_pitch_x), ...
                layer="m1", output=false);
            a2 = femtogds.ops.Array2D(ctx, base, ncopies_x=p_nx, ncopies_y=p_ny, ...
                delta_x=femtogds.types.Vertices([1, 0], p_pitch_x), delta_y=femtogds.types.Vertices([0, 1], p_pitch_y), ...
                layer="m1", output=true);

            ctx.build_comsol();

            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(a1.id)));
            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(a2.id)));
            t1 = string(ctx.comsol_backend.feature_tags(int32(a1.id)));
            t2 = string(ctx.comsol_backend.feature_tags(int32(a2.id)));
            testCase.verifyTrue(startsWith(t1, "arr"));
            testCase.verifyTrue(startsWith(t2, "arr"));

            for nm = ["arr_nx", "arr_ny", "arr_pitch_x", "arr_pitch_y"]
                testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, string(nm)));
            end
            testCase.verifyTrue(isKey(ctx.comsol_backend.selection_tags, "wp1|metal1"));
        end

        function emitPolygonPrimitive(testCase)
            % Verify COMSOL backend emits femtogds.primitives.Polygon primitive and dependencies.
            ctx = femtogds.core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_mode="off", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p = femtogds.types.Parameter(30, "poly_pitch");
            poly = femtogds.primitives.Polygon(ctx, vertices=femtogds.types.Vertices([0 0; 4 0; 4 2; 0 2], p), ...
                layer="m1", output=true);
            ctx.build_comsol();

            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(poly.id)));
            tag = string(ctx.comsol_backend.feature_tags(int32(poly.id)));
            testCase.verifyTrue(startsWith(tag, "pol"));
            testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, "poly_pitch"));
            testCase.verifyTrue(isKey(ctx.comsol_backend.selection_tags, "wp1|metal1"));
        end

        function emitCircleAndEllipsePrimitives(testCase)
            % Verify COMSOL backend emits femtogds.primitives.Circle/femtogds.primitives.Ellipse primitives.
            ctx = femtogds.core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_mode="off", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p_r = femtogds.types.Parameter(25, "circ_r");
            p_a = femtogds.types.Parameter(40, "ell_a");
            p_b = femtogds.types.Parameter(18, "ell_b");
            p_rot = femtogds.types.Parameter(30, "ell_rot_deg", unit="");

            c = femtogds.primitives.Circle(ctx, center=[0 0], radius=p_r, layer="m1", output=false);
            e = femtogds.primitives.Ellipse(ctx, center=[80 0], a=p_a, b=p_b, angle=p_rot, ...
                layer="m1", output=true);
            ctx.build_comsol();

            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(c.id)));
            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(e.id)));
            c_tag = string(ctx.comsol_backend.feature_tags(int32(c.id)));
            e_tag = string(ctx.comsol_backend.feature_tags(int32(e.id)));
            testCase.verifyTrue(startsWith(c_tag, "cir"));
            testCase.verifyTrue(startsWith(e_tag, "ell"));

            for nm = ["circ_r", "ell_a", "ell_b", "ell_rot_deg"]
                testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, string(nm)));
            end
            testCase.verifyTrue(isKey(ctx.comsol_backend.selection_tags, "wp1|metal1"));
        end

        function emitCurveAndPointPrimitives(testCase)
            % Verify COMSOL backend emits point/curve primitives.
            ctx = femtogds.core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_mode="off", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p = femtogds.primitives.Point(ctx, p=[-10 -20; 30 40], marker_size=4, layer="m1", output=false);
            ls = femtogds.primitives.LineSegment(ctx, p1=[-20 0], p2=[20 10], width=6, ...
                layer="m1", output=false);
            ic = femtogds.primitives.InterpolationCurve(ctx, points=[0 0; 10 20; 20 0; 30 10], ...
                type="open", width=6, layer="m1", output=false);
            qb = femtogds.primitives.QuadraticBezier(ctx, p0=[40 0], p1=[50 30], p2=[70 10], ...
                npoints=64, width=6, layer="m1", output=false);
            cb = femtogds.primitives.CubicBezier(ctx, p0=[80 0], p1=[95 35], p2=[120 -20], p3=[140 10], ...
                npoints=96, width=6, layer="m1", output=false);
            ca = femtogds.primitives.CircularArc(ctx, center=[180 0], radius=25, ...
                start_angle=30, end_angle=230, npoints=96, width=6, ...
                layer="m1", output=false);
            pc = femtogds.primitives.ParametricCurve(ctx, coord={"20*cos(s)", "20*sin(s)"}, ...
                parname="s", parmin=0, parmax=2*pi, ...
                type="closed", npoints=96, layer="m1", output=true);

            ctx.build_comsol();

            nodes = {p, ls, ic, qb, cb, ca, pc};
            for i = 1:numel(nodes)
                testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(nodes{i}.id)));
            end
            testCase.verifyTrue(isKey(ctx.comsol_backend.selection_tags, "wp1|metal1"));
        end

        function emitThickenFeature(testCase)
            % Verify COMSOL backend emits femtogds.ops.Thicken feature.
            ctx = femtogds.core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_mode="off", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p_t = femtogds.types.Parameter(18, "thk_total");
            ls = femtogds.primitives.LineSegment(ctx, p1=[0 0], p2=[100 20], width=1, layer="m1", output=false);
            th = femtogds.ops.Thicken(ctx, ls, offset="symmetric", totalthick=p_t, ...
                ends="circular", convexcorner="fillet", keep=true, ...
                layer="m1", output=true);

            ctx.build_comsol();

            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(ls.id)));
            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(th.id)));
            th_tag = string(ctx.comsol_backend.feature_tags(int32(th.id)));
            testCase.verifyTrue(startsWith(th_tag, "thk"));
            testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, "thk_total"));
            testCase.verifyTrue(isKey(ctx.comsol_backend.selection_tags, "wp1|metal1"));
        end

        function emitChamferOffsetTangent(testCase)
            % Verify COMSOL backend emits femtogds.ops.Chamfer/femtogds.ops.Offset/femtogds.ops.Tangent.
            ctx = femtogds.core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_mode="off", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p_dist = femtogds.types.Parameter(4, "cha_dist");
            p_off = femtogds.types.Parameter(6, "off_dist");

            r = femtogds.primitives.Rectangle(ctx, center=[0 0], width=80, height=40, layer="m1", output=false);
            cha = femtogds.ops.Chamfer(ctx, r, dist=p_dist, points=[1 2 3 4], layer="m1", output=false);
            off = femtogds.ops.Offset(ctx, r, distance=p_off, convexcorner="fillet", ...
                layer="m1", output=false);

            c = femtogds.primitives.Circle(ctx, center=[140 0], radius=20, layer="m1", output=false);
            tan = femtogds.ops.Tangent(ctx, c, type="coord", coord=[180 10], edge_index=1, ...
                layer="m1", output=false);

            u = femtogds.ops.Union(ctx, {cha, off, tan}, layer="m1", output=true);

            ctx.build_comsol();

            nodes = {cha, off, tan, u};
            for i = 1:numel(nodes)
                testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(nodes{i}.id)));
            end
            cha_tag = string(ctx.comsol_backend.feature_tags(int32(cha.id)));
            off_tag = string(ctx.comsol_backend.feature_tags(int32(off.id)));
            tan_tag = string(ctx.comsol_backend.feature_tags(int32(tan.id)));
            u_tag = string(ctx.comsol_backend.feature_tags(int32(u.id)));
            testCase.verifyTrue(startsWith(cha_tag, "cha"));
            testCase.verifyTrue(startsWith(off_tag, "off"));
            testCase.verifyTrue(startsWith(tan_tag, "tan"));
            testCase.verifyTrue(startsWith(u_tag, "uni"));

            for nm = ["cha_dist", "off_dist"]
                testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, string(nm)));
            end
            testCase.verifyTrue(isKey(ctx.comsol_backend.selection_tags, "wp1|metal1"));
        end
    end

    methods (Static, Access=private)
        function tf = hasComsolApi()
            % Return true when femtogds.core.ComsolModeler can be instantiated.
            persistent cached
            if ~isempty(cached)
                tf = cached;
                return;
            end

            try
                m = femtogds.core.ComsolModeler.shared(reset=true);
                cached = ~isempty(m) && isvalid(m);
                femtogds.core.ComsolModeler.clear_shared();
            catch
                cached = false;
            end
            tf = cached;
        end

        function names = paramNames(model)
            % Read model parameter names as a string array.
            names = strings(0, 1);
            try
                names = string(model.param.varnames());
            catch
                try
                    names = string(model.param().varnames());
                catch
                end
            end
        end
    end
end



































