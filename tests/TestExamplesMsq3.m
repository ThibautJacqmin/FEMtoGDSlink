classdef TestExamplesMsq3 < matlab.unittest.TestCase
    % Smoke tests for MSQ3 example scripts in headless/no-backend mode.
    methods (Test)
        function example6RunsHeadless(testCase)
            out = TestExamplesMsq3.runExampleNoBackend("example_6_msq3_membrane_chip.m");
            testCase.verifyNotEmpty(regexp(out, 'Example 6 membrane center:', 'once'));
            testCase.verifyNotEmpty(regexp(out, 'Example 6 backside opening dims:', 'once'));
            testCase.verifyNotEmpty(regexp(out, 'Example 6 KOH protection dims:', 'once'));
        end

        function example7RunsHeadless(testCase)
            out = TestExamplesMsq3.runExampleNoBackend("example_7_msq3_meca_lc_chip.m");
            testCase.verifyNotEmpty(regexp(out, 'Example 7 membrane center:', 'once'));
            testCase.verifyNotEmpty(regexp(out, 'Example 7 resonator center:', 'once'));

            rd_tok = regexp(out, 'Example 7 readout length: ([0-9.]+) um', 'tokens', 'once');
            dc_tok = regexp(out, 'Example 7 dc-bias length: ([0-9.]+) um', 'tokens', 'once');
            testCase.assertFalse(isempty(rd_tok));
            testCase.assertFalse(isempty(dc_tok));
            testCase.verifyGreaterThan(str2double(rd_tok{1}), 0);
            testCase.verifyGreaterThan(str2double(dc_tok{1}), 0);
        end

        function example8RunsHeadlessAndPlacesExpectedChips(testCase)
            out = TestExamplesMsq3.runExampleNoBackend("example_8_msq3_membrane_wafer.m");
            tok = regexp(out, 'Example 8 placed chips: ([0-9]+)', 'tokens', 'once');
            testCase.assertFalse(isempty(tok));
            testCase.verifyEqual(str2double(tok{1}), 37);
        end

        function example9RunsHeadlessAndPlacesExpectedChipSplit(testCase)
            out = TestExamplesMsq3.runExampleNoBackend("example_9_msq3_meca_lc_wafer.m");
            tok = regexp(out, ...
                'Example 9 placed chips: ([0-9]+) \(with_dc_bias=([0-9]+), without_dc_bias=([0-9]+)\)', ...
                'tokens', 'once');
            testCase.assertFalse(isempty(tok));
            testCase.verifyEqual(str2double(tok{1}), 12);
            testCase.verifyEqual(str2double(tok{2}), 6);
            testCase.verifyEqual(str2double(tok{3}), 6);
        end
    end

    methods (Static, Access=private)
        function out = runExampleNoBackend(script_name)
            root_dir = fileparts(fileparts(mfilename("fullpath")));
            script_path = fullfile(root_dir, script_name);
            if ~isfile(script_path)
                error("Missing example script: %s", script_path);
            end

            src = fileread(script_path);
            src = regexprep(src, "use_comsol\s*=\s*true;", "use_comsol = false;");
            src = regexprep(src, "use_gds\s*=\s*true;", "use_gds = false;");
            src = regexprep(src, "preview_klayout\s*=\s*true;", "preview_klayout = false;");

            tmp_path = [tempname, '.m'];
            fid = fopen(char(tmp_path), 'w');
            if fid < 0
                error("Could not create temporary script file.");
            end
            fwrite(fid, src);
            fclose(fid);
            cleanup_tmp = onCleanup(@() TestExamplesMsq3.safeDelete(tmp_path)); %#ok<NASGU>

            out = evalc("run('" + strrep(tmp_path, filesep, "/") + "');");
        end

        function safeDelete(path_str)
            if isfile(path_str)
                delete(path_str);
            end
        end
    end
end
