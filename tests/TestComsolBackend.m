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
            GeometrySession.clear_shared_comsol();
            GeometrySession.set_current([]);
        end
    end

    methods (Test)
        function emitGeometryGraphRegistersParametersAndSelections(testCase)
            % Verify emitted features, named parameters, and layer selections.
            ctx = GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_mode="off", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p_pitch = Parameter(40, "pitch_y");
            p_w0 = Parameter(120, "tower_w0");
            p_dw = Parameter(20, "tower_dw");
            p_h = Parameter(60, "tower_h");
            p_rot = Parameter(7, "tower_rot_deg", unit="");
            p_rect_rot = Parameter(18, "rect_rot_deg", unit="");
            p_scale = Parameter(0.95, "tower_scale", unit="");
            p_move = Parameter(10, "tower_move_unit");
            p_rad = Parameter(6, "fillet_r");
            p_n = DependentParameter(@(x) max(8, round(2*x)), p_rad, "fillet_n", unit="");

            r1 = Rectangle(ctx, center=Vertices([0, 0], p_pitch), ...
                width=p_w0 - p_dw, height=p_h, layer="m1", output=false);
            r2 = Rectangle(ctx, base="corner", corner=[5, -10], ...
                width=30, height=20, angle=p_rect_rot, layer="m1", output=false);
            u = Union(ctx, {r1, r2}, layer="m1", output=false);
            d = Difference(ctx, u, {r2}, layer="m1", output=false);
            m = Move(ctx, d, delta=Vertices([1, 0], p_move), output=false);
            ro = Rotate(ctx, m, angle=p_rot, origin=Vertices([0, 0], p_pitch), output=false);
            sc = Scale(ctx, ro, factor=p_scale, origin=Vertices([0, 0], p_pitch), output=false);
            mi = Mirror(ctx, sc, point=Vertices([0, 0], p_pitch), axis=[1, 0], output=false);
            i = Intersection(ctx, {mi, r1}, layer="m1", output=false);
            f = Fillet(ctx, i, radius=p_rad, npoints=p_n, points=[1 2 3 4], ...
                layer="m1", output=true);

            ctx.build_comsol();

            nodes = {r1, r2, u, d, m, ro, sc, mi, i, f};
            for k = 1:numel(nodes)
                testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(nodes{k}.id)));
            end

            expected = ["pitch_y", "tower_w0", "tower_dw", "tower_h", ...
                "tower_rot_deg", "rect_rot_deg", "tower_scale", "tower_move_unit", "fillet_r"];
            for k = 1:numel(expected)
                testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, char(expected(k))));
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
            GeometrySession.clear_shared_comsol();
            ctx1 = GeometrySession.with_shared_comsol(enable_gds=false, snap_mode="off", ...
                reset_model=true);
            tag1 = string(ctx1.comsol.model_tag);

            ctx2 = GeometrySession.with_shared_comsol(enable_gds=false, snap_mode="off", ...
                reset_model=true);
            tag2 = string(ctx2.comsol.model_tag);

            testCase.verifyEqual(tag2, tag1);
            testCase.verifyTrue(isequal(ctx1.comsol, ctx2.comsol));
        end

        function clearSharedCreatesNewModel(testCase)
            % Verify clearing shared COMSOL forces creation of a new model tag.
            GeometrySession.clear_shared_comsol();
            ctx1 = GeometrySession.with_shared_comsol(enable_gds=false, snap_mode="off", ...
                reset_model=true);
            tag1 = string(ctx1.comsol.model_tag);

            GeometrySession.clear_shared_comsol();
            ctx2 = GeometrySession.with_shared_comsol(enable_gds=false, snap_mode="off", ...
                reset_model=true);
            tag2 = string(ctx2.comsol.model_tag);

            testCase.verifyNotEqual(tag1, tag2);
        end

        function resetWorkspaceClearsSnappedParameters(testCase)
            % Verify shared reset clears old snp* parameters.
            ctx1 = GeometrySession.with_shared_comsol(enable_gds=true, snap_mode="strict", ...
                emit_on_create=false, reset_model=true);
            ctx1.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");

            p_w = Parameter(120, "w");
            p_h = Parameter(60, "h");
            r = Rectangle(ctx1, center=[0 0], width=p_w, height=p_h, layer="m1", output=true); %#ok<NASGU>
            ctx1.build_comsol();

            names_before = TestComsolBackend.paramNames(ctx1.comsol.model);
            testCase.verifyTrue(any(startsWith(names_before, "snp")));

            ctx2 = GeometrySession.with_shared_comsol(enable_gds=true, snap_mode="off", ...
                emit_on_create=false, reset_model=true);
            names_after = TestComsolBackend.paramNames(ctx2.comsol.model);
            testCase.verifyFalse(any(startsWith(names_after, "snp")));
        end

        function emitArrayFeatures(testCase)
            % Verify COMSOL backend emits 1D/2D array features and params.
            ctx = GeometrySession.with_shared_comsol( ...
                enable_gds=true, emit_on_create=false, snap_mode="off", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p_nx = Parameter(4, "arr_nx", unit="");
            p_ny = Parameter(3, "arr_ny", unit="");
            p_pitch_x = Parameter(200, "arr_pitch_x");
            p_pitch_y = Parameter(140, "arr_pitch_y");

            base = Rectangle(ctx, center=[0 0], width=80, height=40, layer="m1", output=false);
            a1 = Array1D(ctx, base, ncopies=p_nx, delta=Vertices([1, 0], p_pitch_x), ...
                layer="m1", output=false);
            a2 = Array2D(ctx, base, ncopies_x=p_nx, ncopies_y=p_ny, ...
                delta_x=Vertices([1, 0], p_pitch_x), delta_y=Vertices([0, 1], p_pitch_y), ...
                layer="m1", output=true);

            ctx.build_comsol();

            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(a1.id)));
            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(a2.id)));
            t1 = string(ctx.comsol_backend.feature_tags(int32(a1.id)));
            t2 = string(ctx.comsol_backend.feature_tags(int32(a2.id)));
            testCase.verifyTrue(startsWith(t1, "arr"));
            testCase.verifyTrue(startsWith(t2, "arr"));

            for nm = ["arr_nx", "arr_ny", "arr_pitch_x", "arr_pitch_y"]
                testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, char(nm)));
            end
            testCase.verifyTrue(isKey(ctx.comsol_backend.selection_tags, "wp1|metal1"));
        end

        function emitPolygonPrimitive(testCase)
            % Verify COMSOL backend emits Polygon primitive and dependencies.
            ctx = GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_mode="off", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p = Parameter(30, "poly_pitch");
            poly = Polygon(ctx, vertices=Vertices([0 0; 4 0; 4 2; 0 2], p), ...
                layer="m1", output=true);
            ctx.build_comsol();

            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(poly.id)));
            tag = string(ctx.comsol_backend.feature_tags(int32(poly.id)));
            testCase.verifyTrue(startsWith(tag, "pol"));
            testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, "poly_pitch"));
            testCase.verifyTrue(isKey(ctx.comsol_backend.selection_tags, "wp1|metal1"));
        end

        function emitCircleAndEllipsePrimitives(testCase)
            % Verify COMSOL backend emits Circle/Ellipse primitives.
            ctx = GeometrySession.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, snap_mode="off", reset_model=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
                comsol_selection="metal1", comsol_selection_state="all");

            p_r = Parameter(25, "circ_r");
            p_a = Parameter(40, "ell_a");
            p_b = Parameter(18, "ell_b");
            p_rot = Parameter(30, "ell_rot_deg", unit="");

            c = Circle(ctx, center=[0 0], radius=p_r, layer="m1", output=false);
            e = Ellipse(ctx, center=[80 0], a=p_a, b=p_b, angle=p_rot, ...
                layer="m1", output=true);
            ctx.build_comsol();

            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(c.id)));
            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(e.id)));
            c_tag = string(ctx.comsol_backend.feature_tags(int32(c.id)));
            e_tag = string(ctx.comsol_backend.feature_tags(int32(e.id)));
            testCase.verifyTrue(startsWith(c_tag, "cir"));
            testCase.verifyTrue(startsWith(e_tag, "ell"));

            for nm = ["circ_r", "ell_a", "ell_b", "ell_rot_deg"]
                testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, char(nm)));
            end
            testCase.verifyTrue(isKey(ctx.comsol_backend.selection_tags, "wp1|metal1"));
        end
    end

    methods (Static, Access=private)
        function tf = hasComsolApi()
            % Return true when ComsolModeler can be instantiated.
            persistent cached
            if ~isempty(cached)
                tf = cached;
                return;
            end

            try
                m = ComsolModeler.shared(reset=true);
                cached = ~isempty(m) && isvalid(m);
                ComsolModeler.clear_shared();
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
