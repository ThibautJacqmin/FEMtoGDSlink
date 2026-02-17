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
            core.GeometrySession.clear_shared_comsol();
            core.GeometrySession.set_current([]);
        end
    end

    methods (Test)
        function emitGeometryGraphRegistersParametersAndSelections(testCase)
            % Verify emitted features, named parameters, and layer selections.
            ctx = core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_on_grid=false, ...
                comsol_api="livelink", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p_pitch = types.Parameter(40, "pitch_y");
            p_w0 = types.Parameter(120, "tower_w0");
            p_dw = types.Parameter(20, "tower_dw");
            p_h = types.Parameter(60, "tower_h");
            p_rot = types.Parameter(7, "tower_rot_deg", unit="");
            p_rect_rot = types.Parameter(18, "rect_rot_deg", unit="");
            p_scale = types.Parameter(0.95, "tower_scale", unit="");
            p_move = types.Parameter(10, "tower_move_unit");
            p_rad = types.Parameter(6, "fillet_r");
            p_n = types.Parameter(@(x) max(8, round(2*x)), p_rad, "fillet_n", unit="");

            r1 = primitives.Rectangle(ctx, center=types.Vertices([0, 0], p_pitch), ...
                width=p_w0 - p_dw, height=p_h, layer="m1");
            r2 = primitives.Rectangle(ctx, base="corner", corner=[5, -10], ...
                width=30, height=20, angle=p_rect_rot, layer="m1");
            u = ops.Union(ctx, {r1, r2}, layer="m1");
            d = ops.Difference(ctx, u, {r2}, layer="m1");
            m = ops.Move(ctx, d, delta=types.Vertices([1, 0], p_move));
            ro = ops.Rotate(ctx, m, angle=p_rot, origin=types.Vertices([0, 0], p_pitch));
            sc = ops.Scale(ctx, ro, factor=p_scale, origin=types.Vertices([0, 0], p_pitch));
            mi = ops.Mirror(ctx, sc, point=types.Vertices([0, 0], p_pitch), axis=[1, 0]);
            i = ops.Intersection(ctx, {mi, r1}, layer="m1");
            f = ops.Fillet(ctx, i, radius=p_rad, npoints=p_n, points=[1 2 3 4], ...
                layer="m1");

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

        function emitFilletAllPointsOnComposite(testCase)
            % Verify fillet points="all" works on non-rectangle composite input.
            ctx = core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_on_grid=false, ...
                comsol_api="livelink", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p_rad = types.Parameter(4, "fil_all_r");
            p_n = types.Parameter(12, "fil_all_n", unit="");

            r1 = primitives.Rectangle(ctx, center=[0 0], width=120, height=70, layer="m1");
            r2 = primitives.Rectangle(ctx, center=[35 0], width=120, height=70, layer="m1");
            composite = ops.Union(ctx, {r1, r2}, layer="m1");
            fil = ops.Fillet(ctx, composite, radius=p_rad, npoints=p_n, points="all", ...
                layer="m1");

            ctx.build_comsol();

            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(composite.id)));
            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(fil.id)));
            fil_tag = string(ctx.comsol_backend.feature_tags(int32(fil.id)));
            testCase.verifyTrue(startsWith(fil_tag, "fil"));
        end

        function keepInputObjectsSemanticsBuilds(testCase)
            % Verify keep_input_objects=false/true options both emit and build on branched graphs.
            ctx = core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_on_grid=false, ...
                comsol_api="livelink", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            r = primitives.Rectangle(ctx, center=[0 0], width=120, height=70, layer="m1");
            m_consume = ops.Move(ctx, r, delta=[30 0], keep_input_objects=false, layer="m1");
            u_consume = ops.Union(ctx, {r, m_consume}, keep_input_objects=false, layer="m1");

            r2 = primitives.Rectangle(ctx, center=[220 0], width=100, height=60, layer="m1");
            m_keep = ops.Move(ctx, r2, delta=[20 0], keep_input_objects=true, layer="m1");
            u_keep = ops.Union(ctx, {r2, m_keep}, keep_input_objects=true, layer="m1");

            out = ops.Union(ctx, {u_consume, u_keep}, keep_input_objects=false, layer="m1");
            ctx.build_comsol();

            nodes = {r, m_consume, u_consume, r2, m_keep, u_keep, out};
            for i = 1:numel(nodes)
                testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(nodes{i}.id)));
            end
        end

        function sharedModelerIsReusedAcrossSessions(testCase)
            % Verify with_shared_comsol reuses the same COMSOL model instance.
            core.GeometrySession.clear_shared_comsol();
            ctx1 = core.GeometrySession.with_shared_comsol(enable_gds=false, ...
                snap_on_grid=false, comsol_api="livelink", ...
                reset_model=true, clean_on_reset=false);
            tag1 = string(ctx1.comsol.model_tag);

            ctx2 = core.GeometrySession.with_shared_comsol(enable_gds=false, ...
                snap_on_grid=false, comsol_api="livelink", ...
                reset_model=true, clean_on_reset=false);
            tag2 = string(ctx2.comsol.model_tag);

            testCase.verifyEqual(tag2, tag1);
            testCase.verifyTrue(isequal(ctx1.comsol, ctx2.comsol));
        end

        function clearSharedCreatesNewModel(testCase)
            % Verify clearing shared COMSOL forces creation of a new model tag.
            core.GeometrySession.clear_shared_comsol();
            ctx1 = core.GeometrySession.with_shared_comsol(enable_gds=false, ...
                snap_on_grid=false, comsol_api="livelink", reset_model=true);
            tag1 = string(ctx1.comsol.model_tag);

            core.GeometrySession.clear_shared_comsol();
            ctx2 = core.GeometrySession.with_shared_comsol(enable_gds=false, ...
                snap_on_grid=false, comsol_api="livelink", reset_model=true);
            tag2 = string(ctx2.comsol.model_tag);

            testCase.verifyNotEqual(tag1, tag2);
        end

        function resetWorkspaceClearsSnappedParameters(testCase)
            % Verify shared reset clears old snp* parameters.
            ctx1 = core.GeometrySession.with_shared_comsol(enable_gds=true, ...
                snap_on_grid=true, comsol_api="livelink", ...
                emit_on_create=false, reset_model=true);
            ctx1.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");

            p_w = types.Parameter(120, "w");
            p_h = types.Parameter(60, "h");
            r = primitives.Rectangle(ctx1, center=[0 0], width=p_w, height=p_h, layer="m1"); %#ok<NASGU>
            ctx1.build_comsol();

            names_before = TestComsolBackend.paramNames(ctx1.comsol.model);
            testCase.verifyTrue(any(startsWith(names_before, "snp")));

            ctx2 = core.GeometrySession.with_shared_comsol(enable_gds=true, ...
                snap_on_grid=false, comsol_api="livelink", ...
                emit_on_create=false, reset_model=true);
            names_after = TestComsolBackend.paramNames(ctx2.comsol.model);
            testCase.verifyFalse(any(startsWith(names_after, "snp")));
        end

        function emitArrayFeatures(testCase)
            % Verify COMSOL backend emits 1D/2D array features and params.
            ctx = core.GeometrySession.with_shared_comsol( ...
                enable_gds=true, emit_on_create=false, snap_on_grid=false, ...
                comsol_api="livelink", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p_nx = types.Parameter(4, "arr_nx", unit="");
            p_ny = types.Parameter(3, "arr_ny", unit="");
            p_pitch_x = types.Parameter(200, "arr_pitch_x");
            p_pitch_y = types.Parameter(140, "arr_pitch_y");

            base = primitives.Rectangle(ctx, center=[0 0], width=80, height=40, layer="m1");
            a1 = ops.Array1D(ctx, base, ncopies=p_nx, delta=types.Vertices([1, 0], p_pitch_x), ...
                layer="m1");
            a2 = ops.Array2D(ctx, base, ncopies_x=p_nx, ncopies_y=p_ny, ...
                delta_x=types.Vertices([1, 0], p_pitch_x), delta_y=types.Vertices([0, 1], p_pitch_y), ...
                layer="m1");

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
            % Verify COMSOL backend emits primitives.Polygon primitive and dependencies.
            ctx = core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_on_grid=false, ...
                comsol_api="livelink", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p = types.Parameter(30, "poly_pitch");
            poly = primitives.Polygon(ctx, vertices=types.Vertices([0 0; 4 0; 4 2; 0 2], p), ...
                layer="m1");
            ctx.build_comsol();

            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(poly.id)));
            tag = string(ctx.comsol_backend.feature_tags(int32(poly.id)));
            testCase.verifyTrue(startsWith(tag, "pol"));
            testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, "poly_pitch"));
            testCase.verifyTrue(isKey(ctx.comsol_backend.selection_tags, "wp1|metal1"));
        end

        function emitCircleAndEllipsePrimitives(testCase)
            % Verify COMSOL backend emits primitives.Circle/primitives.Ellipse primitives.
            ctx = core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_on_grid=false, ...
                comsol_api="livelink", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p_r = types.Parameter(25, "circ_r");
            p_a = types.Parameter(40, "ell_a");
            p_b = types.Parameter(18, "ell_b");
            p_rot = types.Parameter(30, "ell_rot_deg", unit="");

            c = primitives.Circle(ctx, center=[0 0], radius=p_r, layer="m1");
            e = primitives.Ellipse(ctx, center=[80 0], a=p_a, b=p_b, angle=p_rot, ...
                layer="m1");
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

        function emitSquarePrimitive(testCase)
            % Verify COMSOL backend emits primitives.Square primitive.
            ctx = core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_on_grid=false, ...
                comsol_api="livelink", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p_side = types.Parameter(34, "sq_side");
            s = primitives.Square(ctx, base="corner", corner=[20 -10], ...
                side=p_side, angle=15, layer="m1");
            ctx.build_comsol();

            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(s.id)));
            s_tag = string(ctx.comsol_backend.feature_tags(int32(s.id)));
            testCase.verifyTrue(startsWith(s_tag, "squ"));
            testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, "sq_side"));
            testCase.verifyEqual(s.width.value, p_side.value);
            testCase.verifyEqual(s.height.value, p_side.value);
            testCase.verifyTrue(isKey(ctx.comsol_backend.selection_tags, "wp1|metal1"));
        end

        function emitCurveAndPointPrimitives(testCase)
            % Verify COMSOL backend emits point/curve primitives.
            ctx = core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_on_grid=false, ...
                comsol_api="livelink", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p = primitives.Point(ctx, p=[-10 -20; 30 40], marker_size=4, layer="m1");
            ls = primitives.LineSegment(ctx, p1=[-20 0], p2=[20 10], width=6, ...
                layer="m1");
            ic = primitives.InterpolationCurve(ctx, points=[0 0; 10 20; 20 0; 30 10], ...
                type="open", width=6, layer="m1");
            qb = primitives.QuadraticBezier(ctx, p0=[40 0], p1=[50 30], p2=[70 10], ...
                npoints=64, width=6, layer="m1");
            cb = primitives.CubicBezier(ctx, p0=[80 0], p1=[95 35], p2=[120 -20], p3=[140 10], ...
                npoints=96, width=6, layer="m1");
            ca = primitives.CircularArc(ctx, center=[180 0], radius=25, ...
                start_angle=30, end_angle=230, npoints=96, width=6, ...
                layer="m1");
            pc = primitives.ParametricCurve(ctx, coord={"20*cos(s)", "20*sin(s)"}, ...
                parname="s", parmin=0, parmax=2*pi, ...
                type="closed", npoints=96, layer="m1");

            ctx.build_comsol();

            nodes = {p, ls, ic, qb, cb, ca, pc};
            for i = 1:numel(nodes)
                testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(nodes{i}.id)));
            end
            testCase.verifyTrue(isKey(ctx.comsol_backend.selection_tags, "wp1|metal1"));
        end

        function emitThickenFeature(testCase)
            % Verify COMSOL backend emits ops.Thicken feature.
            ctx = core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_on_grid=false, ...
                comsol_api="livelink", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p_t = types.Parameter(18, "thk_total");
            ls = primitives.LineSegment(ctx, p1=[0 0], p2=[100 20], width=1, layer="m1");
            th = ops.Thicken(ctx, ls, offset="symmetric", totalthick=p_t, ...
                ends="circular", convexcorner="fillet", keep_input_objects=true, ...
                layer="m1");

            ctx.build_comsol();

            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(ls.id)));
            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(th.id)));
            th_tag = string(ctx.comsol_backend.feature_tags(int32(th.id)));
            testCase.verifyTrue(startsWith(th_tag, "thk"));
            testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, "thk_total"));
            testCase.verifyTrue(isKey(ctx.comsol_backend.selection_tags, "wp1|metal1"));
        end

        function emitChamferOffsetTangent(testCase)
            % Verify COMSOL backend emits ops.Chamfer/ops.Offset/ops.Tangent.
            ctx = core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_on_grid=false, ...
                comsol_api="livelink", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p_dist = types.Parameter(4, "cha_dist");
            p_off = types.Parameter(6, "off_dist");

            r = primitives.Rectangle(ctx, center=[0 0], width=80, height=40, layer="m1");
            cha = ops.Chamfer(ctx, r, dist=p_dist, points=[1 2 3 4], layer="m1");
            off = ops.Offset(ctx, r, distance=p_off, convexcorner="fillet", ...
                layer="m1");

            c = primitives.Circle(ctx, center=[140 0], radius=20, layer="m1");
            tan = ops.Tangent(ctx, c, type="coord", coord=[180 10], edge_index=1, ...
                layer="m1");

            u = ops.Union(ctx, {cha, off, tan}, layer="m1");

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

        function registerStandaloneParameter(testCase)
            % Verify standalone Parameter expressions can be registered without ctx.comsol calls.
            ctx = core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_on_grid=false, ...
                comsol_api="livelink", reset_model=true);

            p_num = types.Parameter(8, "line_thk");
            p_den = types.Parameter(10, "off_dist");
            dummy = ctx.register_parameter(p_num / p_den, name="dummy_ratio", unit="");

            testCase.verifyEqual(string(dummy.name), "dummy_ratio");
            testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, "line_thk"));
            testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, "off_dist"));
            testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, "dummy_ratio"));
        end

        function constructorNamedParameterAutoRegisters(testCase)
            % Verify named Parameter(source, name=...) auto-registers in current COMSOL session.
            ctx = core.GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_on_grid=false, ...
                comsol_api="livelink", reset_model=true);

            p_num = types.Parameter(8, "line_thk");
            p_den = types.Parameter(10, "off_dist");
            dummy = types.Parameter(p_num / p_den, name="dummy_ratio", unit="");

            testCase.verifyEqual(string(dummy.name), "dummy_ratio");
            testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, "line_thk"));
            testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, "off_dist"));
            testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, "dummy_ratio"));
        end
    end

    methods (Static, Access=private)
        function tf = hasComsolApi()
            % Return true when LiveLink prerequisites/server are reachable.
            persistent cached
            if ~isempty(cached)
                tf = cached;
                return;
            end

            host = TestComsolBackend.comsolHost();
            port = TestComsolBackend.comsolPort();
            if ~TestComsolBackend.canReachServer(host, port, 250)
                cached = false;
                tf = cached;
                return;
            end

            try
                core.ComsolLivelinkModeler.ensure_ready( ...
                    host=host, port=port, connect=false);
                cached = true;
            catch
                cached = false;
            end
            tf = cached;
        end

        function host = comsolHost()
            % Resolve COMSOL host from environment or default.
            host = string(getenv("FEMTOGDS_COMSOL_HOST"));
            if strlength(host) == 0
                host = "localhost";
            end
        end

        function port = comsolPort()
            % Resolve COMSOL port from environment or default.
            token = string(getenv("FEMTOGDS_COMSOL_PORT"));
            val = str2double(token);
            if ~(isscalar(val) && isfinite(val) && val > 0)
                port = 2036;
            else
                port = double(val);
            end
        end

        function tf = canReachServer(host, port, timeout_ms)
            % Fast TCP probe to avoid long blocking COMSOL bootstrap calls.
            tf = false;
            try
                s = javaObject("java.net.Socket");
                c = onCleanup(@() TestComsolBackend.safeCloseSocket(s));
                addr = javaObject("java.net.InetSocketAddress", char(host), int32(port));
                s.connect(addr, int32(timeout_ms));
                tf = true;
            catch
            end
            clear c
        end

        function safeCloseSocket(s)
            % Close Java socket best-effort.
            try
                s.close();
            catch
            end
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



































