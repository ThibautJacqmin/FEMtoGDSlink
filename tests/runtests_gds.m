function results = runtests_gds
% Run GDS unit tests (skips if KLayout Python module is unavailable).
suite = testsuite("tests/TestGdsBackend.m");
results = run(suite);
disp(results);
end
