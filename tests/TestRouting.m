classdef TestRouting < matlab.unittest.TestCase
    % Unit/integration tests for +routing package.
    methods (Test)
        function portSpecReverseMaskCompatibility(testCase)
            spec = routing.PortSpec( ...
                widths=[10, 24], ...
                offsets=[0, 3], ...
                layers=["m1", "gap"], ...
                subnames=["sig", "gap"]);

            testCase.verifyEqual(spec.ntracks, 2);
            testCase.verifyEqual(spec.widths_value(), [10, 24], AbsTol=1e-12);
            testCase.verifyEqual(spec.offsets_value(), [0, 3], AbsTol=1e-12);

            rev = spec.reversed();
            testCase.verifyEqual(rev.offsets_value(), [0, -3], AbsTol=1e-12);
            testCase.verifyEqual(rev.widths_value(), spec.widths_value(), AbsTol=1e-12);

            masked = spec.with_mask(layer="mask", gap=2);
            testCase.verifyEqual(masked.ntracks, 3);
            testCase.verifyEqual(masked.layers(end), "mask");
            testCase.verifyEqual(masked.subnames(end), "mask");
            testCase.verifyTrue(masked.width_value(3) > 0);

            testCase.verifyTrue(spec.is_compatible(spec));
            testCase.verifyFalse(spec.is_compatible(rev, check_offsets=true));
            testCase.verifyTrue(spec.is_compatible(rev, check_offsets=false));
        end

        function routeManhattanAndShift(testCase)
            spec = routing.PortSpec(widths=10, offsets=0, layers="m1", subnames="sig");
            p1 = routing.PortRef(name="p1", pos=[0, 0], ori=[1, 0], spec=spec);
            p2 = routing.PortRef(name="p2", pos=[200, 80], ori=[-1, 0], spec=spec);

            route = routing.Route.manhattan(p1, p2, start_straight=25, fillet=8, bend="auto");
            testCase.verifyEqual(route.points(1, :), [0, 0], AbsTol=1e-12);
            testCase.verifyEqual(route.points(end, :), [200, 80], AbsTol=1e-12);
            testCase.verifyGreaterThan(route.path_length(), 0);

            shifted = route.shifted(12);
            testCase.verifyEqual(size(shifted.points, 2), 2);
            testCase.verifyEqual(shifted.fillet, route.fillet, AbsTol=1e-12);

            sharp = routing.Route(points=[0, 0; 100, 0; 100, 100], fillet=0);
            filleted = routing.Route(points=[0, 0; 100, 0; 100, 100], fillet=20);
            sharp_pts = sharp.shifted_points(0);
            fillet_pts = filleted.shifted_points(0);
            testCase.verifyEqual(size(sharp_pts, 1), 3);
            testCase.verifyGreaterThan(size(fillet_pts, 1), size(sharp_pts, 1));
            testCase.verifyLessThan(filleted.path_length(), sharp.path_length());
        end

        function portRefMarkersBondAndSplit(testCase)
            ctx = core.GeometrySession(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");
            ctx.add_layer("gap", gds_layer=2, gds_datatype=0, comsol_workplane="wp1");
            ctx.add_layer("port", gds_layer=10, gds_datatype=0, comsol_workplane="wp1");

            spec = routing.PortSpec( ...
                widths=[10, 30], offsets=[0, 5], ...
                layers=["m1", "gap"], subnames=["sig", "gnd"]);
            p = routing.PortRef(name="p", pos=[100, 50], ori=[1, 0], spec=spec);

            [ymax, ymin] = p.bond_params();
            testCase.verifyEqual(ymax, 20, AbsTol=1e-12);
            testCase.verifyEqual(ymin, -10, AbsTol=1e-12);

            tris = p.marker_triangles();
            testCase.verifyEqual(numel(tris), 2);
            testCase.verifyEqual(tris{1}.nvertices, 3);
            testCase.verifyEqual(tris{2}.nvertices, 3);
            tri1 = tris{1}.value;
            testCase.verifyGreaterThan(tri1(2, 1), tri1(1, 1));
            testCase.verifyGreaterThan(tri1(2, 1), tri1(3, 1));

            feats = p.draw_markers(ctx=ctx, layer="port");
            testCase.verifyEqual(numel(feats), 2);
            for i = 1:numel(feats)
                testCase.verifyTrue(isa(feats{i}, "core.GeomFeature"));
            end

            split_sig = p.split(subnames="sig", gap=8, gap_layer="gap");
            testCase.verifyEqual(numel(split_sig), 1);
            s = split_sig{1}.spec;
            testCase.verifyEqual(s.ntracks, 2);
            testCase.verifyEqual(s.widths_value(), [10, 26], AbsTol=1e-12);
            testCase.verifyEqual(s.layers, ["m1", "gap"]);
            testCase.verifyEqual(split_sig{1}.position_value(), [100, 50], AbsTol=1e-12);

            split_all_but_last = p.split(subnames=-1, gap=6, gap_layer="gap");
            testCase.verifyEqual(numel(split_all_but_last), 1);
        end

        function cableBuildsFeaturesWithoutBackends(testCase)
            ctx = core.GeometrySession(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");
            ctx.add_layer("gap", gds_layer=2, gds_datatype=0, comsol_workplane="wp1");

            spec = routing.PortSpec( ...
                widths=[12, 32], offsets=[0, 0], ...
                layers=["m1", "gap"], subnames=["sig", "gap"]);
            p1 = routing.PortRef(name="in", pos=[0, 0], ori=[1, 0], spec=spec);
            p2 = routing.PortRef(name="out", pos=[240, 60], ori=[-1, 0], spec=spec);

            cable = routing.Cable(ctx, p1, p2, ...
                fillet=18, start_straight=35, name="feed", merge_per_layer=true);

            testCase.verifyEqual(numel(cable.raw_tracks), 2);
            testCase.verifyEqual(numel(cable.features), 2);
            testCase.verifyGreaterThan(cable.length_nm(), 0);
            testCase.verifyGreaterThan( ...
                cable.centerlines{1}.points.nvertices, ...
                size(cable.route.points, 1));
            for i = 1:numel(cable.features)
                testCase.verifyTrue(isa(cable.features{i}, "core.GeomFeature"));
            end

            terminal_nodes = ctx.gds_nodes_for_export();
            terminal_ids = cellfun(@(n) int32(n.id), terminal_nodes);
            cable_ids = cellfun(@(n) int32(n.id), cable.features);
            testCase.verifyEqual(sort(terminal_ids), sort(cable_ids));
        end

        function cableRejectsMismatchedSpecs(testCase)
            ctx = core.GeometrySession(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");

            s1 = routing.PortSpec(widths=10, offsets=0, layers="m1", subnames="sig");
            s2 = routing.PortSpec(widths=14, offsets=0, layers="m1", subnames="sig");
            p1 = routing.PortRef(name="a", pos=[0, 0], ori=[1, 0], spec=s1);
            p2 = routing.PortRef(name="b", pos=[120, 0], ori=[-1, 0], spec=s2);

            testCase.verifyError(@() routing.Cable(ctx, p1, p2), "routing:Cable:SpecMismatch");
        end

        function cableExportsToGds(testCase)
            testCase.assumeTrue(TestRouting.hasKLayout(), ...
                "Skipping: KLayout Python bindings not available.");

            ctx = core.GeometrySession(enable_comsol=false, enable_gds=true, snap_on_grid=false);
            ctx.add_layer("m1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1");
            ctx.add_layer("gap", gds_layer=2, gds_datatype=0, comsol_workplane="wp1");

            spec = routing.PortSpec( ...
                widths=[14, 34], offsets=[0, 0], ...
                layers=["m1", "gap"], subnames=["sig", "gap"]);
            p1 = routing.PortRef(name="in", pos=[0, 0], ori=[1, 0], spec=spec);
            p2 = routing.PortRef(name="out", pos=[300, 120], ori=[-1, 0], spec=spec);

            cable = routing.Cable(ctx, p1, p2, ...
                fillet=25, start_straight=40, name="route5", merge_per_layer=true);

            outFile = fullfile(tempdir, "test_routing_cable.gds");
            if isfile(outFile)
                delete(outFile);
            end
            ctx.export_gds(outFile);
            testCase.verifyTrue(isfile(outFile));

            backend = core.KlayoutBackend(ctx);
            for i = 1:numel(cable.features)
                reg = backend.region_for(cable.features{i});
                testCase.verifyGreaterThan(double(reg.area()), 0);
            end
        end
    end

    methods (Static, Access=private)
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
