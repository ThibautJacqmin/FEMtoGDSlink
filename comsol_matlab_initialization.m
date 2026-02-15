root_dir = fileparts(mfilename("fullpath"));
addpath(root_dir);
cfg = core.ProjectConfig.load(reload=true);

comsol_root = string(cfg.comsol.root);
if strlength(comsol_root) == 0
    error("comsol_matlab_initialization:MissingComsolRoot", ...
        "Set cfg.comsol.root in femtogds_config.m before running initialization.");
end

mli_path = fullfile(char(comsol_root), "mli");
if ~isfolder(mli_path)
    error("comsol_matlab_initialization:MissingMliPath", ...
        "COMSOL mli path not found: %s", mli_path);
end

addpath(mli_path);
which mphstart -all
mphstart(char(cfg.comsol.host), double(cfg.comsol.port));
