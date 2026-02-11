function results = runtests_all
% Run all test suites in the tests folder.
this_file = mfilename('fullpath');
tests_dir = fileparts(this_file);
root_dir = fileparts(tests_dir);
addpath(root_dir);
addpath(tests_dir);

suite = testsuite("tests");
results = run(suite);
disp(results);
end
