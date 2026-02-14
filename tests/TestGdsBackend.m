classdef TestGdsBackend < matlab.unittest.TestCase
    % Regression tests for GDS emission pipeline.
    methods (Test)
        function exportRectangle(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = TestGdsBackend.newContext();

            r = primitives.Rectangle(ctx, center=[0 0], width=100, height=50, layer="m1");

            outFile = fullfile(tempdir, "test_rect.gds");
            if isfile(outFile)
                delete(outFile);
            end
            ctx.export_gds(outFile);

            testCase.verifyTrue(isfile(outFile));
            backend = core.GdsBackend(ctx);
            reg = backend.region_for(r);
            testCase.verifyGreaterThan(double(reg.count()), 0);
        end

        function exportBooleanAndTransform(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = TestGdsBackend.newContext();

            r1 = primitives.Rectangle(ctx, center=[0 0], width=100, height=50, layer="m1");
            r2 = primitives.Rectangle(ctx, center=[20 0], width=30, height=30, layer="m1");

            u = ops.Union(ctx, {r1, r2});
            m = ops.Move(ctx, u, delta=[10 0]);

            outFile = fullfile(tempdir, "test_union_move.gds");
            if isfile(outFile)
                delete(outFile);
            end
            ctx.export_gds(outFile);

            testCase.verifyTrue(isfile(outFile));
            backend = core.GdsBackend(ctx);
            reg = backend.region_for(m);
            testCase.verifyGreaterThan(double(reg.count()), 0);
        end

        function exportFilletOnRectangle(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = TestGdsBackend.newContext();
            p_r = types.Parameter(10, "fillet_r");
            p_n = types.Parameter(8, "fillet_n", unit="");

            r = primitives.Rectangle(ctx, center=[0 0], width=140, height=90, layer="m1");
            f = ops.Fillet(ctx, r, radius=p_r, npoints=p_n, points=[1 2 3 4], layer="m1");

            outFile = fullfile(tempdir, "test_fillet.gds");
            if isfile(outFile)
                delete(outFile);
            end
            ctx.export_gds(outFile);

            testCase.verifyTrue(isfile(outFile));
            backend = core.GdsBackend(ctx);
            reg = backend.region_for(f);
            testCase.verifyGreaterThan(double(reg.count()), 0);
        end

        function rectangleCornerAndRotation(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = TestGdsBackend.newContext();
            r = primitives.Rectangle(ctx, base="corner", corner=[10 20], ...
                width=120, height=60, angle=35, layer="m1");
            backend = core.GdsBackend(ctx);
            reg = backend.region_for(r);

            testCase.verifyEqual(double(reg.count()), 1);
            it = reg.each_merged();
            p = py.next(it);
            testCase.verifyEqual(double(p.num_points()), 4);

            % Area is approximately preserved after integer snapping in GDS.
            expected_area = 120 * 60;
            testCase.verifyGreaterThan(double(reg.area()), 0.95 * expected_area);
            testCase.verifyLessThan(double(reg.area()), 1.05 * expected_area);
        end

        function circleAndEllipsePrimitives(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = TestGdsBackend.newContext();
            c = primitives.Circle(ctx, center=[0 0], radius=50, npoints=128, layer="m1");
            e = primitives.Ellipse(ctx, center=[200 0], a=80, b=40, angle=30, npoints=128, ...
                layer="m1");

            backend = core.GdsBackend(ctx);
            reg_c = backend.region_for(c);
            reg_e = backend.region_for(e);

            area_c_expected = pi * 50 * 50;
            area_e_expected = pi * 80 * 40;

            testCase.verifyEqual(double(reg_c.count()), 1);
            testCase.verifyEqual(double(reg_e.count()), 1);
            testCase.verifyGreaterThan(double(reg_c.area()), 0.95 * area_c_expected);
            testCase.verifyLessThan(double(reg_c.area()), 1.05 * area_c_expected);
            testCase.verifyGreaterThan(double(reg_e.area()), 0.95 * area_e_expected);
            testCase.verifyLessThan(double(reg_e.area()), 1.05 * area_e_expected);
        end

        function polygonPrimitive(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = TestGdsBackend.newContext();
            p = types.Parameter(25, "poly_pitch");
            poly = primitives.Polygon(ctx, vertices=types.Vertices([0 0; 2 0; 2 1; 0 1], p), ...
                layer="m1");
            backend = core.GdsBackend(ctx);
            reg = backend.region_for(poly);

            testCase.verifyEqual(double(reg.count()), 1);
            expected_area = 2 * 1 * (p.value^2);
            testCase.verifyEqual(double(reg.area()), expected_area);
        end

        function array1DAnd2D(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = TestGdsBackend.newContext();
            p_nx = types.Parameter(4, "arr_nx", unit="");
            p_ny = types.Parameter(3, "arr_ny", unit="");
            p_pitch_x = types.Parameter(220, "arr_pitch_x");
            p_pitch_y = types.Parameter(140, "arr_pitch_y");

            base = primitives.Rectangle(ctx, center=[0 0], width=100, height=50, layer="m1");
            arr1 = ops.Array1D(ctx, base, ncopies=p_nx, delta=types.Vertices([1, 0], p_pitch_x), ...
                layer="m1");
            arr2 = ops.Array2D(ctx, base, ncopies_x=p_nx, ncopies_y=p_ny, ...
                delta_x=types.Vertices([1, 0], p_pitch_x), delta_y=types.Vertices([0, 1], p_pitch_y), ...
                layer="m1");

            backend = core.GdsBackend(ctx);
            reg1 = backend.region_for(arr1);
            reg2 = backend.region_for(arr2);
            base_area = 100 * 50;

            testCase.verifyEqual(double(reg1.area()), p_nx.value * base_area);
            testCase.verifyEqual(double(reg2.area()), p_nx.value * p_ny.value * base_area);
        end

        function curveAndPointPrimitives(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = TestGdsBackend.newContext();

            pt = primitives.Point(ctx, p=[-260, -120], marker_size=6, layer="m1");
            ls = primitives.LineSegment(ctx, p1=[-220, -100], p2=[-120, -40], width=8, ...
                layer="m1");
            ic = primitives.InterpolationCurve(ctx, points=[-110 -20; -80 20; -30 -10; 20 35], ...
                type="open", width=8, layer="m1");
            qb = primitives.QuadraticBezier(ctx, p0=[40 -40], p1=[80 70], p2=[130 -20], ...
                type="open", npoints=80, width=8, layer="m1");
            cb = primitives.CubicBezier(ctx, p0=[150 -50], p1=[190 80], p2=[250 -70], p3=[290 20], ...
                type="open", npoints=96, width=8, layer="m1");
            ca = primitives.CircularArc(ctx, center=[360 0], radius=55, start_angle=30, end_angle=260, ...
                type="open", npoints=160, width=8, layer="m1");
            pc = primitives.ParametricCurve(ctx, coord={"40*cos(s)", "40*sin(s)"}, ...
                parname="s", parmin=0, parmax=2*pi, ...
                type="closed", npoints=128, layer="m1");

            outFile = fullfile(tempdir, "test_curves_points.gds");
            if isfile(outFile)
                delete(outFile);
            end
            ctx.export_gds(outFile);
            testCase.verifyTrue(isfile(outFile));

            backend = core.GdsBackend(ctx);
            nodes = {pt, ls, ic, qb, cb, ca, pc};
            for i = 1:numel(nodes)
                reg = backend.region_for(nodes{i});
                testCase.verifyGreaterThan(double(reg.count()), 0);
                testCase.verifyGreaterThan(double(reg.area()), 0);
            end
        end

        function thickenFeature(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = TestGdsBackend.newContext();

            ls = primitives.LineSegment(ctx, p1=[0 0], p2=[200 0], width=1, layer="m1");
            th1 = ops.Thicken(ctx, ls, ...
                offset="symmetric", totalthick=30, ends="circular", convexcorner="fillet", ...
                layer="m1");

            ic = primitives.InterpolationCurve(ctx, points=[0 0; 60 40; 120 -30; 200 30], ...
                type="open", width=1, layer="m1");
            th2 = ops.Thicken(ctx, ic, ...
                offset="asymmetric", upthick=22, downthick=8, ...
                ends="straight", convexcorner="extend", ...
                layer="m1");

            r = primitives.Rectangle(ctx, center=[320 0], width=120, height=80, layer="m1");
            th3 = ops.Thicken(ctx, r, offset="symmetric", totalthick=20, layer="m1");

            outFile = fullfile(tempdir, "test_thicken.gds");
            if isfile(outFile)
                delete(outFile);
            end
            ctx.export_gds(outFile);
            testCase.verifyTrue(isfile(outFile));

            backend = core.GdsBackend(ctx);
            reg_ls = backend.region_for(ls);
            reg_th1 = backend.region_for(th1);
            reg_th2 = backend.region_for(th2);
            reg_r = backend.region_for(r);
            reg_th3 = backend.region_for(th3);

            testCase.verifyGreaterThan(double(reg_th1.area()), double(reg_ls.area()));
            testCase.verifyGreaterThan(double(reg_th2.area()), 0);
            testCase.verifyGreaterThan(double(reg_th3.area()), double(reg_r.area()));
        end

        function chamferOffsetTangent(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = TestGdsBackend.newContext();

            base = primitives.Rectangle(ctx, center=[0 0], width=120, height=80, layer="m1");
            cha = ops.Chamfer(ctx, base, dist=12, points=[1 2 3 4], layer="m1");
            p_off_seed = types.Parameter(7, "off_seed");
            p_off_dist = types.Parameter(@(x) x + 3, p_off_seed, "off_dist");
            off = ops.Offset(ctx, base, distance=p_off_dist, reverse=false, convexcorner="fillet", ...
                trim=true, layer="m1");

            c = primitives.Circle(ctx, center=[220 0], radius=45, npoints=128, layer="m1");
            tan = ops.Tangent(ctx, c, type="coord", coord=[320 20], start=0.75, ...
                width=8, layer="m1");

            outFile = fullfile(tempdir, "test_chamfer_offset_tangent.gds");
            if isfile(outFile)
                delete(outFile);
            end
            ctx.export_gds(outFile);
            testCase.verifyTrue(isfile(outFile));

            backend = core.GdsBackend(ctx);
            reg_base = backend.region_for(base);
            reg_cha = backend.region_for(cha);
            reg_off = backend.region_for(off);
            reg_tan = backend.region_for(tan);
            testCase.verifyGreaterThan(double(reg_cha.area()), 0);
            testCase.verifyLessThanOrEqual(double(reg_cha.area()), double(reg_base.area()));
            testCase.verifyGreaterThan(double(reg_off.area()), double(reg_base.area()));
            testCase.verifyEqual(p_off_dist.value, 10);
            testCase.verifyEqual(string(p_off_dist.expr), "off_seed+3");
            testCase.verifyGreaterThan(double(reg_tan.area()), 0);
        end

        function parameterArithmeticLeftRightDivisionAndPower(testCase)
            p = types.Parameter(5, "p", unit="");
            q = types.Parameter(2, "q", unit="");

            y1 = p * 3;
            y2 = 3 * p;
            y3 = p * q;
            y4 = p / 2;
            y5 = 10 / p;
            y6 = p \ 10;
            y7 = 10 \ p;
            y8 = p / q;
            y9 = p \ q;
            y10 = p ^ 2;
            y11 = 2 ^ q;
            y12 = p ^ q;

            vals = [y1.value, y2.value, y3.value, y4.value, y5.value, y6.value, ...
                y7.value, y8.value, y9.value, y10.value, y11.value, y12.value];
            expected = [15, 15, 10, 2.5, 2, 2, 0.5, 2.5, 0.4, 25, 4, 25];
            testCase.verifyEqual(vals, expected, AbsTol=1e-12);

            testCase.verifyEqual(string(y2.expr), "(3)*(p)");
            testCase.verifyEqual(string(y5.expr), "(10)/(p)");
            testCase.verifyEqual(string(y6.expr), "(10)/(p)");
            testCase.verifyEqual(string(y7.expr), "(p)/(10)");
            testCase.verifyEqual(string(y10.expr), "(p)^(2)");
            testCase.verifyEqual(string(y11.expr), "(2)^(q)");
            testCase.verifyEqual(string(y12.expr), "(p)^(q)");
        end

        function parameterDirectSinShowsHelpfulError(testCase)
            p = types.Parameter(2, "p", unit="");
            testCase.verifyError(@() sin(p), "Parameter:UnsupportedFunction");
            try
                sin(p);
                testCase.verifyFail("Expected Parameter:UnsupportedFunction.");
            catch err
                testCase.verifyEqual(string(err.identifier), "Parameter:UnsupportedFunction");
                testCase.verifyTrue(contains(string(err.message), "function-based Parameter"));
            end
        end

        function parameterConstructorSupportsNameKeyword(testCase)
            p_num = types.Parameter(8, "num", unit="", auto_register=false);
            p_den = types.Parameter(10, "den", unit="", auto_register=false);
            dummy = types.Parameter(p_num / p_den, name="dummy_ratio", unit="", auto_register=false);

            testCase.verifyEqual(string(dummy.name), "dummy_ratio");
            testCase.verifyEqual(dummy.value, 0.8, AbsTol=1e-12);
            testCase.verifyEqual(string(dummy.expr), "(num)/(den)");
        end

        function gdsResolutionControlsLayoutDbu(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = core.GeometrySession(enable_comsol=false, enable_gds=true, ...
                snap_mode="off", gds_resolution_nm=5);
            testCase.verifyEqual(double(ctx.gds.pylayout.dbu), 0.005, AbsTol=1e-12);
        end

        function gdsIntegerUsesResolutionWhenSnapOff(testCase)
            ctx = core.GeometrySession(enable_comsol=false, enable_gds=false, ...
                snap_mode="off", gds_resolution_nm=2);
            ints = ctx.gds_integer([1, 3, 5], "resolution-test");
            testCase.verifyEqual(ints, [1, 2, 3]);
        end
    end

    methods (Static, Access=private)
        function ctx = newContext()
            % Build a standard GDS-only context used by all tests.
            ctx = core.GeometrySession(enable_comsol=false, enable_gds=true, snap_mode="off");
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");
        end

        function tf = hasKLayout()
            % Return true when KLayout Python bindings are available.
            persistent cached
            if ~isempty(cached)
                tf = cached;
                return;
            end
            try
                try
                    pyenv;
                catch
                    % Older MATLAB versions may not have pyenv.
                end
                try
                    py.importlib.import_module('pya');
                    cached = true;
                catch
                    try
                        py.importlib.import_module('klayout.db');
                        cached = true;
                    catch
                        mod = py.importlib.import_module('lygadgets');
                        cached = logical(py.hasattr(mod, 'pya')) && ~isa(mod.pya, 'py.NoneType');
                    end
                end
            catch
                cached = false;
            end
            tf = cached;
        end
    end
end





























