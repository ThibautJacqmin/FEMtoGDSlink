classdef TestGdsBackend < matlab.unittest.TestCase
    methods (Test)
        function exportRectangle(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python module 'lygadgets' not available.");

            ctx = GeometrySession(enable_comsol=false, enable_gds=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");

            r = Rectangle(ctx, center=[0 0], width=100, height=50, layer="m1");
            r.output = true;

            outFile = fullfile(tempdir, "test_rect.gds");
            if isfile(outFile)
                delete(outFile);
            end
            ctx.export_gds(outFile);

            testCase.verifyTrue(isfile(outFile));
        end

        function exportBooleanAndTransform(testCase)
            testCase.assumeTrue(TestGdsBackend.hasKLayout(), ...
                "Skipping: KLayout Python module 'lygadgets' not available.");

            ctx = GeometrySession(enable_comsol=false, enable_gds=true);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");

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
        end
    end

    methods (Static, Access=private)
        function tf = hasKLayout()
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
