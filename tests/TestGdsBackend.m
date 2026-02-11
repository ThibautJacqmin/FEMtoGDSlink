classdef TestGdsBackend < matlab.unittest.TestCase
    % Regression tests for GDS emission pipeline.
    methods (Test)
        function exportRectangle(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python module 'lygadgets' not available.");

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
                "Skipping: KLayout Python module 'lygadgets' not available.");

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
                "Skipping: KLayout Python module 'lygadgets' not available.");

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
                "Skipping: KLayout Python module 'lygadgets' not available.");

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
                py.importlib.import_module('lygadgets');
                cached = true;
            catch
                cached = false;
            end
            tf = cached;
        end
    end
end
