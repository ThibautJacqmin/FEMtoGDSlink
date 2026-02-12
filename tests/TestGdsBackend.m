classdef TestGdsBackend < matlab.unittest.TestCase
    % Regression tests for GDS emission pipeline.
    methods (Test)
        function exportRectangle(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = TestGdsBackend.newContext();

            r = Rectangle(ctx, center=[0 0], width=100, height=50, layer="m1");
            r.output = true;

            outFile = fullfile(tempdir, "test_rect.gds");
            if isfile(outFile)
                delete(outFile);
            end
            ctx.export_gds(outFile);

            testCase.verifyTrue(isfile(outFile));
            backend = GdsBackend(ctx);
            reg = backend.region_for(r);
            testCase.verifyGreaterThan(double(reg.count()), 0);
        end

        function exportBooleanAndTransform(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = TestGdsBackend.newContext();

            r1 = Rectangle(ctx, center=[0 0], width=100, height=50, layer="m1");
            r2 = Rectangle(ctx, center=[20 0], width=30, height=30, layer="m1");
            r1.output = false;
            r2.output = false;

            u = Union(ctx, {r1, r2}, output=true);
            m = Move(ctx, u, delta=[10 0], output=true);

            outFile = fullfile(tempdir, "test_union_move.gds");
            if isfile(outFile)
                delete(outFile);
            end
            ctx.export_gds(outFile);

            testCase.verifyTrue(isfile(outFile));
            backend = GdsBackend(ctx);
            reg = backend.region_for(m);
            testCase.verifyGreaterThan(double(reg.count()), 0);
        end

        function exportFilletOnRectangle(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = TestGdsBackend.newContext();
            p_r = Parameter(10, "fillet_r");
            p_n = Parameter(8, "fillet_n", unit="");

            r = Rectangle(ctx, center=[0 0], width=140, height=90, layer="m1", output=false);
            f = Fillet(ctx, r, radius=p_r, npoints=p_n, points=[1 2 3 4], layer="m1", output=true);

            outFile = fullfile(tempdir, "test_fillet.gds");
            if isfile(outFile)
                delete(outFile);
            end
            ctx.export_gds(outFile);

            testCase.verifyTrue(isfile(outFile));
            backend = GdsBackend(ctx);
            reg = backend.region_for(f);
            testCase.verifyGreaterThan(double(reg.count()), 0);
        end

        function rectangleCornerAndRotation(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = TestGdsBackend.newContext();
            r = Rectangle(ctx, base="corner", corner=[10 20], ...
                width=120, height=60, angle=35, layer="m1", output=true);
            backend = GdsBackend(ctx);
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
            c = Circle(ctx, center=[0 0], radius=50, npoints=128, layer="m1", output=false);
            e = Ellipse(ctx, center=[200 0], a=80, b=40, angle=30, npoints=128, ...
                layer="m1", output=true);

            backend = GdsBackend(ctx);
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
            p = Parameter(25, "poly_pitch");
            poly = Polygon(ctx, vertices=Vertices([0 0; 2 0; 2 1; 0 1], p), ...
                layer="m1", output=true);
            backend = GdsBackend(ctx);
            reg = backend.region_for(poly);

            testCase.verifyEqual(double(reg.count()), 1);
            expected_area = 2 * 1 * (p.value^2);
            testCase.verifyEqual(double(reg.area()), expected_area);
        end

        function array1DAnd2D(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = TestGdsBackend.newContext();
            p_nx = Parameter(4, "arr_nx", unit="");
            p_ny = Parameter(3, "arr_ny", unit="");
            p_pitch_x = Parameter(220, "arr_pitch_x");
            p_pitch_y = Parameter(140, "arr_pitch_y");

            base = Rectangle(ctx, center=[0 0], width=100, height=50, layer="m1", output=false);
            arr1 = Array1D(ctx, base, ncopies=p_nx, delta=Vertices([1, 0], p_pitch_x), ...
                layer="m1", output=false);
            arr2 = Array2D(ctx, base, ncopies_x=p_nx, ncopies_y=p_ny, ...
                delta_x=Vertices([1, 0], p_pitch_x), delta_y=Vertices([0, 1], p_pitch_y), ...
                layer="m1", output=true);

            backend = GdsBackend(ctx);
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

            pt = Point(ctx, p=[-260, -120], marker_size=6, layer="m1", output=true);
            ls = LineSegment(ctx, p1=[-220, -100], p2=[-120, -40], width=8, ...
                layer="m1", output=true);
            ic = InterpolationCurve(ctx, points=[-110 -20; -80 20; -30 -10; 20 35], ...
                type="open", width=8, layer="m1", output=true);
            qb = QuadraticBezier(ctx, p0=[40 -40], p1=[80 70], p2=[130 -20], ...
                type="open", npoints=80, width=8, layer="m1", output=true);
            cb = CubicBezier(ctx, p0=[150 -50], p1=[190 80], p2=[250 -70], p3=[290 20], ...
                type="open", npoints=96, width=8, layer="m1", output=true);
            ca = CircularArc(ctx, center=[360 0], radius=55, start_angle=30, end_angle=260, ...
                type="open", npoints=160, width=8, layer="m1", output=true);
            pc = ParametricCurve(ctx, coord={"40*cos(s)", "40*sin(s)"}, ...
                parname="s", parmin=0, parmax=2*pi, ...
                type="closed", npoints=128, layer="m1", output=true);

            outFile = fullfile(tempdir, "test_curves_points.gds");
            if isfile(outFile)
                delete(outFile);
            end
            ctx.export_gds(outFile);
            testCase.verifyTrue(isfile(outFile));

            backend = GdsBackend(ctx);
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

            ls = LineSegment(ctx, p1=[0 0], p2=[200 0], width=1, layer="m1", output=false);
            th1 = Thicken(ctx, ls, ...
                offset="symmetric", totalthick=30, ends="circular", convexcorner="fillet", ...
                layer="m1", output=true);

            ic = InterpolationCurve(ctx, points=[0 0; 60 40; 120 -30; 200 30], ...
                type="open", width=1, layer="m1", output=false);
            th2 = Thicken(ctx, ic, ...
                offset="asymmetric", upthick=22, downthick=8, ...
                ends="straight", convexcorner="extend", ...
                layer="m1", output=true);

            r = Rectangle(ctx, center=[320 0], width=120, height=80, layer="m1", output=false);
            th3 = Thicken(ctx, r, offset="symmetric", totalthick=20, layer="m1", output=true);

            outFile = fullfile(tempdir, "test_thicken.gds");
            if isfile(outFile)
                delete(outFile);
            end
            ctx.export_gds(outFile);
            testCase.verifyTrue(isfile(outFile));

            backend = GdsBackend(ctx);
            reg_ls = backend.region_for(ls);
            reg_th1 = backend.region_for(th1);
            reg_th2 = backend.region_for(th2);
            reg_r = backend.region_for(r);
            reg_th3 = backend.region_for(th3);

            testCase.verifyGreaterThan(double(reg_th1.area()), double(reg_ls.area()));
            testCase.verifyGreaterThan(double(reg_th2.area()), 0);
            testCase.verifyGreaterThan(double(reg_th3.area()), double(reg_r.area()));
        end

        function chamferOffsetTangentExtract(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available (pya/klayout.db/lygadgets).");

            ctx = TestGdsBackend.newContext();

            base = Rectangle(ctx, center=[0 0], width=120, height=80, layer="m1", output=false);
            cha = Chamfer(ctx, base, dist=12, points=[1 2 3 4], layer="m1", output=true);
            off = Offset(ctx, base, distance=10, reverse=false, convexcorner="fillet", ...
                trim=true, layer="m1", output=true);

            c = Circle(ctx, center=[220 0], radius=45, npoints=128, layer="m1", output=false);
            tan = Tangent(ctx, c, type="coord", coord=[320 20], start=0.75, ...
                width=8, layer="m1", output=true);

            e1 = Rectangle(ctx, center=[-220 20], width=60, height=40, layer="m1", output=false);
            e2 = Move(ctx, e1, delta=[90 0], layer="m1", output=false);
            ext = Extract(ctx, {e1, e2}, inputhandling="keep", layer="m1", output=true);

            outFile = fullfile(tempdir, "test_chamfer_offset_tangent_extract.gds");
            if isfile(outFile)
                delete(outFile);
            end
            ctx.export_gds(outFile);
            testCase.verifyTrue(isfile(outFile));

            backend = GdsBackend(ctx);
            reg_base = backend.region_for(base);
            reg_cha = backend.region_for(cha);
            reg_off = backend.region_for(off);
            reg_tan = backend.region_for(tan);
            reg_e1 = backend.region_for(e1);
            reg_e2 = backend.region_for(e2);
            reg_ext = backend.region_for(ext);

            testCase.verifyGreaterThan(double(reg_cha.area()), 0);
            testCase.verifyLessThanOrEqual(double(reg_cha.area()), double(reg_base.area()));
            testCase.verifyGreaterThan(double(reg_off.area()), double(reg_base.area()));
            testCase.verifyGreaterThan(double(reg_tan.area()), 0);
            testCase.verifyEqual(double(reg_ext.area()), double(reg_e1.area() + reg_e2.area()));
        end
    end

    methods (Static, Access=private)
        function ctx = newContext()
            % Build a standard GDS-only context used by all tests.
            ctx = GeometrySession(enable_comsol=false, enable_gds=true, snap_mode="off");
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
