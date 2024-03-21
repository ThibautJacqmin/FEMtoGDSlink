


% Create material
comsol_modeler.add_material(poisson_ratio=0.23, youngs_modulus=250e9, density=3200)
comsol_modeler.add_mesh(meshsize=4);

physics = comsol_modeler.component.physics.create('solid1', 'SolidMechanics', 'Geometry');
%physics.field('displacement').field('u2');
%physics.field('displacement').component({'u2' 'v2' 'w2'});
physics.create('fix1', 'Fixed', 1);
physics.feature('fix1').selection.set([2 4 204 207 209 214]);

