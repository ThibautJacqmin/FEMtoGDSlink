classdef TestLattice < matlab.unittest.TestCase
    % Unit tests for lattice geometry/maths helper classes.
    methods (TestClassSetup)
        function addProjectRootToPath(~)
            this_file = mfilename('fullpath');
            tests_dir = fileparts(this_file);
            root_dir = fileparts(tests_dir);
            addpath(root_dir);
        end
    end

    methods (Test)
        function hexagonalGeometryShapeAndCentering(testCase)
            a = 10;
            nw = 4;
            nh = 3;
            lat = lattices.HexagonalLattice(a, nw, nh);

            testCase.verifySize(lat.nodes, [nw + 1, nh + 1, 2]);

            ci = floor(nw / 2) + 1;
            cj = floor(nh / 2) + 1;
            center_node = squeeze(lat.nodes(ci, cj, :)).';
            testCase.verifyEqual(center_node, [0, 0], AbsTol=1e-12);

            % Adjacent i-index nodes on same row are spaced by a.
            dx = lat.nodes(ci + 1, cj, 1) - lat.nodes(ci, cj, 1);
            dy = lat.nodes(ci + 1, cj, 2) - lat.nodes(ci, cj, 2);
            testCase.verifyEqual(dx, a, AbsTol=1e-12);
            testCase.verifyEqual(dy, 0, AbsTol=1e-12);
        end

        function reciprocalAndContourProperties(testCase)
            a = 12.5;
            lat = lattices.HexagonalLattice(a, 2, 2);

            testCase.verifyEqual(lat.a1, a * [1, 0], AbsTol=1e-12);
            testCase.verifyEqual(lat.a2, a * [1/2, sqrt(3)/2], AbsTol=1e-12);
            testCase.verifyEqual(lat.b, 4 * pi / sqrt(3) / a, AbsTol=1e-12);
            testCase.verifyEqual(lat.b1, lat.b * [1/2, -sqrt(3)/2], AbsTol=1e-12);
            testCase.verifyEqual(lat.b2, lat.b * [1/2, sqrt(3)/2], AbsTol=1e-12);

            uc = lat.unitCellContour;
            testCase.verifySize(uc, [5, 2]);
            testCase.verifyEqual(uc(1, :), uc(end, :), AbsTol=1e-12);

            ibz = lat.irreducibleBrillouinZoneContour;
            testCase.verifySize(ibz, [4, 2]);
            testCase.verifyEqual(ibz(1, :), lat.Gamma, AbsTol=1e-12);
            testCase.verifyEqual(ibz(end, :), lat.Gamma, AbsTol=1e-12);
            testCase.verifyEqual(ibz(2, :), lat.M, AbsTol=1e-12);
            testCase.verifyEqual(ibz(3, :), lat.K, AbsTol=1e-12);
        end

        function honeycombSublatticeOffsets(testCase)
            a = 9;
            lat = lattices.HoneyCombLattice(a, 3, 2);

            A = lat.nodes.sublatticeA;
            B = lat.nodes.sublatticeB;
            C = lat.nodes.hexagon_centers;

            testCase.verifyEqual(A, lat.hexagonal_lattice.nodes, AbsTol=1e-12);

            dB = B - A;
            testCase.verifyEqual(dB(:, :, 1), (a / 2) * ones(size(dB, 1), size(dB, 2)), AbsTol=1e-12);
            testCase.verifyEqual(dB(:, :, 2), (a / (2 * sqrt(3))) * ones(size(dB, 1), size(dB, 2)), ...
                AbsTol=1e-12);

            dC = C - A;
            testCase.verifyEqual(dC(:, :, 1), zeros(size(dC, 1), size(dC, 2)), AbsTol=1e-12);
            testCase.verifyEqual(dC(:, :, 2), (a / sqrt(3)) * ones(size(dC, 1), size(dC, 2)), AbsTol=1e-12);
        end

        function honeycombSiteCoordinates(testCase)
            a = 7;
            lat = lattices.HoneyCombLattice(a, 2, 2);

            expected_siteA = (lat.a1 + lat.a2) / 3;
            expected_delta = (lat.a1 + lat.a2) / 3;

            testCase.verifyEqual(lat.siteA, expected_siteA, AbsTol=1e-12);
            testCase.verifyEqual(lat.siteB - lat.siteA, expected_delta, AbsTol=1e-12);
        end

        function computeGeometryDispatch(testCase)
            h1 = lattices.HexagonalLattice(8, 2, 1);
            nodes1 = h1.computeGeometry("Hexagonal");
            testCase.verifyEqual(nodes1, h1.nodes, AbsTol=1e-12);

            h2 = lattices.HoneyCombLattice(8, 2, 1);
            nodes2 = h2.computeGeometry("Honeycomb");
            testCase.verifyEqual(nodes2.sublatticeA, h2.nodes.sublatticeA, AbsTol=1e-12);
            testCase.verifyEqual(nodes2.sublatticeB, h2.nodes.sublatticeB, AbsTol=1e-12);
            testCase.verifyEqual(nodes2.hexagon_centers, h2.nodes.hexagon_centers, AbsTol=1e-12);

            % Legacy spelling remains accepted.
            nodes2_legacy = h2.computeGeometry("HoneyComb");
            testCase.verifyEqual(nodes2_legacy.sublatticeA, h2.nodes.sublatticeA, AbsTol=1e-12);
        end

        function getSitesApiReturnsFlatAndGridCoordinates(testCase)
            hex = lattices.HexagonalLattice(10, 2, 3);
            flat = hex.get_sites();
            grid = hex.get_sites(as_grid=true);
            testCase.verifySize(flat, [(hex.nw + 1) * (hex.nh + 1), 2]);
            testCase.verifyEqual(grid, hex.nodes, AbsTol=1e-12);

            hon = lattices.HoneyCombLattice(10, 2, 3);
            A = hon.get_sites(which="A");
            B = hon.get_sites(which="B");
            C = hon.get_sites(which="centers");
            all_sites = hon.get_sites();
            testCase.verifySize(A, [(hon.nw + 1) * (hon.nh + 1), 2]);
            testCase.verifySize(B, [(hon.nw + 1) * (hon.nh + 1), 2]);
            testCase.verifySize(C, [(hon.nw + 1) * (hon.nh + 1), 2]);
            testCase.verifyTrue(isstruct(all_sites));
            testCase.verifyEqual(all_sites.A, A, AbsTol=1e-12);
            testCase.verifyEqual(all_sites.B, B, AbsTol=1e-12);
            testCase.verifyEqual(all_sites.centers, C, AbsTol=1e-12);

            all_grid = hon.get_sites(as_grid=true);
            testCase.verifyEqual(all_grid.A, hon.nodes.sublatticeA, AbsTol=1e-12);
            testCase.verifyEqual(all_grid.B, hon.nodes.sublatticeB, AbsTol=1e-12);
            testCase.verifyEqual(all_grid.centers, hon.nodes.hexagon_centers, AbsTol=1e-12);
        end

        function constructorValidatesPositiveInputs(testCase)
            did_throw = false;
            try
                lattices.HexagonalLattice(0, 2, 2);
            catch
                did_throw = true;
            end
            testCase.verifyTrue(did_throw);

            did_throw = false;
            try
                lattices.HexagonalLattice(5, 0, 2);
            catch
                did_throw = true;
            end
            testCase.verifyTrue(did_throw);

            did_throw = false;
            try
                lattices.HoneyCombLattice(5, 2, -1);
            catch
                did_throw = true;
            end
            testCase.verifyTrue(did_throw);
        end

        function hexagonalCircleArrayBuildsParameterizedArrays(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            a_param = types.Parameter(20, "a_lat", unit="nm", auto_register=false);
            lat = lattices.HexagonalLattice(20, 4, 3);

            seed = primitives.Circle(ctx, center=[0, 0], radius=3, npoints=64, layer="default");
            feat = lat.latticeFromFeature(seed=seed, ctx=ctx, layer="default", a_parameter=a_param);

            testCase.verifyTrue(isa(feat, "ops.Union"));
            members = feat.members;
            testCase.verifyNumElements(members, 2);
            array_count = 0;
            for i = 1:numel(members)
                testCase.verifyTrue(TestLattice.featureTreeContainsClass( ...
                    members{i}, "primitives.Circle"));
                arr = TestLattice.firstFeatureOfClass(members{i}, "ops.Array2D");
                testCase.verifyFalse(isempty(arr));
                array_count = array_count + 1;
                testCase.verifyEqual(arr.ncopies_x.value, 5);
                testCase.verifyEqual(arr.delta_x.array, [1, 0], AbsTol=1e-12);
                testCase.verifyEqual(arr.delta_y.array, [0, sqrt(3)], AbsTol=1e-12);
                testCase.verifyEqual(string(arr.delta_x.prefactor.name), "a_lat");
                testCase.verifyEqual(string(arr.delta_y.prefactor.name), "a_lat");
            end
            testCase.verifyEqual(array_count, 2);
        end

        function honeycombCircleArraySupportsSublatticeSelection(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            a_param = types.Parameter(12, "a_hc", unit="nm", auto_register=false);
            lat = lattices.HoneyCombLattice(12, 3, 2);

            seed = primitives.Circle(ctx, center=[0, 0], radius=2, npoints=64, layer="default");
            fA = lat.latticeFromFeature(ctx=ctx, seed=seed, layer="default", ...
                a_parameter=a_param, sublattice="A");
            fB = lat.latticeFromFeature(ctx=ctx, seed=seed, layer="default", ...
                a_parameter=a_param, sublattice="B");
            fAB = lat.latticeFromFeature(ctx=ctx, seed=seed, layer="default", ...
                a_parameter=a_param, sublattice="AB");
            fC = lat.latticeFromFeature(ctx=ctx, seed=seed, layer="default", ...
                a_parameter=a_param, sublattice="centers");

            testCase.verifyTrue(isa(fA, "core.GeomFeature"));
            testCase.verifyTrue(isa(fB, "core.GeomFeature"));
            testCase.verifyTrue(isa(fC, "core.GeomFeature"));
            testCase.verifyTrue(isa(fAB, "ops.Union"));
            testCase.verifyNumElements(fAB.members, 2);
        end

        function latticeCreateArrayDispatchesHexagonalFromName(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            a_param = types.Parameter(18, "a_lat_dispatch", unit="nm", auto_register=false);
            seed = primitives.Circle(ctx, center=[0, 0], radius=2.5, npoints=48, layer="default");

            [feat, lat] = lattices.Lattice.createLattice(lattice="Hexagonal", a=18, nw=3, nh=2, ...
                seed=seed, ctx=ctx, layer="default", a_parameter=a_param);

            testCase.verifyTrue(isa(lat, "lattices.HexagonalLattice"));
            testCase.verifyTrue(isa(feat, "core.GeomFeature"));
            testCase.verifyTrue(TestLattice.featureTreeContainsClass(feat, "primitives.Circle"));
        end

        function latticeCreateArraySupportsHoneycombDifferentABSeeds(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            a_param = types.Parameter(14, "a_lat_hc_dispatch", unit="nm", auto_register=false);
            seed_A = primitives.Circle(ctx, center=[0, 0], radius=2, npoints=40, layer="default");
            seed_B = primitives.Rectangle(ctx, center=[0, 0], width=3.5, height=2.5, ...
                layer="default");

            [feat, lat] = lattices.Lattice.createLattice(lattice="HoneyComb", a=14, nw=2, nh=2, ...
                seedA=seed_A, seedB=seed_B, sublattice="AB", ctx=ctx, ...
                layer="default", a_parameter=a_param);

            testCase.verifyTrue(isa(lat, "lattices.HoneyCombLattice"));
            testCase.verifyTrue(isa(feat, "ops.Union"));
            testCase.verifyTrue(TestLattice.featureTreeContainsClass(feat, "primitives.Circle"));
            testCase.verifyTrue(TestLattice.featureTreeContainsClass(feat, "primitives.Rectangle"));
        end
    end

    methods (Static, Access=private)
        function tf = featureTreeContainsClass(feature, class_name)
            % Recursively inspect a feature graph for a class occurrence.
            tf = false;
            if isempty(feature)
                return;
            end
            if isa(feature, class_name)
                tf = true;
                return;
            end
            if ~isa(feature, "core.GeomFeature")
                return;
            end

            if isprop(feature, "target")
                tf = TestLattice.featureTreeContainsClass(feature.target, class_name);
                if tf
                    return;
                end
            end

            if isprop(feature, "members")
                members = feature.members;
                for i = 1:numel(members)
                    tf = TestLattice.featureTreeContainsClass(members{i}, class_name);
                    if tf
                        return;
                    end
                end
            else
                for i = 1:numel(feature.inputs)
                    tf = TestLattice.featureTreeContainsClass(feature.inputs{i}, class_name);
                    if tf
                        return;
                    end
                end
            end
        end

        function out = firstFeatureOfClass(feature, class_name)
            % Return first matching feature node in graph (or []).
            out = [];
            if isempty(feature)
                return;
            end
            if isa(feature, class_name)
                out = feature;
                return;
            end
            if ~isa(feature, "core.GeomFeature")
                return;
            end

            if isprop(feature, "target")
                out = TestLattice.firstFeatureOfClass(feature.target, class_name);
                if ~isempty(out)
                    return;
                end
            end

            if isprop(feature, "members")
                members = feature.members;
                for i = 1:numel(members)
                    out = TestLattice.firstFeatureOfClass(members{i}, class_name);
                    if ~isempty(out)
                        return;
                    end
                end
            else
                for i = 1:numel(feature.inputs)
                    out = TestLattice.firstFeatureOfClass(feature.inputs{i}, class_name);
                    if ~isempty(out)
                        return;
                    end
                end
            end
        end
    end
end
