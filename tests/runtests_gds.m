function results = runtests_gds
% Run GDS unit tests (skips if KLayout Python module is unavailable).
this_file = mfilename('fullpath');
tests_dir = fileparts(this_file);
root_dir = fileparts(tests_dir);
addpath(root_dir);
addpath(tests_dir);

suite = testsuite("tests/TestGdsBackend.m");
results = run(suite);
disp(results);
end
