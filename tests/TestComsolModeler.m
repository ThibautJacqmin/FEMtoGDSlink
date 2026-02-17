classdef TestComsolModeler < matlab.unittest.TestCase
    % Unit tests for shared COMSOL modeler helpers.
    methods (Test)
        function nextModelTagHasModelPrefix(testCase)
            tag = core.ComsolModeler.next_model_tag();
            testCase.verifyClass(tag, "string");
            testCase.verifyTrue(startsWith(tag, "Model_"));
        end

        function comsolPrefixUsesThreeLowercaseChars(testCase)
            pref = core.ComsolModeler.comsol_prefix("Rectangle");
            testCase.verifyEqual(pref, "rec");
        end

        function connectionDefaultsHaveExpectedTypes(testCase)
            cfg = core.ComsolModeler.connection_defaults();
            testCase.verifyTrue(isstruct(cfg));
            testCase.verifyTrue(isfield(cfg, "host"));
            testCase.verifyTrue(isfield(cfg, "port"));
            testCase.verifyTrue(isfield(cfg, "root"));
            testCase.verifyClass(cfg.host, "string");
            testCase.verifyClass(cfg.port, "double");
            testCase.verifyClass(cfg.root, "string");
            testCase.verifyGreaterThan(cfg.port, 0);
        end

        function configuredRootsReturnsStringColumn(testCase)
            roots = core.ComsolModeler.configured_roots();
            testCase.verifyClass(roots, "string");
            testCase.verifyEqual(size(roots, 2), 1);
            testCase.verifyEqual(roots, unique(roots, "stable"));
        end
    end
end
