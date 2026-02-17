classdef TestGeometrySessionUtils < matlab.unittest.TestCase
    % Unit tests for GeometrySession static utility behavior.
    methods (TestMethodTeardown)
        function clearCurrentContext(~)
            core.GeometrySession.set_current([]);
        end
    end

    methods (Test)
        function nodeKeepsInputsReadsFeatureFlag(testCase)
            ctx = core.GeometrySession(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            rect = primitives.Rectangle(ctx, center=[0 0], width=20, height=10, layer="default");

            keep_node = ops.Move(ctx, rect, delta=[10 0], keep_input_objects=true, layer="default");
            consume_node = ops.Move(ctx, rect, delta=[20 0], keep_input_objects=false, layer="default");

            testCase.verifyTrue(core.GeometrySession.node_keeps_inputs(keep_node));
            testCase.verifyFalse(core.GeometrySession.node_keeps_inputs(consume_node));
            testCase.verifyFalse(core.GeometrySession.node_keeps_inputs(rect));
        end

        function rectangleAndSquareExposeBezierFilletHelpers(testCase)
            ctx = core.GeometrySession(enable_comsol=false, enable_gds=false, snap_on_grid=false);

            r = primitives.Rectangle(ctx, center=[10 5], width=8, height=4, layer="default");
            testCase.verifyEqual(r.left.value, 6, AbsTol=1e-12);
            testCase.verifyEqual(r.right.value, 14, AbsTol=1e-12);
            testCase.verifyEqual(r.bottom.value, 3, AbsTol=1e-12);
            testCase.verifyEqual(r.top.value, 7, AbsTol=1e-12);
            testCase.verifyEqual(r.top_left.value, [6, 7], AbsTol=1e-12);
            testCase.verifyEqual(r.top_right.value, [14, 7], AbsTol=1e-12);
            testCase.verifyEqual(r.bottom_left.value, [6, 3], AbsTol=1e-12);
            testCase.verifyEqual(r.bottom_right.value, [14, 3], AbsTol=1e-12);

            rf = r.get_fillets(fillet_width=2, fillet_height=1, npoints=6);
            testCase.verifyEqual(numel(rf), 4);
            for i = 1:numel(rf)
                testCase.verifyClass(rf{i}, "primitives.Polygon");
            end

            s = primitives.Square(ctx, center=[0 0], side=6, layer="default");
            testCase.verifyEqual(s.width.value, 6, AbsTol=1e-12);
            testCase.verifyEqual(s.height.value, 6, AbsTol=1e-12);
            s.size = 9;
            testCase.verifyEqual(s.width.value, 9, AbsTol=1e-12);
            testCase.verifyEqual(s.height.value, 9, AbsTol=1e-12);
            s.side = 12;
            testCase.verifyEqual(s.width.value, 12, AbsTol=1e-12);
            testCase.verifyEqual(s.height.value, 12, AbsTol=1e-12);

            sf = s.get_fillets(fillet_width=1.5, fillet_height=1.5, npoints=8);
            testCase.verifyEqual(numel(sf), 4);
        end
    end
end
