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
