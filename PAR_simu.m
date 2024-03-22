


% Create material
comsol_modeler.add_material(poisson_ratio=0.23, youngs_modulus=250e9, density=3200)
% Add physics (shell)
comsol_modeler.add_physics(thickness=100e-9, ...
                           stress = 800e6,...
                           fixed_boundaries=[2, 4, 204, 207, 209, 214, 352]);
% Add mesh
comsol_modeler.add_mesh(4);

% Add study
comsol_modeler.add_study;


%physics.field('displacement').field('u2');
%physics.field('displacement').component({'u2' 'v2' 'w2'});
physics.create('fix1', 'Fixed', 1);
physics.feature('fix1').selection.set([2 4 204 207 209 214]);

