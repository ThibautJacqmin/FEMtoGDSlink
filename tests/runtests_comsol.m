function results = runtests_comsol
% Run COMSOL integration tests (auto-skips if COMSOL API is unavailable).
this_file = mfilename('fullpath');
tests_dir = fileparts(this_file);
root_dir = fileparts(tests_dir);
addpath(root_dir);
addpath(tests_dir);

suite = testsuite("tests/TestComsolBackend.m");
results = run(suite);
disp(results);
end
