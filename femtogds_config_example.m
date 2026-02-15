function cfg = femtogds_config_example
%FEMTOGDS_CONFIG_EXAMPLE Example local installation/configuration values.
% Keep this file as a template. Local machine values belong in femtogds_config.m.

cfg = struct();

cfg.comsol = struct();
cfg.comsol.root = "C:\Program Files\COMSOL\COMSOL64\Multiphysics";
cfg.comsol.host = "localhost";
cfg.comsol.port = 2036;

cfg.klayout = struct();
cfg.klayout.root = "C:\Program Files\KLayout";
% Optional extra Python module paths for KLayout bindings.
cfg.klayout.python_paths = strings(0, 1);
% Optional extra binary directories for DLL lookup on Windows.
cfg.klayout.bin_paths = strings(0, 1);
end
