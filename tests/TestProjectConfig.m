classdef TestProjectConfig < matlab.unittest.TestCase
    % Unit tests for local runtime configuration loading.
    methods (Test)
        function loadProvidesComsolAndKlayoutSections(testCase)
            cfg = core.ProjectConfig.load(reload=true);

            testCase.verifyTrue(isstruct(cfg));
            testCase.verifyTrue(isfield(cfg, "comsol"));
            testCase.verifyTrue(isfield(cfg, "klayout"));
            testCase.verifyTrue(isfield(cfg.comsol, "root"));
            testCase.verifyTrue(isfield(cfg.comsol, "host"));
            testCase.verifyTrue(isfield(cfg.comsol, "port"));
            testCase.verifyTrue(isfield(cfg.klayout, "root"));
            testCase.verifyTrue(isfield(cfg.klayout, "python_paths"));
            testCase.verifyTrue(isfield(cfg.klayout, "bin_paths"));
        end

        function loadNormalizesExpectedTypes(testCase)
            cfg = core.ProjectConfig.load(reload=true);

            testCase.verifyClass(cfg.comsol.root, "string");
            testCase.verifyClass(cfg.comsol.host, "string");
            testCase.verifyClass(cfg.comsol.port, "double");
            testCase.verifyClass(cfg.klayout.root, "string");
            testCase.verifyClass(cfg.klayout.python_paths, "string");
            testCase.verifyClass(cfg.klayout.bin_paths, "string");
            testCase.verifyGreaterThan(cfg.comsol.port, 0);
        end
    end
end
