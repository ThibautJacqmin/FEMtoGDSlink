classdef TestVertices < matlab.unittest.TestCase
    % Unit tests for numeric and parameterized types.Vertices behavior.
    methods (TestMethodTeardown)
        function clearCurrentContext(~)
            core.GeometryPipeline.set_current([]);
        end
    end

    methods (Test)
        function legacySharedPrefactorStillWorks(testCase)
            u = types.Parameter(1, "u_len", unit="um", auto_register=false);
            v = types.Vertices([10, 5], u);

            testCase.verifyFalse(v.has_component_coordinates());
            testCase.verifyEqual(v.value, [10, 5], AbsTol=1e-12);
            testCase.verifyEqual(v.length_value_nm(), [10000, 5000], AbsTol=1e-12);
            testCase.verifyEqual(string(v.comsol_string_x()), "(10)*(u_len)");
            testCase.verifyEqual(string(v.comsol_string_y()), "(5)*(u_len)");
        end

        function componentWiseParametersWork(testCase)
            x_right = types.Parameter(120, "x_right", unit="um", auto_register=false);
            y_bot = types.Parameter(50, "y_bot", unit="um", auto_register=false);
            w = types.Parameter(20, "rect_w", unit="um", auto_register=false);

            v = types.Vertices.xy(x_right - w, y_bot);

            testCase.verifyTrue(v.has_component_coordinates());
            testCase.verifyEqual(v.value, [100, 50], AbsTol=1e-12);
            testCase.verifyEqual(string(v.prefactor.unit), "um");
            testCase.verifyEqual(v.length_value_nm(), [100000, 50000], AbsTol=1e-12);
            testCase.verifyEqual(string(v.comsol_string_x()), "(x_right)-(rect_w)");
            testCase.verifyEqual(string(v.comsol_string_y()), "y_bot");
        end

        function unaryMinusParameterWorksInVertices(testCase)
            x = types.Parameter(12, "x_left", unit="um", auto_register=false);
            y = types.Parameter(5, "y_mid", unit="um", auto_register=false);

            nx = -x;
            v = types.Vertices.xy(-x, y);
            v_array = types.Vertices([-x, y]);

            testCase.verifyEqual(nx.value, -12, AbsTol=1e-12);
            testCase.verifyEqual(string(nx.unit), "um");
            testCase.verifyEqual(string(nx.expr), "-(x_left)");
            testCase.verifyEqual(string(nx.expression_token()), "-(x_left)");
            testCase.verifyEqual(v.value, [-12, 5], AbsTol=1e-12);
            testCase.verifyEqual(v.length_value_nm(), [-12000, 5000], AbsTol=1e-12);
            testCase.verifyEqual(string(v.comsol_string_x()), "-(x_left)");
            testCase.verifyEqual(string(v.comsol_string_y()), "y_mid");
            testCase.verifyEqual(v_array.value, v.value, AbsTol=1e-12);
            testCase.verifyEqual(string(v_array.comsol_string_x()), "-(x_left)");
        end

        function numericMateInheritsComponentUnit(testCase)
            x = types.Parameter(12, "x_um", unit="um", auto_register=false);

            v = types.Vertices.xy(x, 5);

            testCase.verifyEqual(v.value, [12, 5], AbsTol=1e-12);
            testCase.verifyEqual(string(v.prefactor.unit), "um");
            testCase.verifyEqual(v.length_value_nm(), [12000, 5000], AbsTol=1e-12);
            testCase.verifyEqual(string(v.comsol_string_x()), "x_um");
            testCase.verifyEqual(string(v.comsol_string_y()), "5[um]");
        end

        function constructorAcceptsParameterCoordinateArray(testCase)
            x = types.Parameter(7, "x_arr", unit="um", auto_register=false);
            y = types.Parameter(3, "y_arr", unit="um", auto_register=false);

            v = types.Vertices([x, y]);

            testCase.verifyTrue(v.has_component_coordinates());
            testCase.verifyEqual(v.value, [7, 3], AbsTol=1e-12);
            testCase.verifyEqual(string(v.comsol_string_x()), "x_arr");
            testCase.verifyEqual(string(v.comsol_string_y()), "y_arr");
        end

        function fromComponentsBuildsMultiplePoints(testCase)
            x = types.Parameter(10, "x0", unit="um", auto_register=false);
            y = types.Parameter(6, "y0", unit="um", auto_register=false);
            w = types.Parameter(4, "w0", unit="um", auto_register=false);

            v = types.Vertices.from_components({x, 0; x + w, y});

            testCase.verifyEqual(v.nvertices, 2);
            testCase.verifyEqual(v.value, [10, 0; 14, 6], AbsTol=1e-12);
            testCase.verifyEqual(v.length_value_nm(), [10000, 0; 14000, 6000], AbsTol=1e-12);
            testCase.verifyEqual(string(v.comsol_string_x()), ["x0"; "(x0)+(w0)"]);
            testCase.verifyEqual(string(v.comsol_string_y()), ["0[um]"; "y0"]);
        end

        function rectangleAndMoveAcceptComponentWiseVertices(testCase)
            ctx = core.GeometryPipeline(enable_comsol=false, enable_gds=false, snap_on_grid=false);
            ctx.add_layer("metal1", gds_layer=1, gds_datatype=0);

            x_right = types.Parameter(120, "x_right_r", unit="um", auto_register=false);
            y_bot = types.Parameter(50, "y_bot_r", unit="um", auto_register=false);
            w = types.Parameter(20, "rect_w_r", unit="um", auto_register=false);
            h = types.Parameter(10, "rect_h_r", unit="um", auto_register=false);

            r = primitives.Rectangle(ctx, ...
                base="corner", ...
                corner=types.Vertices.xy(x_right - w, y_bot), ...
                width=w, ...
                height=h, ...
                layer="metal1");

            testCase.verifyEqual(r.position.value, [100, 50], AbsTol=1e-12);
            testCase.verifyEqual(string(r.position.comsol_string_x()), "(x_right_r)-(rect_w_r)");
            testCase.verifyEqual(string(r.position.comsol_string_y()), "y_bot_r");

            dx = types.Parameter(12, "dx_r", unit="um", auto_register=false);
            dy = types.Parameter(5, "dy_r", unit="um", auto_register=false);
            m = ops.Move(ctx, r, delta=types.Vertices.xy(dx, dy), layer="metal1");

            testCase.verifyEqual(m.delta.value, [12, 5], AbsTol=1e-12);
            testCase.verifyEqual(string(m.delta.comsol_string_x()), "dx_r");
            testCase.verifyEqual(string(m.delta.comsol_string_y()), "dy_r");
        end

        function mixedComponentUnitsError(testCase)
            x = types.Parameter(1, "x_um_bad", unit="um", auto_register=false);
            y = types.Parameter(1, "y_mm_bad", unit="mm", auto_register=false);

            testCase.verifyError(@() types.Vertices.xy(x, y), ...
                "Vertices:MixedComponentUnits");
        end
    end
end
