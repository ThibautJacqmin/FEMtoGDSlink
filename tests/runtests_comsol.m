function results = runtests_comsol(args)
% Run COMSOL integration tests (auto-skips if COMSOL API is unavailable).
arguments
    args.initialize_comsol logical = true
end

this_file = mfilename('fullpath');
tests_dir = fileparts(this_file);
root_dir = fileparts(tests_dir);
addpath(root_dir);
addpath(tests_dir);

if args.initialize_comsol
    init_script = fullfile(root_dir, "tests", "helpers", "comsol_matlab_initialization.m");
    if isfile(init_script)
        try
            run(init_script);
        catch ex
            warning("runtests_comsol:InitializationFailed", ...
                "COMSOL initialization script failed (%s). Tests may be skipped.", ex.message);
        end
    end
end

suite = [ ...
    testsuite("tests/TestComsolBackend.m"), ...
    testsuite("tests/TestComsolMphBackend.m") ...
];
results = run(suite);
disp(results);
end
