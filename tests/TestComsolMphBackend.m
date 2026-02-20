classdef TestComsolMphBackend < matlab.unittest.TestCase
    % Integration tests for COMSOL emission through the Python MPh backend.
    methods (TestMethodTeardown)
        function cleanupSharedComsol(~)
            % Ensure shared state does not leak across tests.
            core.GeometryPipeline.clear_shared_comsol();
            core.GeometryPipeline.set_current([]);
        end
    end

    methods (Test)
        function bootstrapLoadsInstalledMph(testCase)
            % Verify bootstrap resolves mph from site-packages, not local repo.
            mph_mod = core.ComsolMphModeler.ensure_ready();
            mod_file = string(char(py.getattr(mph_mod, "__file__")));
            local_repo = lower(string(fullfile(pwd, "MPh")));

            testCase.verifyFalse(startsWith(lower(mod_file), local_repo), ...
                "mph bootstrap loaded local MPh folder.");
            testCase.verifyTrue(contains(lower(mod_file), "site-packages"), ...
                "mph module path does not look like an installed package.");
        end

        function withSharedComsolUsesMphModelerAndBuilds(testCase)
            % Verify GeometryPipeline can emit basic features through comsol_api="mph".
            [ok, reason] = TestComsolMphBackend.hasMphServer();
            testCase.assumeTrue(ok, "Skipping MPh integration test: " + reason);

            ctx = core.GeometryPipeline.with_shared_comsol( ...
                enable_gds=false, emit_on_create=false, ...
                snap_on_grid=false, reset_model=true, clean_on_reset=false, ...
                comsol_api="mph");
            testCase.verifyClass(ctx.comsol, "core.ComsolMphModeler");

            p_w = types.Parameter(40, "mph_w");
            p_h = types.Parameter(20, "mph_h");
            r = primitives.Rectangle(ctx, center=[0 0], width=p_w, height=p_h, layer="default");
            s = primitives.Square(ctx, center=[-35 0], side=12, layer="default");
            c = primitives.Circle(ctx, center=[35 0], radius=8, layer="default");
            u = ops.Union(ctx, {r, s, c}, layer="default");

            ctx.build_comsol();

            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(r.id)));
            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(s.id)));
            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(c.id)));
            testCase.verifyTrue(isKey(ctx.comsol_backend.feature_tags, int32(u.id)));
            testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, "mph_w"));
            testCase.verifyTrue(isKey(ctx.comsol_backend.defined_params, "mph_h"));
        end

        function mphSharedModelerReuseAndClear(testCase)
            % Verify shared MPh modeler reuses model tag and clear_shared resets it.
            [ok, reason] = TestComsolMphBackend.hasMphServer();
            testCase.assumeTrue(ok, "Skipping MPh integration test: " + reason);

            core.GeometryPipeline.clear_shared_comsol();
            ctx1 = core.GeometryPipeline.with_shared_comsol( ...
                enable_gds=false, snap_on_grid=false, ...
                reset_model=true, clean_on_reset=false, ...
                comsol_api="mph");
            tag1 = string(ctx1.comsol.model_tag);

            ctx2 = core.GeometryPipeline.with_shared_comsol( ...
                enable_gds=false, snap_on_grid=false, ...
                reset_model=true, clean_on_reset=false, ...
                comsol_api="mph");
            tag2 = string(ctx2.comsol.model_tag);

            testCase.verifyEqual(tag2, tag1);
            testCase.verifyTrue(isequal(ctx1.comsol, ctx2.comsol));

            core.GeometryPipeline.clear_shared_comsol();
            ctx3 = core.GeometryPipeline.with_shared_comsol( ...
                enable_gds=false, snap_on_grid=false, ...
                reset_model=true, clean_on_reset=false, ...
                comsol_api="mph");
            tag3 = string(ctx3.comsol.model_tag);
            testCase.verifyNotEqual(tag3, tag1);
        end
    end

    methods (Static, Access=private)
        function [tf, reason] = hasMphServer()
            % Return true when installed mph is available and server accepts connections.
            persistent cached_tf cached_reason
            if ~isempty(cached_tf)
                tf = cached_tf;
                reason = cached_reason;
                return;
            end

            tf = false;
            reason = "";
            host = TestComsolMphBackend.comsolHost();
            port = TestComsolMphBackend.comsolPort();
            if ~TestComsolMphBackend.canReachServer(host, port, 250)
                reason = "server port is not reachable (" + host + ":" + string(port) + ").";
                cached_tf = tf;
                cached_reason = reason;
                return;
            end

            try
                core.ComsolMphModeler.ensure_ready();
            catch ex
                reason = "mph import/bootstrap failed: " + string(ex.message);
                cached_tf = tf;
                cached_reason = reason;
                return;
            end

            tf = true;
            cached_tf = tf;
            cached_reason = reason;
        end

        function host = comsolHost()
            % Resolve COMSOL host from environment or default.
            host = string(getenv("FEMTOGDS_COMSOL_HOST"));
            if strlength(host) == 0
                host = "localhost";
            end
        end

        function port = comsolPort()
            % Resolve COMSOL port from environment or default.
            token = string(getenv("FEMTOGDS_COMSOL_PORT"));
            val = str2double(token);
            if ~(isscalar(val) && isfinite(val) && val > 0)
                port = 2036;
            else
                port = double(val);
            end
        end

        function tf = canReachServer(host, port, timeout_ms)
            % Fast TCP probe to avoid long blocking MPh client connect calls.
            tf = false;
            try
                s = javaObject("java.net.Socket");
                c = onCleanup(@() TestComsolMphBackend.safeCloseSocket(s));
                addr = javaObject("java.net.InetSocketAddress", char(host), int32(port));
                s.connect(addr, int32(timeout_ms));
                tf = true;
            catch
            end
            clear c
        end

        function safeCloseSocket(s)
            % Close Java socket best-effort.
            try
                s.close();
            catch
            end
        end
    end
end

