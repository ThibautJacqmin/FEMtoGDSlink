function out = model
%
% untitled.m
%
% Model exported on Mar 22 2024, 11:23 by COMSOL 6.1.0.282.

import com.comsol.model.*
import com.comsol.model.util.*

model = ModelUtil.create('Model');

model.modelPath('/home/stationjacqmin/Desktop/Thibaut');

model.param.set('L', '2e-3');
model.param.descr('L', 'side length');
model.param.set('thickness', '100e-9');
model.param.descr('thickness', 'thickness');
model.param.set('sigma', '900e6');
model.param.descr('sigma', 'stress');
model.param.set('radius', '100e-6');
model.param.descr('radius', 'sphere radius');

model.component.create('comp1', true);

model.component('comp1').geom.create('geom1', 3);

model.component('comp1').mesh.create('mesh1');

model.component('comp1').geom('geom1').create('sph1', 'Sphere');
model.component('comp1').geom('geom1').feature('sph1').set('pos', {'0' '0' 'radius'});
model.component('comp1').geom('geom1').feature('sph1').set('r', 'radius');
model.component('comp1').geom('geom1').run('sph1');
model.component('comp1').geom('geom1').run('sph1');
model.component('comp1').geom('geom1').create('wp1', 'WorkPlane');
model.component('comp1').geom('geom1').feature('wp1').set('unite', true);
model.component('comp1').geom('geom1').feature('wp1').geom.create('sq1', 'Square');
model.component('comp1').geom('geom1').feature('wp1').geom.feature('sq1').set('size', 'L');
model.component('comp1').geom('geom1').feature('wp1').geom.feature('sq1').set('base', 'center');
model.component('comp1').geom('geom1').feature('wp1').geom.run('sq1');
model.component('comp1').geom('geom1').run('fin');

model.component('comp1').material.create('mat1', 'Common');
model.component('comp1').material('mat1').propertyGroup.create('Enu', 'Young''s modulus and Poisson''s ratio');
model.component('comp1').material('mat1').label('Au - Gold');
model.component('comp1').material('mat1').set('family', 'gold');
model.component('comp1').material('mat1').propertyGroup('def').set('electricconductivity', {'45.6e6[S/m]' '0' '0' '0' '45.6e6[S/m]' '0' '0' '0' '45.6e6[S/m]'});
model.component('comp1').material('mat1').propertyGroup('def').set('thermalexpansioncoefficient', {'14.2e-6[1/K]' '0' '0' '0' '14.2e-6[1/K]' '0' '0' '0' '14.2e-6[1/K]'});
model.component('comp1').material('mat1').propertyGroup('def').set('heatcapacity', '129[J/(kg*K)]');
model.component('comp1').material('mat1').propertyGroup('def').set('density', '19300[kg/m^3]');
model.component('comp1').material('mat1').propertyGroup('def').set('thermalconductivity', {'317[W/(m*K)]' '0' '0' '0' '317[W/(m*K)]' '0' '0' '0' '317[W/(m*K)]'});
model.component('comp1').material('mat1').propertyGroup('Enu').set('E', '');
model.component('comp1').material('mat1').propertyGroup('Enu').set('nu', '');
model.component('comp1').material('mat1').propertyGroup('Enu').set('E', '');
model.component('comp1').material('mat1').propertyGroup('Enu').set('nu', '');
model.component('comp1').material('mat1').propertyGroup('Enu').set('E', '70e9[Pa]');
model.component('comp1').material('mat1').propertyGroup('Enu').set('nu', '0.44');
model.component('comp1').material('mat1').set('family', 'gold');
model.component('comp1').material.create('mat2', 'Common');
model.component('comp1').material('mat2').propertyGroup.create('Enu', 'Young''s modulus and Poisson''s ratio');
model.component('comp1').material('mat2').label('Si3N4 - Silicon nitride');
model.component('comp1').material('mat2').propertyGroup('def').set('electricconductivity', {'0[S/m]' '0' '0' '0' '0[S/m]' '0' '0' '0' '0[S/m]'});
model.component('comp1').material('mat2').propertyGroup('def').set('thermalexpansioncoefficient', {'2.3e-6[1/K]' '0' '0' '0' '2.3e-6[1/K]' '0' '0' '0' '2.3e-6[1/K]'});
model.component('comp1').material('mat2').propertyGroup('def').set('heatcapacity', '700[J/(kg*K)]');
model.component('comp1').material('mat2').propertyGroup('def').set('relpermittivity', {'9.7' '0' '0' '0' '9.7' '0' '0' '0' '9.7'});
model.component('comp1').material('mat2').propertyGroup('def').set('density', '3100[kg/m^3]');
model.component('comp1').material('mat2').propertyGroup('def').set('thermalconductivity', {'20[W/(m*K)]' '0' '0' '0' '20[W/(m*K)]' '0' '0' '0' '20[W/(m*K)]'});
model.component('comp1').material('mat2').propertyGroup('Enu').set('E', '');
model.component('comp1').material('mat2').propertyGroup('Enu').set('nu', '');
model.component('comp1').material('mat2').propertyGroup('Enu').set('E', '');
model.component('comp1').material('mat2').propertyGroup('Enu').set('nu', '');
model.component('comp1').material('mat2').propertyGroup('Enu').set('E', '250e9[Pa]');
model.component('comp1').material('mat2').propertyGroup('Enu').set('nu', '0.23');
model.component('comp1').material('mat2').set('family', 'plastic');
model.component('comp1').material.remove('mat2');

model.component('comp1').physics.create('shell', 'Shell', 'geom1');
model.component('comp1').physics('shell').selection.set([1]);
model.component('comp1').physics('shell').feature('emm1').set('E_mat', 'userdef');
model.component('comp1').physics('shell').feature('emm1').set('E', '250e9');
model.component('comp1').physics('shell').feature('emm1').set('nu_mat', 'userdef');
model.component('comp1').physics('shell').feature('emm1').set('nu', 0.23);
model.component('comp1').physics('shell').feature('emm1').set('rho_mat', 'userdef');
model.component('comp1').physics('shell').feature('emm1').set('rho', 3200);
model.component('comp1').physics('shell').feature('to1').set('d', 'thickness');
model.component('comp1').physics('shell').feature('emm1').create('iss1', 'InitialStressandStrain', 2);
model.component("Component").physics("shell").feature("emm1").create("iss1", "InitialStressandStrain", 2);
model.component('comp1').physics('shell').feature('emm1').feature('iss1').set('Ni', {'sigma*thickness' '0' '0' 'sigma*thickness'});
model.component('comp1').physics('shell').create('fix1', 'Fixed', 1);
model.component('comp1').physics('shell').feature('fix1').selection.set([1 2 3 16]);
model.component('comp1').physics.create('solid', 'SolidMechanics', 'geom1');
model.component('comp1').physics('solid').create('gr1', 'Gravity', 3);
model.component('comp1').physics('solid').feature('gr1').selection.set([1]);

model.component('comp1').mesh('mesh1').run;

model.study.create('std1');
model.study('std1').create('stat', 'Stationary');
model.study('std1').feature('stat').setSolveFor('/physics/shell', true);
model.study('std1').feature('stat').setSolveFor('/physics/solid', true);
model.study('std1').create('eig', 'Eigenfrequency');
model.study('std1').feature('eig').set('conrad', '1');
model.study('std1').feature('eig').set('geometricNonlinearity', true);
model.study('std1').feature('eig').setSolveFor('/physics/shell', true);
model.study('std1').feature('eig').setSolveFor('/physics/solid', true);

model.component('comp1').common.create('mpf1', 'ParticipationFactors');

model.study('std1').feature('stat').set('geometricNonlinearity', true);
model.study('std1').feature('eig').set('eigmethod', 'region');
model.study('std1').feature('eig').set('eigunit', 'kHz');
model.study('std1').feature('eig').set('eigsr', 1);
model.study('std1').feature('eig').set('eiglr', 100);

model.sol.create('sol1');
model.sol('sol1').study('std1');

model.study('std1').feature('stat').set('notlistsolnum', 1);
model.study('std1').feature('stat').set('notsolnum', 'auto');
model.study('std1').feature('stat').set('listsolnum', 1);
model.study('std1').feature('stat').set('solnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', 1);
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', 1);
model.study('std1').feature('eig').set('solnum', 'auto');

model.sol('sol1').create('st1', 'StudyStep');
model.sol('sol1').feature('st1').set('study', 'std1');
model.sol('sol1').feature('st1').set('studystep', 'stat');
model.sol('sol1').create('v1', 'Variables');
model.sol('sol1').feature('v1').set('control', 'stat');
model.sol('sol1').create('s1', 'Stationary');
model.sol('sol1').feature('s1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('s1').create('se1', 'Segregated');
model.sol('sol1').feature('s1').feature('se1').feature.remove('ssDef');
model.sol('sol1').feature('s1').feature('se1').create('ss1', 'SegregatedStep');
model.sol('sol1').feature('s1').feature('se1').feature('ss1').set('segvar', {'comp1_u' 'comp1_ar'});
model.sol('sol1').feature('s1').feature('se1').feature('ss1').set('linsolver', 'dDef');
model.sol('sol1').feature('s1').feature('se1').feature('ss1').label('Shell');
model.sol('sol1').feature('s1').feature('se1').create('ss2', 'SegregatedStep');
model.sol('sol1').feature('s1').feature('se1').feature('ss2').set('segvar', {'comp1_u2'});
model.sol('sol1').feature('s1').create('d1', 'Direct');
model.sol('sol1').feature('s1').feature('d1').set('linsolver', 'pardiso');
model.sol('sol1').feature('s1').feature('d1').set('pivotperturb', 1.0E-9);
model.sol('sol1').feature('s1').feature('d1').set('nliniterrefine', true);
model.sol('sol1').feature('s1').feature('d1').label('Suggested Direct Solver (solid)');
model.sol('sol1').feature('s1').feature('se1').feature('ss2').set('linsolver', 'd1');
model.sol('sol1').feature('s1').feature('se1').feature('ss2').label('Solid Mechanics');
model.sol('sol1').feature('s1').create('i1', 'Iterative');
model.sol('sol1').feature('s1').feature('i1').set('linsolver', 'gmres');
model.sol('sol1').feature('s1').feature('i1').set('prefuntype', 'right');
model.sol('sol1').feature('s1').feature('i1').set('rhob', 40);
model.sol('sol1').feature('s1').feature('i1').set('nlinnormuse', true);
model.sol('sol1').feature('s1').feature('i1').label('Suggested Iterative Solver (solid)');
model.sol('sol1').feature('s1').feature('i1').create('mg1', 'Multigrid');
model.sol('sol1').feature('s1').feature('i1').feature('mg1').set('prefun', 'gmg');
model.sol('sol1').feature('s1').feature('i1').feature('mg1').feature('pr').create('so1', 'SOR');
model.sol('sol1').feature('s1').feature('i1').feature('mg1').feature('pr').feature('so1').set('iter', 1);
model.sol('sol1').feature('s1').feature('i1').feature('mg1').feature('po').create('so1', 'SOR');
model.sol('sol1').feature('s1').feature('i1').feature('mg1').feature('po').feature('so1').set('iter', 1);
model.sol('sol1').feature('s1').feature('i1').feature('mg1').feature('cs').create('mg1', 'Multigrid');
model.sol('sol1').feature('s1').feature('i1').feature('mg1').feature('cs').feature('mg1').set('prefun', 'saamg');
model.sol('sol1').feature('s1').feature('i1').feature('mg1').feature('cs').feature('mg1').set('usesmooth', false);
model.sol('sol1').feature('s1').feature('i1').feature('mg1').feature('cs').feature('mg1').set('iter', 2);
model.sol('sol1').feature('s1').feature('i1').feature('mg1').feature('cs').feature('mg1').set('mglevels', 2);
model.sol('sol1').feature('s1').feature('i1').feature('mg1').feature('cs').feature('mg1').set('maxcoarsedof', 10000);
model.sol('sol1').feature('s1').feature.remove('fcDef');
model.sol('sol1').create('su1', 'StoreSolution');
model.sol('sol1').create('st2', 'StudyStep');
model.sol('sol1').feature('st2').set('study', 'std1');
model.sol('sol1').feature('st2').set('studystep', 'eig');
model.sol('sol1').create('v2', 'Variables');
model.sol('sol1').feature('v2').set('initmethod', 'sol');
model.sol('sol1').feature('v2').set('initsol', 'sol1');
model.sol('sol1').feature('v2').set('initsoluse', 'su1');
model.sol('sol1').feature('v2').set('notsolmethod', 'sol');
model.sol('sol1').feature('v2').set('notsol', 'sol1');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').create('e1', 'Eigenvalue');
model.sol('sol1').feature('e1').set('eigvfunscale', 'maximum');
model.sol('sol1').feature('e1').set('eigvfunscaleparam', '2.84E-9');
model.sol('sol1').feature('e1').set('storelinpoint', true);
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').set('linpmethod', 'sol');
model.sol('sol1').feature('e1').set('linpsol', 'sol1');
model.sol('sol1').feature('e1').set('linpsoluse', 'su1');
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notsolvertype', 'solnum');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').attach('std1');

model.result.dataset.create('shl1', 'Shell');
model.result.dataset('shl1').set('data', 'dset1');
model.result.dataset('shl1').setIndex('orientationexpr', 'shell.nlX', 0);
model.result.dataset('shl1').setIndex('orientationexpr', 'shell.nlY', 1);
model.result.dataset('shl1').setIndex('orientationexpr', 'shell.nlZ', 2);
model.result.dataset('shl1').set('distanceexpr', 'shell.z_pos');
model.result.dataset('shl1').set('seplevels', false);
model.result.dataset('shl1').set('resolution', 2);
model.result.dataset('shl1').set('areascalefactor', 'shell.ASF');
model.result.dataset('shl1').set('linescalefactor', 'shell.LSF');
model.result.create('pg1', 'PlotGroup3D');
model.result('pg1').set('data', 'dset1');
model.result('pg1').set('showlegends', false);
model.result('pg1').set('data', 'shl1');
model.result('pg1').create('surf1', 'Surface');
model.result('pg1').feature('surf1').set('expr', {'shell.disp'});
model.result('pg1').feature('surf1').set('threshold', 'manual');
model.result('pg1').feature('surf1').set('thresholdvalue', 0.2);
model.result('pg1').label('Mode Shape (shell)');
model.result('pg1').feature('surf1').set('colortable', 'AuroraBorealis');
model.result('pg1').feature('surf1').create('def', 'Deform');
model.result('pg1').feature('surf1').feature('def').set('expr', {'shell.u' 'shell.v' 'shell.w'});
model.result.create('pg2', 'PlotGroup3D');
model.result('pg2').set('data', 'dset1');
model.result('pg2').label('Shell Geometry (shell)');
model.result('pg2').set('titletype', 'label');
model.result('pg2').set('showlegends', false);
model.result('pg2').set('edgecolor', 'cyan');
model.result('pg2').create('surf1', 'Surface');
model.result('pg2').feature('surf1').set('expr', {'if(abs(shell.z)==1,shell.z, NaN)'});
model.result('pg2').feature('surf1').set('threshold', 'manual');
model.result('pg2').feature('surf1').set('thresholdvalue', 0.2);
model.result('pg2').feature('surf1').set('data', 'shl1');
model.result('pg2').feature('surf1').label('Top and Bottom');
model.result('pg2').feature('surf1').set('colortable', 'RainbowLight');
model.result.create('pg3', 'PlotGroup3D');
model.result('pg3').set('data', 'dset1');
model.result('pg3').label('Thickness and Orientation (shell)');
model.result('pg3').set('titletype', 'label');
model.result('pg3').set('showlegendsunit', true);
model.result('pg3').create('surf1', 'Surface');
model.result('pg3').feature('surf1').set('expr', {'shell.d'});
model.result('pg3').feature('surf1').set('threshold', 'manual');
model.result('pg3').feature('surf1').set('thresholdvalue', 0.2);
model.result('pg3').feature('surf1').label('Thickness');
model.result('pg3').feature('surf1').set('colortable', 'HeatCameraLight');
model.result('pg3').feature('surf1').set('colortabletrans', 'reverse');
model.result('pg3').create('syss', 'CoordSysSurface');
model.result('pg3').feature('syss').set('sys', 'shellsys');
model.result('pg3').feature('syss').label('Shell Local System');
model.result.evaluationGroup.create('std1EvgFrq', 'EvaluationGroup');
model.result.evaluationGroup('std1EvgFrq').set('data', 'dset1');
model.result.evaluationGroup('std1EvgFrq').label('Eigenfrequencies (Study 1)');
model.result.evaluationGroup('std1EvgFrq').create('gev1', 'EvalGlobal');
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('expr', 'freq*2*pi', 0);
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('unit', 'rad/s', 0);
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('descr', 'Angular frequency', 0);
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('expr', 'imag(freq)/abs(freq)', 1);
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('unit', '1', 1);
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('descr', 'Damping ratio', 1);
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('expr', 'abs(freq)/imag(freq)/2', 2);
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('unit', '1', 2);
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('descr', 'Quality factor', 2);
model.result.dataset('dset1').set('frametype', 'spatial');
model.result.create('pg4', 'PlotGroup3D');
model.result('pg4').set('data', 'dset1');
model.result('pg4').set('frametype', 'spatial');
model.result('pg4').set('showlegends', false);
model.result('pg4').create('surf1', 'Surface');
model.result('pg4').feature('surf1').set('expr', {'solid.disp'});
model.result('pg4').feature('surf1').set('threshold', 'manual');
model.result('pg4').feature('surf1').set('thresholdvalue', 0.2);
model.result('pg4').label('Mode Shape (solid)');
model.result('pg4').feature('surf1').set('colortable', 'AuroraBorealis');
model.result('pg4').feature('surf1').create('def', 'Deform');
model.result('pg4').feature('surf1').feature('def').set('expr', {'u2' 'v2' 'w2'});
model.result('pg4').feature('surf1').feature('def').set('descr', 'Displacement field');
model.result.evaluationGroup.create('std1mpf1', 'EvaluationGroup');
model.result.evaluationGroup('std1mpf1').set('data', 'dset1');
model.result.evaluationGroup('std1mpf1').label('Participation Factors (Study 1)');
model.result.evaluationGroup('std1mpf1').create('gev1', 'EvalGlobal');
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.pfLnormX', 0);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', '1', 0);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Participation factor, normalized, X-translation', 0);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.pfLnormY', 1);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', '1', 1);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Participation factor, normalized, Y-translation', 1);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.pfLnormZ', 2);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', '1', 2);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Participation factor, normalized, Z-translation', 2);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.pfRnormX', 3);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', '1', 3);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Participation factor, normalized, X-rotation', 3);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.pfRnormY', 4);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', '1', 4);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Participation factor, normalized, Y-rotation', 4);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.pfRnormZ', 5);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', '1', 5);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Participation factor, normalized, Z-rotation', 5);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.mEffLX', 6);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', 'kg', 6);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Effective modal mass, X-translation', 6);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.mEffLY', 7);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', 'kg', 7);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Effective modal mass, Y-translation', 7);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.mEffLZ', 8);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', 'kg', 8);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Effective modal mass, Z-translation', 8);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.mEffRX', 9);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', 'kg*m^2', 9);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Effective modal mass, X-rotation', 9);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.mEffRY', 10);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', 'kg*m^2', 10);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Effective modal mass, Y-rotation', 10);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.mEffRZ', 11);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', 'kg*m^2', 11);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Effective modal mass, Z-rotation', 11);
model.result.remove('pg2');
model.result.remove('pg1');
model.result.remove('pg4');
model.result.remove('pg3');
model.result.evaluationGroup.remove('std1mpf1');
model.result.evaluationGroup.remove('std1EvgFrq');
model.result.dataset.remove('shl1');

model.label('sphere_on_square_membrane.mph');

model.param.set('sphere_position', '10e-6');

model.component('comp1').geom('geom1').feature('sph1').set('pos', {'0' '0' 'radius-sphere_position'});

model.param.set('L', '5e-3');
model.param.set('radius', '250e-6');
model.param.descr('sphere_position', 'sphere delta with respect to membrane');
model.param.descr('sphere_position', 'sphere delta z with respect to membrane');

model.component('comp1').geom('geom1').run('sph1');
model.component('comp1').geom('geom1').feature('wp1').geom.run('sq1');
model.component('comp1').geom('geom1').run('sph1');
model.component('comp1').geom('geom1').create('int1', 'Intersection');
model.component('comp1').geom('geom1').feature.move('int1', 2);
model.component('comp1').geom('geom1').runPre('int1');
model.component('comp1').geom('geom1').feature('int1').selection('input').set({'sph1' 'wp1'});
model.component('comp1').geom('geom1').feature('int1').set('keep', true);
model.component('comp1').geom('geom1').run('wp1');
model.component('comp1').geom('geom1').create('par1', 'Partition');
model.component('comp1').geom('geom1').feature('par1').selection('input').set({'wp1'});
model.component('comp1').geom('geom1').feature.remove('par1');
model.component('comp1').geom('geom1').run('wp1');
model.component('comp1').geom('geom1').create('pard1', 'PartitionDomains');
model.component('comp1').geom('geom1').feature('pard1').selection('domain').set('sph1', 1);
model.component('comp1').geom('geom1').run('pard1');
model.component('comp1').geom('geom1').run('pard1');
model.component('comp1').geom('geom1').create('del1', 'Delete');
model.component('comp1').geom('geom1').feature.move('del1', 4);
model.component('comp1').geom('geom1').feature.move('int1', 2);
model.component('comp1').geom('geom1').runPre('int1');
model.component('comp1').geom('geom1').feature('int1').selection('input').set({'wp1'});
model.component('comp1').geom('geom1').feature('int1').selection('input').init;
model.component('comp1').geom('geom1').feature('int1').selection('input').set({'sph1' 'wp1'});
model.component('comp1').geom('geom1').runPre('del1');
model.component('comp1').geom('geom1').feature('del1').selection('input').set('pard1', [5 7 10 11]);
model.component('comp1').geom('geom1').run('pard1');
model.component('comp1').geom('geom1').create('par1', 'Partition');
model.component('comp1').geom('geom1').feature.remove('par1');
model.component('comp1').geom('geom1').run('del1');
model.component('comp1').geom('geom1').run('fin');

model.component('comp1').multiphysics.create('sshc1', 'SolidShellConnection', -1);
model.component('comp1').multiphysics('sshc1').set('connectionSettings', 'sharedBnd');

model.component('comp1').mesh('mesh1').autoMeshSize(3);
model.component('comp1').mesh('mesh1').run;
model.component('comp1').mesh('mesh1').autoMeshSize(2);
model.component('comp1').mesh('mesh1').run;

model.study('std1').feature('eig').set('eigsr', 0.5);

model.sol('sol1').study('std1');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol2').copySolution('sol3');

model.result.dataset('dset2').set('solution', 'none');

model.study('std1').feature('stat').set('notlistsolnum', 1);
model.study('std1').feature('stat').set('notsolnum', 'auto');
model.study('std1').feature('stat').set('listsolnum', 1);
model.study('std1').feature('stat').set('solnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', 1);
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', 1);
model.study('std1').feature('eig').set('solnum', 'auto');

model.sol('sol1').feature.remove('e1');
model.sol('sol1').feature.remove('v2');
model.sol('sol1').feature.remove('st2');
model.sol('sol1').feature.remove('su1');
model.sol('sol1').feature.remove('s1');
model.sol('sol1').feature.remove('v1');
model.sol('sol1').feature.remove('st1');
model.sol('sol3').copySolution('sol2');
model.sol.remove('sol3');
model.sol('sol2').label('Solution Store 1');

model.result.dataset.remove('dset4');

model.sol('sol1').create('st1', 'StudyStep');
model.sol('sol1').feature('st1').set('study', 'std1');
model.sol('sol1').feature('st1').set('studystep', 'stat');
model.sol('sol1').create('v1', 'Variables');
model.sol('sol1').feature('v1').set('control', 'stat');
model.sol('sol1').create('s1', 'Stationary');
model.sol('sol1').feature('s1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('s1').create('seDef', 'Segregated');
model.sol('sol1').feature('s1').create('fc1', 'FullyCoupled');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'dDef');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature.remove('fcDef');
model.sol('sol1').feature('s1').feature.remove('seDef');
model.sol('sol1').create('su1', 'StoreSolution');
model.sol('sol1').feature('su1').set('sol', 'sol2');
model.sol('sol1').feature('su1').label('Solution Store 1');
model.sol('sol1').create('st2', 'StudyStep');
model.sol('sol1').feature('st2').set('study', 'std1');
model.sol('sol1').feature('st2').set('studystep', 'eig');
model.sol('sol1').create('v2', 'Variables');
model.sol('sol1').feature('v2').set('initmethod', 'sol');
model.sol('sol1').feature('v2').set('initsol', 'sol1');
model.sol('sol1').feature('v2').set('initsoluse', 'su1');
model.sol('sol1').feature('v2').set('notsolmethod', 'sol');
model.sol('sol1').feature('v2').set('notsol', 'sol1');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').create('e1', 'Eigenvalue');
model.sol('sol1').feature('e1').set('eigvfunscale', 'maximum');
model.sol('sol1').feature('e1').set('eigvfunscaleparam', '7.089999999999999E-9');
model.sol('sol1').feature('e1').set('storelinpoint', true);
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').set('linpmethod', 'sol');
model.sol('sol1').feature('e1').set('linpsol', 'sol1');
model.sol('sol1').feature('e1').set('linpsoluse', 'su1');
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').feature('aDef').set('cachepattern', true);

model.result.dataset('dset2').set('solution', 'sol2');

model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notsolvertype', 'solnum');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('control', 'eig');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol1').attach('std1');

model.result.dataset.create('shl1', 'Shell');
model.result.dataset('shl1').set('data', 'dset1');
model.result.dataset('shl1').setIndex('topconst', '1', 3, 1);
model.result.dataset('shl1').setIndex('bottomconst', '-1', 3, 1);
model.result.dataset('shl1').setIndex('orientationexpr', 'shell.nlX', 0);
model.result.dataset('shl1').setIndex('orientationexpr', 'shell.nlY', 1);
model.result.dataset('shl1').setIndex('orientationexpr', 'shell.nlZ', 2);
model.result.dataset('shl1').set('distanceexpr', 'shell.z_pos');
model.result.dataset('shl1').set('seplevels', false);
model.result.dataset('shl1').set('resolution', 2);
model.result.dataset('shl1').set('areascalefactor', 'shell.ASF');
model.result.dataset('shl1').set('linescalefactor', 'shell.LSF');
model.result.create('pg1', 'PlotGroup3D');
model.result('pg1').set('data', 'dset1');
model.result('pg1').set('showlegends', false);
model.result('pg1').set('data', 'shl1');
model.result('pg1').create('surf1', 'Surface');
model.result('pg1').feature('surf1').set('expr', {'shell.disp'});
model.result('pg1').feature('surf1').set('threshold', 'manual');
model.result('pg1').feature('surf1').set('thresholdvalue', 0.2);
model.result('pg1').label('Mode Shape (shell)');
model.result('pg1').feature('surf1').set('colortable', 'AuroraBorealis');
model.result('pg1').feature('surf1').create('def', 'Deform');
model.result('pg1').feature('surf1').feature('def').set('expr', {'shell.u' 'shell.v' 'shell.w'});
model.result.create('pg2', 'PlotGroup3D');
model.result('pg2').set('data', 'dset1');
model.result('pg2').label('Shell Geometry (shell)');
model.result('pg2').set('titletype', 'label');
model.result('pg2').set('showlegends', false);
model.result('pg2').set('edgecolor', 'cyan');
model.result('pg2').create('surf1', 'Surface');
model.result('pg2').feature('surf1').set('expr', {'if(abs(shell.z)==1,shell.z, NaN)'});
model.result('pg2').feature('surf1').set('threshold', 'manual');
model.result('pg2').feature('surf1').set('thresholdvalue', 0.2);
model.result('pg2').feature('surf1').set('data', 'shl1');
model.result('pg2').feature('surf1').label('Top and Bottom');
model.result('pg2').feature('surf1').set('colortable', 'RainbowLight');
model.result.create('pg3', 'PlotGroup3D');
model.result('pg3').set('data', 'dset1');
model.result('pg3').label('Thickness and Orientation (shell)');
model.result('pg3').set('titletype', 'label');
model.result('pg3').set('showlegendsunit', true);
model.result('pg3').create('surf1', 'Surface');
model.result('pg3').feature('surf1').set('expr', {'shell.d'});
model.result('pg3').feature('surf1').set('threshold', 'manual');
model.result('pg3').feature('surf1').set('thresholdvalue', 0.2);
model.result('pg3').feature('surf1').label('Thickness');
model.result('pg3').feature('surf1').set('colortable', 'HeatCameraLight');
model.result('pg3').feature('surf1').set('colortabletrans', 'reverse');
model.result('pg3').create('syss', 'CoordSysSurface');
model.result('pg3').feature('syss').set('sys', 'shellsys');
model.result('pg3').feature('syss').label('Shell Local System');
model.result.evaluationGroup.create('std1EvgFrq', 'EvaluationGroup');
model.result.evaluationGroup('std1EvgFrq').set('data', 'dset1');
model.result.evaluationGroup('std1EvgFrq').label('Eigenfrequencies (Study 1)');
model.result.evaluationGroup('std1EvgFrq').create('gev1', 'EvalGlobal');
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('expr', 'freq*2*pi', 0);
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('unit', 'rad/s', 0);
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('descr', 'Angular frequency', 0);
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('expr', 'imag(freq)/abs(freq)', 1);
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('unit', '1', 1);
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('descr', 'Damping ratio', 1);
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('expr', 'abs(freq)/imag(freq)/2', 2);
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('unit', '1', 2);
model.result.evaluationGroup('std1EvgFrq').feature('gev1').setIndex('descr', 'Quality factor', 2);
model.result.dataset('dset1').set('frametype', 'spatial');
model.result.create('pg4', 'PlotGroup3D');
model.result('pg4').set('data', 'dset1');
model.result('pg4').set('frametype', 'spatial');
model.result('pg4').set('showlegends', false);
model.result('pg4').create('surf1', 'Surface');
model.result('pg4').feature('surf1').set('expr', {'solid.disp'});
model.result('pg4').feature('surf1').set('threshold', 'manual');
model.result('pg4').feature('surf1').set('thresholdvalue', 0.2);
model.result('pg4').label('Mode Shape (solid)');
model.result('pg4').feature('surf1').set('colortable', 'AuroraBorealis');
model.result('pg4').feature('surf1').create('def', 'Deform');
model.result('pg4').feature('surf1').feature('def').set('expr', {'u2' 'v2' 'w2'});
model.result('pg4').feature('surf1').feature('def').set('descr', 'Displacement field');
model.result.evaluationGroup.create('std1mpf1', 'EvaluationGroup');
model.result.evaluationGroup('std1mpf1').set('data', 'dset1');
model.result.evaluationGroup('std1mpf1').label('Participation Factors (Study 1)');
model.result.evaluationGroup('std1mpf1').create('gev1', 'EvalGlobal');
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.pfLnormX', 0);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', '1', 0);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Participation factor, normalized, X-translation', 0);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.pfLnormY', 1);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', '1', 1);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Participation factor, normalized, Y-translation', 1);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.pfLnormZ', 2);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', '1', 2);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Participation factor, normalized, Z-translation', 2);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.pfRnormX', 3);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', '1', 3);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Participation factor, normalized, X-rotation', 3);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.pfRnormY', 4);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', '1', 4);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Participation factor, normalized, Y-rotation', 4);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.pfRnormZ', 5);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', '1', 5);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Participation factor, normalized, Z-rotation', 5);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.mEffLX', 6);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', 'kg', 6);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Effective modal mass, X-translation', 6);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.mEffLY', 7);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', 'kg', 7);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Effective modal mass, Y-translation', 7);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.mEffLZ', 8);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', 'kg', 8);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Effective modal mass, Z-translation', 8);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.mEffRX', 9);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', 'kg*m^2', 9);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Effective modal mass, X-rotation', 9);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.mEffRY', 10);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', 'kg*m^2', 10);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Effective modal mass, Y-rotation', 10);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('expr', 'mpf1.mEffRZ', 11);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('unit', 'kg*m^2', 11);
model.result.evaluationGroup('std1mpf1').feature('gev1').setIndex('descr', 'Effective modal mass, Z-rotation', 11);

model.sol('sol1').runAll;

model.result('pg1').run;
model.result.evaluationGroup('std1EvgFrq').run;
model.result.evaluationGroup('std1mpf1').run;
model.result('pg1').run;
model.result('pg1').run;

model.nodeGroup.create('grp1', 'Results');
model.nodeGroup('grp1').set('type', 'plotgroup');
model.nodeGroup('grp1').add('plotgroup', 'pg1');

model.result('pg4').run;

model.nodeGroup('grp1').add('plotgroup', 'pg4');
model.nodeGroup('grp1').remove('plotgroup', 'pg4', true);
model.nodeGroup('grp1').add('plotgroup', 'pg4');
model.nodeGroup('grp1').remove('plotgroup', 'pg4', false);
model.nodeGroup('grp1').add('plotgroup', 'pg4');
model.nodeGroup('grp1').remove('plotgroup', 'pg4', false);

model.result('pg4').run;

model.nodeGroup('grp1').add('plotgroup', 'pg4');

model.result('pg1').run;
model.result('pg1').run;
model.result('pg4').run;
model.result('pg1').feature.copy('surf2', 'pg4/surf1');
model.result('pg4').feature.remove('surf1');
model.result('pg4').run;
model.result.remove('pg4');
model.result('pg1').run;
model.result('pg1').label('Mode Shape');
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result.create('pg4', 'PlotGroup3D');

model.nodeGroup('grp1').add('plotgroup', 'pg4');

model.result('pg4').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').feature('surf1').set('data', 'dset1');
model.result('pg1').run;
model.result('pg1').feature('surf2').set('data', 'dset2');
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').feature('surf1').set('solutionparams', 'parent');
model.result('pg1').run;
model.result('pg1').feature('surf2').set('data', 'shl1');
model.result('pg1').feature('surf2').set('solutionparams', 'parent');
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').set('data', 'none');
model.result('pg1').run;
model.result('pg1').set('data', 'dset1');
model.result('pg1').run;
model.result('pg1').set('data', 'dset2');
model.result('pg1').run;
model.result('pg1').set('data', 'shl1');
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').set('data', 'dset1');
model.result('pg1').run;
model.result('pg1').run;

model.nodeGroup('grp1').remove('plotgroup', 'pg1', true);

model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').set('data', 'dset1');
model.result('pg1').run;
model.result('pg1').feature('surf1').set('data', 'dset2');
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').feature('surf1').feature('def').set('scaleactive', true);
model.result('pg1').run;
model.result('pg1').feature('surf2').feature('def').set('scaleactive', true);
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').feature('surf1').feature('def').set('scale', 2.26500352732668E7);
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').feature('surf1').feature('def').set('scale', 2000);
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').feature('surf1').feature('def').set('scale', '2e7');
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').set('data', 'dset2');
model.result('pg1').run;
model.result('pg1').set('data', 'dset1');
model.result('pg1').run;
model.result('pg1').feature('surf1').set('data', 'dset1');
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').feature('surf2').set('data', 'dset2');
model.result('pg1').run;
model.result('pg1').feature('surf2').set('data', 'dset1');
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').feature('surf1').feature('def').set('scale', 2.26500352732668E7);
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').set('looplevel', [3]);
model.result('pg1').run;

model.label('sphere_on_square_membrane.mph');

model.result('pg1').run;

model.component('comp1').mesh('mesh1').run;

model.result('pg1').run;

model.sol('sol1').copySolution('sol3');

model.result.dataset('dset3').label('Loaded membrane stress');
model.result.dataset('dset3').label('Loaded membrane stress 900 MPa');

model.param.set('sigma', '0e6');

model.sol('sol1').study('std1');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol2').copySolution('sol4');

model.result.dataset('dset2').set('solution', 'none');

model.study('std1').feature('stat').set('notlistsolnum', 1);
model.study('std1').feature('stat').set('notsolnum', 'auto');
model.study('std1').feature('stat').set('listsolnum', 1);
model.study('std1').feature('stat').set('solnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', 1);
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', 1);
model.study('std1').feature('eig').set('solnum', 'auto');

model.sol('sol1').feature.remove('e1');
model.sol('sol1').feature.remove('v2');
model.sol('sol1').feature.remove('st2');
model.sol('sol1').feature.remove('su1');
model.sol('sol1').feature.remove('s1');
model.sol('sol1').feature.remove('v1');
model.sol('sol1').feature.remove('st1');
model.sol('sol4').copySolution('sol2');
model.sol.remove('sol4');
model.sol('sol2').label('Solution Store 1');

model.result.dataset.remove('dset5');

model.sol('sol1').create('st1', 'StudyStep');
model.sol('sol1').feature('st1').set('study', 'std1');
model.sol('sol1').feature('st1').set('studystep', 'stat');
model.sol('sol1').create('v1', 'Variables');
model.sol('sol1').feature('v1').set('control', 'stat');
model.sol('sol1').create('s1', 'Stationary');
model.sol('sol1').feature('s1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('s1').create('seDef', 'Segregated');
model.sol('sol1').feature('s1').create('fc1', 'FullyCoupled');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'dDef');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature.remove('fcDef');
model.sol('sol1').feature('s1').feature.remove('seDef');
model.sol('sol1').create('su1', 'StoreSolution');
model.sol('sol1').feature('su1').set('sol', 'sol2');
model.sol('sol1').feature('su1').label('Solution Store 1');
model.sol('sol1').create('st2', 'StudyStep');
model.sol('sol1').feature('st2').set('study', 'std1');
model.sol('sol1').feature('st2').set('studystep', 'eig');
model.sol('sol1').create('v2', 'Variables');
model.sol('sol1').feature('v2').set('initmethod', 'sol');
model.sol('sol1').feature('v2').set('initsol', 'sol1');
model.sol('sol1').feature('v2').set('initsoluse', 'su1');
model.sol('sol1').feature('v2').set('notsolmethod', 'sol');
model.sol('sol1').feature('v2').set('notsol', 'sol1');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').create('e1', 'Eigenvalue');
model.sol('sol1').feature('e1').set('eigvfunscale', 'maximum');
model.sol('sol1').feature('e1').set('eigvfunscaleparam', '7.089999999999999E-9');
model.sol('sol1').feature('e1').set('storelinpoint', true);
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').set('linpmethod', 'sol');
model.sol('sol1').feature('e1').set('linpsol', 'sol1');
model.sol('sol1').feature('e1').set('linpsoluse', 'su1');
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').feature('aDef').set('cachepattern', true);

model.result.dataset('dset2').set('solution', 'sol2');

model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notsolvertype', 'solnum');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('control', 'eig');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol1').attach('std1');
model.sol('sol1').runAll;

model.result('pg1').run;

model.study('std1').feature('eig').set('eigmethod', 'region');
model.study('std1').feature('eig').set('eigunit', 'Hz');
model.study('std1').feature('eig').set('eiglr', 1000);

model.sol('sol1').study('std1');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol2').copySolution('sol4');

model.result.dataset('dset2').set('solution', 'none');

model.study('std1').feature('stat').set('notlistsolnum', 1);
model.study('std1').feature('stat').set('notsolnum', 'auto');
model.study('std1').feature('stat').set('listsolnum', 1);
model.study('std1').feature('stat').set('solnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', 1);
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', 1);
model.study('std1').feature('eig').set('solnum', 'auto');

model.sol('sol1').feature.remove('e1');
model.sol('sol1').feature.remove('v2');
model.sol('sol1').feature.remove('st2');
model.sol('sol1').feature.remove('su1');
model.sol('sol1').feature.remove('s1');
model.sol('sol1').feature.remove('v1');
model.sol('sol1').feature.remove('st1');
model.sol('sol4').copySolution('sol2');
model.sol.remove('sol4');
model.sol('sol2').label('Solution Store 1');

model.result.dataset.remove('dset5');

model.sol('sol1').create('st1', 'StudyStep');
model.sol('sol1').feature('st1').set('study', 'std1');
model.sol('sol1').feature('st1').set('studystep', 'stat');
model.sol('sol1').create('v1', 'Variables');
model.sol('sol1').feature('v1').set('control', 'stat');
model.sol('sol1').create('s1', 'Stationary');
model.sol('sol1').feature('s1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('s1').create('seDef', 'Segregated');
model.sol('sol1').feature('s1').create('fc1', 'FullyCoupled');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'dDef');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature.remove('fcDef');
model.sol('sol1').feature('s1').feature.remove('seDef');
model.sol('sol1').create('su1', 'StoreSolution');
model.sol('sol1').feature('su1').set('sol', 'sol2');
model.sol('sol1').feature('su1').label('Solution Store 1');
model.sol('sol1').create('st2', 'StudyStep');
model.sol('sol1').feature('st2').set('study', 'std1');
model.sol('sol1').feature('st2').set('studystep', 'eig');
model.sol('sol1').create('v2', 'Variables');
model.sol('sol1').feature('v2').set('initmethod', 'sol');
model.sol('sol1').feature('v2').set('initsol', 'sol1');
model.sol('sol1').feature('v2').set('initsoluse', 'su1');
model.sol('sol1').feature('v2').set('notsolmethod', 'sol');
model.sol('sol1').feature('v2').set('notsol', 'sol1');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').create('e1', 'Eigenvalue');
model.sol('sol1').feature('e1').set('eigvfunscale', 'maximum');
model.sol('sol1').feature('e1').set('eigvfunscaleparam', '7.089999999999999E-9');
model.sol('sol1').feature('e1').set('storelinpoint', true);
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').set('linpmethod', 'sol');
model.sol('sol1').feature('e1').set('linpsol', 'sol1');
model.sol('sol1').feature('e1').set('linpsoluse', 'su1');
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').feature('aDef').set('cachepattern', true);

model.result.dataset('dset2').set('solution', 'sol2');

model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notsolvertype', 'solnum');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('control', 'eig');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol1').attach('std1');
model.sol('sol1').runAll;

model.result('pg1').run;
model.result('pg1').set('looplevel', [1]);
model.result('pg1').run;
model.result('pg1').set('looplevel', [2]);
model.result('pg1').run;
model.result('pg1').set('looplevel', [3]);
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').set('data', 'dset3');
model.result('pg1').run;
model.result('pg1').set('looplevel', [2]);
model.result('pg1').run;
model.result('pg1').set('looplevel', [3]);
model.result('pg1').run;
model.result('pg1').set('looplevel', [4]);
model.result('pg1').run;
model.result('pg1').set('looplevel', [1]);
model.result('pg1').run;
model.result('pg1').set('looplevel', [3]);
model.result('pg1').run;
model.result('pg1').set('looplevel', [5]);
model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').feature('surf2').set('data', 'parent');
model.result('pg1').run;
model.result('pg1').feature('surf1').set('data', 'parent');
model.result('pg1').run;
model.result('pg1').set('looplevel', [3]);
model.result('pg1').run;
model.result('pg1').set('data', 'dset1');
model.result('pg1').run;

model.sol('sol1').copySolution('sol4');

model.result.dataset('dset4').label('Loaded membrane stress 0 MPa');

model.label('sphere_on_square_membrane.mph');

model.component('comp1').physics('solid').feature('lemm1').set('rho_mat', 'userdef');
model.component('comp1').physics('solid').feature('lemm1').set('rho', '18500*1000');

model.result('pg1').run;

model.sol('sol1').study('std1');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol2').copySolution('sol5');

model.result.dataset('dset2').set('solution', 'none');

model.study('std1').feature('stat').set('notlistsolnum', 1);
model.study('std1').feature('stat').set('notsolnum', 'auto');
model.study('std1').feature('stat').set('listsolnum', 1);
model.study('std1').feature('stat').set('solnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', 1);
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', 1);
model.study('std1').feature('eig').set('solnum', 'auto');

model.sol('sol1').feature.remove('e1');
model.sol('sol1').feature.remove('v2');
model.sol('sol1').feature.remove('st2');
model.sol('sol1').feature.remove('su1');
model.sol('sol1').feature.remove('s1');
model.sol('sol1').feature.remove('v1');
model.sol('sol1').feature.remove('st1');
model.sol('sol5').copySolution('sol2');
model.sol.remove('sol5');
model.sol('sol2').label('Solution Store 1');

model.result.dataset.remove('dset6');

model.sol('sol1').create('st1', 'StudyStep');
model.sol('sol1').feature('st1').set('study', 'std1');
model.sol('sol1').feature('st1').set('studystep', 'stat');
model.sol('sol1').create('v1', 'Variables');
model.sol('sol1').feature('v1').set('control', 'stat');
model.sol('sol1').create('s1', 'Stationary');
model.sol('sol1').feature('s1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('s1').create('seDef', 'Segregated');
model.sol('sol1').feature('s1').create('fc1', 'FullyCoupled');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'dDef');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature.remove('fcDef');
model.sol('sol1').feature('s1').feature.remove('seDef');
model.sol('sol1').create('su1', 'StoreSolution');
model.sol('sol1').feature('su1').set('sol', 'sol2');
model.sol('sol1').feature('su1').label('Solution Store 1');
model.sol('sol1').create('st2', 'StudyStep');
model.sol('sol1').feature('st2').set('study', 'std1');
model.sol('sol1').feature('st2').set('studystep', 'eig');
model.sol('sol1').create('v2', 'Variables');
model.sol('sol1').feature('v2').set('initmethod', 'sol');
model.sol('sol1').feature('v2').set('initsol', 'sol1');
model.sol('sol1').feature('v2').set('initsoluse', 'su1');
model.sol('sol1').feature('v2').set('notsolmethod', 'sol');
model.sol('sol1').feature('v2').set('notsol', 'sol1');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').create('e1', 'Eigenvalue');
model.sol('sol1').feature('e1').set('eigvfunscale', 'maximum');
model.sol('sol1').feature('e1').set('eigvfunscaleparam', '7.089999999999999E-9');
model.sol('sol1').feature('e1').set('storelinpoint', true);
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').set('linpmethod', 'sol');
model.sol('sol1').feature('e1').set('linpsol', 'sol1');
model.sol('sol1').feature('e1').set('linpsoluse', 'su1');
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').feature('aDef').set('cachepattern', true);

model.result.dataset('dset2').set('solution', 'sol2');

model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notsolvertype', 'solnum');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('control', 'eig');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol1').attach('std1');

model.component('comp1').physics('solid').feature('lemm1').set('rho_mat', 'from_mat');
model.component('comp1').physics('solid').feature('gr1').set('g', {'0' '0' '-g_const*10'});

model.sol('sol1').study('std1');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol2').copySolution('sol5');

model.result.dataset('dset2').set('solution', 'none');

model.study('std1').feature('stat').set('notlistsolnum', 1);
model.study('std1').feature('stat').set('notsolnum', 'auto');
model.study('std1').feature('stat').set('listsolnum', 1);
model.study('std1').feature('stat').set('solnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', 1);
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', 1);
model.study('std1').feature('eig').set('solnum', 'auto');

model.sol('sol1').feature.remove('e1');
model.sol('sol1').feature.remove('v2');
model.sol('sol1').feature.remove('st2');
model.sol('sol1').feature.remove('su1');
model.sol('sol1').feature.remove('s1');
model.sol('sol1').feature.remove('v1');
model.sol('sol1').feature.remove('st1');
model.sol('sol5').copySolution('sol2');
model.sol.remove('sol5');
model.sol('sol2').label('Solution Store 1');

model.result.dataset.remove('dset6');

model.sol('sol1').create('st1', 'StudyStep');
model.sol('sol1').feature('st1').set('study', 'std1');
model.sol('sol1').feature('st1').set('studystep', 'stat');
model.sol('sol1').create('v1', 'Variables');
model.sol('sol1').feature('v1').set('control', 'stat');
model.sol('sol1').create('s1', 'Stationary');
model.sol('sol1').feature('s1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('s1').create('seDef', 'Segregated');
model.sol('sol1').feature('s1').create('fc1', 'FullyCoupled');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'dDef');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature.remove('fcDef');
model.sol('sol1').feature('s1').feature.remove('seDef');
model.sol('sol1').create('su1', 'StoreSolution');
model.sol('sol1').feature('su1').set('sol', 'sol2');
model.sol('sol1').feature('su1').label('Solution Store 1');
model.sol('sol1').create('st2', 'StudyStep');
model.sol('sol1').feature('st2').set('study', 'std1');
model.sol('sol1').feature('st2').set('studystep', 'eig');
model.sol('sol1').create('v2', 'Variables');
model.sol('sol1').feature('v2').set('initmethod', 'sol');
model.sol('sol1').feature('v2').set('initsol', 'sol1');
model.sol('sol1').feature('v2').set('initsoluse', 'su1');
model.sol('sol1').feature('v2').set('notsolmethod', 'sol');
model.sol('sol1').feature('v2').set('notsol', 'sol1');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').create('e1', 'Eigenvalue');
model.sol('sol1').feature('e1').set('eigvfunscale', 'maximum');
model.sol('sol1').feature('e1').set('eigvfunscaleparam', '7.089999999999999E-9');
model.sol('sol1').feature('e1').set('storelinpoint', true);
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').set('linpmethod', 'sol');
model.sol('sol1').feature('e1').set('linpsol', 'sol1');
model.sol('sol1').feature('e1').set('linpsoluse', 'su1');
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').feature('aDef').set('cachepattern', true);

model.result.dataset('dset2').set('solution', 'sol2');

model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notsolvertype', 'solnum');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('control', 'eig');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol1').attach('std1');

model.component('comp1').physics('solid').feature('gr1').set('g', {'0' '0' '-g_const'});

model.sol('sol1').study('std1');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol2').copySolution('sol5');

model.result.dataset('dset2').set('solution', 'none');

model.study('std1').feature('stat').set('notlistsolnum', 1);
model.study('std1').feature('stat').set('notsolnum', 'auto');
model.study('std1').feature('stat').set('listsolnum', 1);
model.study('std1').feature('stat').set('solnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', 1);
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', 1);
model.study('std1').feature('eig').set('solnum', 'auto');

model.sol('sol1').feature.remove('e1');
model.sol('sol1').feature.remove('v2');
model.sol('sol1').feature.remove('st2');
model.sol('sol1').feature.remove('su1');
model.sol('sol1').feature.remove('s1');
model.sol('sol1').feature.remove('v1');
model.sol('sol1').feature.remove('st1');
model.sol('sol5').copySolution('sol2');
model.sol.remove('sol5');
model.sol('sol2').label('Solution Store 1');

model.result.dataset.remove('dset6');

model.sol('sol1').create('st1', 'StudyStep');
model.sol('sol1').feature('st1').set('study', 'std1');
model.sol('sol1').feature('st1').set('studystep', 'stat');
model.sol('sol1').create('v1', 'Variables');
model.sol('sol1').feature('v1').set('control', 'stat');
model.sol('sol1').create('s1', 'Stationary');
model.sol('sol1').feature('s1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('s1').create('seDef', 'Segregated');
model.sol('sol1').feature('s1').create('fc1', 'FullyCoupled');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'dDef');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature.remove('fcDef');
model.sol('sol1').feature('s1').feature.remove('seDef');
model.sol('sol1').create('su1', 'StoreSolution');
model.sol('sol1').feature('su1').set('sol', 'sol2');
model.sol('sol1').feature('su1').label('Solution Store 1');
model.sol('sol1').create('st2', 'StudyStep');
model.sol('sol1').feature('st2').set('study', 'std1');
model.sol('sol1').feature('st2').set('studystep', 'eig');
model.sol('sol1').create('v2', 'Variables');
model.sol('sol1').feature('v2').set('initmethod', 'sol');
model.sol('sol1').feature('v2').set('initsol', 'sol1');
model.sol('sol1').feature('v2').set('initsoluse', 'su1');
model.sol('sol1').feature('v2').set('notsolmethod', 'sol');
model.sol('sol1').feature('v2').set('notsol', 'sol1');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').create('e1', 'Eigenvalue');
model.sol('sol1').feature('e1').set('eigvfunscale', 'maximum');
model.sol('sol1').feature('e1').set('eigvfunscaleparam', '7.089999999999999E-9');
model.sol('sol1').feature('e1').set('storelinpoint', true);
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').set('linpmethod', 'sol');
model.sol('sol1').feature('e1').set('linpsol', 'sol1');
model.sol('sol1').feature('e1').set('linpsoluse', 'su1');
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').feature('aDef').set('cachepattern', true);

model.result.dataset('dset2').set('solution', 'sol2');

model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notsolvertype', 'solnum');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('control', 'eig');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol1').attach('std1');
model.sol('sol1').runAll;

model.result('pg1').run;

model.component('comp1').physics('solid').feature('gr1').set('g', {'0' '0' '-g_const*5'});

model.sol('sol1').study('std1');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol2').copySolution('sol5');

model.result.dataset('dset2').set('solution', 'none');

model.study('std1').feature('stat').set('notlistsolnum', 1);
model.study('std1').feature('stat').set('notsolnum', 'auto');
model.study('std1').feature('stat').set('listsolnum', 1);
model.study('std1').feature('stat').set('solnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', 1);
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', 1);
model.study('std1').feature('eig').set('solnum', 'auto');

model.sol('sol1').feature.remove('e1');
model.sol('sol1').feature.remove('v2');
model.sol('sol1').feature.remove('st2');
model.sol('sol1').feature.remove('su1');
model.sol('sol1').feature.remove('s1');
model.sol('sol1').feature.remove('v1');
model.sol('sol1').feature.remove('st1');
model.sol('sol5').copySolution('sol2');
model.sol.remove('sol5');
model.sol('sol2').label('Solution Store 1');

model.result.dataset.remove('dset6');

model.sol('sol1').create('st1', 'StudyStep');
model.sol('sol1').feature('st1').set('study', 'std1');
model.sol('sol1').feature('st1').set('studystep', 'stat');
model.sol('sol1').create('v1', 'Variables');
model.sol('sol1').feature('v1').set('control', 'stat');
model.sol('sol1').create('s1', 'Stationary');
model.sol('sol1').feature('s1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('s1').create('seDef', 'Segregated');
model.sol('sol1').feature('s1').create('fc1', 'FullyCoupled');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'dDef');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature.remove('fcDef');
model.sol('sol1').feature('s1').feature.remove('seDef');
model.sol('sol1').create('su1', 'StoreSolution');
model.sol('sol1').feature('su1').set('sol', 'sol2');
model.sol('sol1').feature('su1').label('Solution Store 1');
model.sol('sol1').create('st2', 'StudyStep');
model.sol('sol1').feature('st2').set('study', 'std1');
model.sol('sol1').feature('st2').set('studystep', 'eig');
model.sol('sol1').create('v2', 'Variables');
model.sol('sol1').feature('v2').set('initmethod', 'sol');
model.sol('sol1').feature('v2').set('initsol', 'sol1');
model.sol('sol1').feature('v2').set('initsoluse', 'su1');
model.sol('sol1').feature('v2').set('notsolmethod', 'sol');
model.sol('sol1').feature('v2').set('notsol', 'sol1');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').create('e1', 'Eigenvalue');
model.sol('sol1').feature('e1').set('eigvfunscale', 'maximum');
model.sol('sol1').feature('e1').set('eigvfunscaleparam', '7.089999999999999E-9');
model.sol('sol1').feature('e1').set('storelinpoint', true);
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').set('linpmethod', 'sol');
model.sol('sol1').feature('e1').set('linpsol', 'sol1');
model.sol('sol1').feature('e1').set('linpsoluse', 'su1');
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').feature('aDef').set('cachepattern', true);

model.result.dataset('dset2').set('solution', 'sol2');

model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notsolvertype', 'solnum');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('control', 'eig');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol1').attach('std1');

model.result('pg1').run;
model.result('pg1').set('data', 'dset1');

model.component('comp1').physics('solid').feature('gr1').set('g', {'0' '0' '-g_const*1000'});

model.study('std1').feature('eig').set('eiglr', 1);
model.study('std1').feature('eig').set('eigunit', 'kHz');
model.study('std1').feature('eig').set('eiglr', 200);
model.study('std1').feature('eig').set('eigsr', 50);
model.study('std1').feature('eig').set('maxnreigs', 2000);
model.study('std1').feature('eig').set('appnreigs', 200);

model.sol('sol1').study('std1');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol2').copySolution('sol5');

model.result.dataset('dset2').set('solution', 'none');

model.study('std1').feature('stat').set('notlistsolnum', 1);
model.study('std1').feature('stat').set('notsolnum', 'auto');
model.study('std1').feature('stat').set('listsolnum', 1);
model.study('std1').feature('stat').set('solnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', 1);
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', 1);
model.study('std1').feature('eig').set('solnum', 'auto');

model.sol('sol1').feature.remove('e1');
model.sol('sol1').feature.remove('v2');
model.sol('sol1').feature.remove('st2');
model.sol('sol1').feature.remove('su1');
model.sol('sol1').feature.remove('s1');
model.sol('sol1').feature.remove('v1');
model.sol('sol1').feature.remove('st1');
model.sol('sol5').copySolution('sol2');
model.sol.remove('sol5');
model.sol('sol2').label('Solution Store 1');

model.result.dataset.remove('dset6');

model.sol('sol1').create('st1', 'StudyStep');
model.sol('sol1').feature('st1').set('study', 'std1');
model.sol('sol1').feature('st1').set('studystep', 'stat');
model.sol('sol1').create('v1', 'Variables');
model.sol('sol1').feature('v1').set('control', 'stat');
model.sol('sol1').create('s1', 'Stationary');
model.sol('sol1').feature('s1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('s1').create('seDef', 'Segregated');
model.sol('sol1').feature('s1').create('fc1', 'FullyCoupled');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'dDef');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature.remove('fcDef');
model.sol('sol1').feature('s1').feature.remove('seDef');
model.sol('sol1').create('su1', 'StoreSolution');
model.sol('sol1').feature('su1').set('sol', 'sol2');
model.sol('sol1').feature('su1').label('Solution Store 1');
model.sol('sol1').create('st2', 'StudyStep');
model.sol('sol1').feature('st2').set('study', 'std1');
model.sol('sol1').feature('st2').set('studystep', 'eig');
model.sol('sol1').create('v2', 'Variables');
model.sol('sol1').feature('v2').set('initmethod', 'sol');
model.sol('sol1').feature('v2').set('initsol', 'sol1');
model.sol('sol1').feature('v2').set('initsoluse', 'su1');
model.sol('sol1').feature('v2').set('notsolmethod', 'sol');
model.sol('sol1').feature('v2').set('notsol', 'sol1');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').create('e1', 'Eigenvalue');
model.sol('sol1').feature('e1').set('eigvfunscale', 'maximum');
model.sol('sol1').feature('e1').set('eigvfunscaleparam', '7.089999999999999E-9');
model.sol('sol1').feature('e1').set('storelinpoint', true);
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').set('linpmethod', 'sol');
model.sol('sol1').feature('e1').set('linpsol', 'sol1');
model.sol('sol1').feature('e1').set('linpsoluse', 'su1');
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').feature('aDef').set('cachepattern', true);

model.result.dataset('dset2').set('solution', 'sol2');

model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notsolvertype', 'solnum');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('control', 'eig');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol1').attach('std1');

model.component('comp1').physics('solid').feature('gr1').set('g', {'0' '0' '-g_const*8'});

model.study('std1').feature('eig').set('eigsr', 5);
model.study('std1').feature('eig').set('eiglr', 20);

model.sol('sol1').study('std1');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol2').copySolution('sol5');

model.result.dataset('dset2').set('solution', 'none');

model.study('std1').feature('stat').set('notlistsolnum', 1);
model.study('std1').feature('stat').set('notsolnum', 'auto');
model.study('std1').feature('stat').set('listsolnum', 1);
model.study('std1').feature('stat').set('solnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', 1);
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', 1);
model.study('std1').feature('eig').set('solnum', 'auto');

model.sol('sol1').feature.remove('e1');
model.sol('sol1').feature.remove('v2');
model.sol('sol1').feature.remove('st2');
model.sol('sol1').feature.remove('su1');
model.sol('sol1').feature.remove('s1');
model.sol('sol1').feature.remove('v1');
model.sol('sol1').feature.remove('st1');
model.sol('sol5').copySolution('sol2');
model.sol.remove('sol5');
model.sol('sol2').label('Solution Store 1');

model.result.dataset.remove('dset6');

model.sol('sol1').create('st1', 'StudyStep');
model.sol('sol1').feature('st1').set('study', 'std1');
model.sol('sol1').feature('st1').set('studystep', 'stat');
model.sol('sol1').create('v1', 'Variables');
model.sol('sol1').feature('v1').set('control', 'stat');
model.sol('sol1').create('s1', 'Stationary');
model.sol('sol1').feature('s1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('s1').create('seDef', 'Segregated');
model.sol('sol1').feature('s1').create('fc1', 'FullyCoupled');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'dDef');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature.remove('fcDef');
model.sol('sol1').feature('s1').feature.remove('seDef');
model.sol('sol1').create('su1', 'StoreSolution');
model.sol('sol1').feature('su1').set('sol', 'sol2');
model.sol('sol1').feature('su1').label('Solution Store 1');
model.sol('sol1').create('st2', 'StudyStep');
model.sol('sol1').feature('st2').set('study', 'std1');
model.sol('sol1').feature('st2').set('studystep', 'eig');
model.sol('sol1').create('v2', 'Variables');
model.sol('sol1').feature('v2').set('initmethod', 'sol');
model.sol('sol1').feature('v2').set('initsol', 'sol1');
model.sol('sol1').feature('v2').set('initsoluse', 'su1');
model.sol('sol1').feature('v2').set('notsolmethod', 'sol');
model.sol('sol1').feature('v2').set('notsol', 'sol1');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').create('e1', 'Eigenvalue');
model.sol('sol1').feature('e1').set('eigvfunscale', 'maximum');
model.sol('sol1').feature('e1').set('eigvfunscaleparam', '7.089999999999999E-9');
model.sol('sol1').feature('e1').set('storelinpoint', true);
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').set('linpmethod', 'sol');
model.sol('sol1').feature('e1').set('linpsol', 'sol1');
model.sol('sol1').feature('e1').set('linpsoluse', 'su1');
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').feature('aDef').set('cachepattern', true);

model.result.dataset('dset2').set('solution', 'sol2');

model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notsolvertype', 'solnum');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('control', 'eig');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol1').attach('std1');

model.component('comp1').physics('solid').feature('gr1').set('g', {'0' '0' '-g_const'});

model.study('std1').feature('eig').set('eigunit', 'Hz');
model.study('std1').feature('eig').set('eiglr', 1000);

model.sol('sol1').study('std1');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol2').copySolution('sol5');

model.result.dataset('dset2').set('solution', 'none');

model.study('std1').feature('stat').set('notlistsolnum', 1);
model.study('std1').feature('stat').set('notsolnum', 'auto');
model.study('std1').feature('stat').set('listsolnum', 1);
model.study('std1').feature('stat').set('solnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', 1);
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', 1);
model.study('std1').feature('eig').set('solnum', 'auto');

model.sol('sol1').feature.remove('e1');
model.sol('sol1').feature.remove('v2');
model.sol('sol1').feature.remove('st2');
model.sol('sol1').feature.remove('su1');
model.sol('sol1').feature.remove('s1');
model.sol('sol1').feature.remove('v1');
model.sol('sol1').feature.remove('st1');
model.sol('sol5').copySolution('sol2');
model.sol.remove('sol5');
model.sol('sol2').label('Solution Store 1');

model.result.dataset.remove('dset6');

model.sol('sol1').create('st1', 'StudyStep');
model.sol('sol1').feature('st1').set('study', 'std1');
model.sol('sol1').feature('st1').set('studystep', 'stat');
model.sol('sol1').create('v1', 'Variables');
model.sol('sol1').feature('v1').set('control', 'stat');
model.sol('sol1').create('s1', 'Stationary');
model.sol('sol1').feature('s1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('s1').create('seDef', 'Segregated');
model.sol('sol1').feature('s1').create('fc1', 'FullyCoupled');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'dDef');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature.remove('fcDef');
model.sol('sol1').feature('s1').feature.remove('seDef');
model.sol('sol1').create('su1', 'StoreSolution');
model.sol('sol1').feature('su1').set('sol', 'sol2');
model.sol('sol1').feature('su1').label('Solution Store 1');
model.sol('sol1').create('st2', 'StudyStep');
model.sol('sol1').feature('st2').set('study', 'std1');
model.sol('sol1').feature('st2').set('studystep', 'eig');
model.sol('sol1').create('v2', 'Variables');
model.sol('sol1').feature('v2').set('initmethod', 'sol');
model.sol('sol1').feature('v2').set('initsol', 'sol1');
model.sol('sol1').feature('v2').set('initsoluse', 'su1');
model.sol('sol1').feature('v2').set('notsolmethod', 'sol');
model.sol('sol1').feature('v2').set('notsol', 'sol1');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').create('e1', 'Eigenvalue');
model.sol('sol1').feature('e1').set('eigvfunscale', 'maximum');
model.sol('sol1').feature('e1').set('eigvfunscaleparam', '7.089999999999999E-9');
model.sol('sol1').feature('e1').set('storelinpoint', true);
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').set('linpmethod', 'sol');
model.sol('sol1').feature('e1').set('linpsol', 'sol1');
model.sol('sol1').feature('e1').set('linpsoluse', 'su1');
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').feature('aDef').set('cachepattern', true);

model.result.dataset('dset2').set('solution', 'sol2');

model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notsolvertype', 'solnum');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('control', 'eig');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol1').attach('std1');
model.sol('sol1').runAll;

model.result('pg1').run;
model.result('pg1').run;
model.result('pg1').set('looplevel', [3]);
model.result('pg1').run;
model.result.create('pg5', 'PlotGroup2D');
model.result('pg5').run;
model.result('pg5').create('surf1', 'Surface');
model.result('pg5').feature('surf1').create('def1', 'Deform');
model.result('pg5').run;
model.result('pg5').run;
model.result('pg5').run;
model.result.remove('pg5');
model.result('pg1').run;
model.result('pg1').set('data', 'dset4');

model.label('square_membrane.mph');

model.result('pg1').run;

model.component('comp1').physics.remove('solid');

model.component('comp1').multiphysics.remove('sshc1');

model.component('comp1').mesh('mesh1').run;

model.component('comp1').geom('geom1').feature.remove('sph1');
model.component('comp1').geom('geom1').feature.remove('int1');
model.component('comp1').geom('geom1').feature.remove('pard1');
model.component('comp1').geom('geom1').feature.remove('del1');
model.component('comp1').geom('geom1').run;

model.component('comp1').mesh('mesh1').run;

model.param.set('sigma', '2e5');

model.sol('sol1').study('std1');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol2').copySolution('sol5');

model.result.dataset('dset2').set('solution', 'none');

model.study('std1').feature('stat').set('notlistsolnum', 1);
model.study('std1').feature('stat').set('notsolnum', 'auto');
model.study('std1').feature('stat').set('listsolnum', 1);
model.study('std1').feature('stat').set('solnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', 1);
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', 1);
model.study('std1').feature('eig').set('solnum', 'auto');

model.sol('sol1').feature.remove('e1');
model.sol('sol1').feature.remove('v2');
model.sol('sol1').feature.remove('st2');
model.sol('sol1').feature.remove('su1');
model.sol('sol1').feature.remove('s1');
model.sol('sol1').feature.remove('v1');
model.sol('sol1').feature.remove('st1');
model.sol('sol5').copySolution('sol2');
model.sol.remove('sol5');
model.sol('sol2').label('Solution Store 1');

model.result.dataset.remove('dset6');

model.sol('sol1').create('st1', 'StudyStep');
model.sol('sol1').feature('st1').set('study', 'std1');
model.sol('sol1').feature('st1').set('studystep', 'stat');
model.sol('sol1').create('v1', 'Variables');
model.sol('sol1').feature('v1').set('control', 'stat');
model.sol('sol1').create('s1', 'Stationary');
model.sol('sol1').feature('s1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('s1').create('fc1', 'FullyCoupled');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'dDef');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature.remove('fcDef');
model.sol('sol1').create('su1', 'StoreSolution');
model.sol('sol1').feature('su1').set('sol', 'sol2');
model.sol('sol1').feature('su1').label('Solution Store 1');
model.sol('sol1').create('st2', 'StudyStep');
model.sol('sol1').feature('st2').set('study', 'std1');
model.sol('sol1').feature('st2').set('studystep', 'eig');
model.sol('sol1').create('v2', 'Variables');
model.sol('sol1').feature('v2').set('initmethod', 'sol');
model.sol('sol1').feature('v2').set('initsol', 'sol1');
model.sol('sol1').feature('v2').set('initsoluse', 'su1');
model.sol('sol1').feature('v2').set('notsolmethod', 'sol');
model.sol('sol1').feature('v2').set('notsol', 'sol1');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').create('e1', 'Eigenvalue');
model.sol('sol1').feature('e1').set('eigvfunscale', 'maximum');
model.sol('sol1').feature('e1').set('eigvfunscaleparam', '7.07E-9');
model.sol('sol1').feature('e1').set('storelinpoint', true);
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').set('linpmethod', 'sol');
model.sol('sol1').feature('e1').set('linpsol', 'sol1');
model.sol('sol1').feature('e1').set('linpsoluse', 'su1');
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').feature('aDef').set('cachepattern', true);

model.result.dataset('dset2').set('solution', 'sol2');

model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notsolvertype', 'solnum');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('control', 'eig');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol1').attach('std1');

model.study('std1').feature('eig').set('eiglr', 5000);
model.study('std1').feature('eig').set('eigsr', 100);

model.sol('sol1').study('std1');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol2').copySolution('sol5');

model.result.dataset('dset2').set('solution', 'none');

model.study('std1').feature('stat').set('notlistsolnum', 1);
model.study('std1').feature('stat').set('notsolnum', 'auto');
model.study('std1').feature('stat').set('listsolnum', 1);
model.study('std1').feature('stat').set('solnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', 1);
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', 1);
model.study('std1').feature('eig').set('solnum', 'auto');

model.sol('sol1').feature.remove('e1');
model.sol('sol1').feature.remove('v2');
model.sol('sol1').feature.remove('st2');
model.sol('sol1').feature.remove('su1');
model.sol('sol1').feature.remove('s1');
model.sol('sol1').feature.remove('v1');
model.sol('sol1').feature.remove('st1');
model.sol('sol5').copySolution('sol2');
model.sol.remove('sol5');
model.sol('sol2').label('Solution Store 1');

model.result.dataset.remove('dset6');

model.sol('sol1').create('st1', 'StudyStep');
model.sol('sol1').feature('st1').set('study', 'std1');
model.sol('sol1').feature('st1').set('studystep', 'stat');
model.sol('sol1').create('v1', 'Variables');
model.sol('sol1').feature('v1').set('control', 'stat');
model.sol('sol1').create('s1', 'Stationary');
model.sol('sol1').feature('s1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('s1').create('fc1', 'FullyCoupled');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'dDef');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature.remove('fcDef');
model.sol('sol1').create('su1', 'StoreSolution');
model.sol('sol1').feature('su1').set('sol', 'sol2');
model.sol('sol1').feature('su1').label('Solution Store 1');
model.sol('sol1').create('st2', 'StudyStep');
model.sol('sol1').feature('st2').set('study', 'std1');
model.sol('sol1').feature('st2').set('studystep', 'eig');
model.sol('sol1').create('v2', 'Variables');
model.sol('sol1').feature('v2').set('initmethod', 'sol');
model.sol('sol1').feature('v2').set('initsol', 'sol1');
model.sol('sol1').feature('v2').set('initsoluse', 'su1');
model.sol('sol1').feature('v2').set('notsolmethod', 'sol');
model.sol('sol1').feature('v2').set('notsol', 'sol1');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').create('e1', 'Eigenvalue');
model.sol('sol1').feature('e1').set('eigvfunscale', 'maximum');
model.sol('sol1').feature('e1').set('eigvfunscaleparam', '7.07E-9');
model.sol('sol1').feature('e1').set('storelinpoint', true);
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').set('linpmethod', 'sol');
model.sol('sol1').feature('e1').set('linpsol', 'sol1');
model.sol('sol1').feature('e1').set('linpsoluse', 'su1');
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').feature('aDef').set('cachepattern', true);

model.result.dataset('dset2').set('solution', 'sol2');

model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notsolvertype', 'solnum');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('control', 'eig');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol1').attach('std1');
model.sol('sol1').runAll;

model.result('pg4').run;
model.result('pg1').run;
model.result('pg1').set('data', 'dset1');
model.result('pg1').run;

model.param.set('sigma', '1e5');

model.study('std1').feature('eig').set('maxnreigs', 1000);

model.sol('sol1').study('std1');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol2').copySolution('sol5');

model.result.dataset('dset2').set('solution', 'none');

model.study('std1').feature('stat').set('notlistsolnum', 1);
model.study('std1').feature('stat').set('notsolnum', 'auto');
model.study('std1').feature('stat').set('listsolnum', 1);
model.study('std1').feature('stat').set('solnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', 1);
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', 1);
model.study('std1').feature('eig').set('solnum', 'auto');

model.sol('sol1').feature.remove('e1');
model.sol('sol1').feature.remove('v2');
model.sol('sol1').feature.remove('st2');
model.sol('sol1').feature.remove('su1');
model.sol('sol1').feature.remove('s1');
model.sol('sol1').feature.remove('v1');
model.sol('sol1').feature.remove('st1');
model.sol('sol5').copySolution('sol2');
model.sol.remove('sol5');
model.sol('sol2').label('Solution Store 1');

model.result.dataset.remove('dset6');

model.sol('sol1').create('st1', 'StudyStep');
model.sol('sol1').feature('st1').set('study', 'std1');
model.sol('sol1').feature('st1').set('studystep', 'stat');
model.sol('sol1').create('v1', 'Variables');
model.sol('sol1').feature('v1').set('control', 'stat');
model.sol('sol1').create('s1', 'Stationary');
model.sol('sol1').feature('s1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('s1').create('fc1', 'FullyCoupled');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'dDef');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature.remove('fcDef');
model.sol('sol1').create('su1', 'StoreSolution');
model.sol('sol1').feature('su1').set('sol', 'sol2');
model.sol('sol1').feature('su1').label('Solution Store 1');
model.sol('sol1').create('st2', 'StudyStep');
model.sol('sol1').feature('st2').set('study', 'std1');
model.sol('sol1').feature('st2').set('studystep', 'eig');
model.sol('sol1').create('v2', 'Variables');
model.sol('sol1').feature('v2').set('initmethod', 'sol');
model.sol('sol1').feature('v2').set('initsol', 'sol1');
model.sol('sol1').feature('v2').set('initsoluse', 'su1');
model.sol('sol1').feature('v2').set('notsolmethod', 'sol');
model.sol('sol1').feature('v2').set('notsol', 'sol1');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').create('e1', 'Eigenvalue');
model.sol('sol1').feature('e1').set('eigvfunscale', 'maximum');
model.sol('sol1').feature('e1').set('eigvfunscaleparam', '7.07E-9');
model.sol('sol1').feature('e1').set('storelinpoint', true);
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').set('linpmethod', 'sol');
model.sol('sol1').feature('e1').set('linpsol', 'sol1');
model.sol('sol1').feature('e1').set('linpsoluse', 'su1');
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').feature('aDef').set('cachepattern', true);

model.result.dataset('dset2').set('solution', 'sol2');

model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notsolvertype', 'solnum');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('control', 'eig');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol1').attach('std1');
model.sol('sol1').runAll;

model.param.set('sigma', '3e4');

model.sol('sol1').study('std1');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol2').copySolution('sol5');

model.result.dataset('dset2').set('solution', 'none');

model.study('std1').feature('stat').set('notlistsolnum', 1);
model.study('std1').feature('stat').set('notsolnum', 'auto');
model.study('std1').feature('stat').set('listsolnum', 1);
model.study('std1').feature('stat').set('solnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', 1);
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', 1);
model.study('std1').feature('eig').set('solnum', 'auto');

model.sol('sol1').feature.remove('e1');
model.sol('sol1').feature.remove('v2');
model.sol('sol1').feature.remove('st2');
model.sol('sol1').feature.remove('su1');
model.sol('sol1').feature.remove('s1');
model.sol('sol1').feature.remove('v1');
model.sol('sol1').feature.remove('st1');
model.sol('sol5').copySolution('sol2');
model.sol.remove('sol5');
model.sol('sol2').label('Solution Store 1');

model.result.dataset.remove('dset6');

model.sol('sol1').create('st1', 'StudyStep');
model.sol('sol1').feature('st1').set('study', 'std1');
model.sol('sol1').feature('st1').set('studystep', 'stat');
model.sol('sol1').create('v1', 'Variables');
model.sol('sol1').feature('v1').set('control', 'stat');
model.sol('sol1').create('s1', 'Stationary');
model.sol('sol1').feature('s1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('s1').create('fc1', 'FullyCoupled');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'dDef');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature.remove('fcDef');
model.sol('sol1').create('su1', 'StoreSolution');
model.sol('sol1').feature('su1').set('sol', 'sol2');
model.sol('sol1').feature('su1').label('Solution Store 1');
model.sol('sol1').create('st2', 'StudyStep');
model.sol('sol1').feature('st2').set('study', 'std1');
model.sol('sol1').feature('st2').set('studystep', 'eig');
model.sol('sol1').create('v2', 'Variables');
model.sol('sol1').feature('v2').set('initmethod', 'sol');
model.sol('sol1').feature('v2').set('initsol', 'sol1');
model.sol('sol1').feature('v2').set('initsoluse', 'su1');
model.sol('sol1').feature('v2').set('notsolmethod', 'sol');
model.sol('sol1').feature('v2').set('notsol', 'sol1');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').create('e1', 'Eigenvalue');
model.sol('sol1').feature('e1').set('eigvfunscale', 'maximum');
model.sol('sol1').feature('e1').set('eigvfunscaleparam', '7.07E-9');
model.sol('sol1').feature('e1').set('storelinpoint', true);
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').set('linpmethod', 'sol');
model.sol('sol1').feature('e1').set('linpsol', 'sol1');
model.sol('sol1').feature('e1').set('linpsoluse', 'su1');
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').feature('aDef').set('cachepattern', true);

model.result.dataset('dset2').set('solution', 'sol2');

model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notsolvertype', 'solnum');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('control', 'eig');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol1').attach('std1');
model.sol('sol1').runAll;

model.param.set('sigma', '1e4');

model.sol('sol1').study('std1');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol2').copySolution('sol5');

model.result.dataset('dset2').set('solution', 'none');

model.study('std1').feature('stat').set('notlistsolnum', 1);
model.study('std1').feature('stat').set('notsolnum', 'auto');
model.study('std1').feature('stat').set('listsolnum', 1);
model.study('std1').feature('stat').set('solnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', 1);
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', 1);
model.study('std1').feature('eig').set('solnum', 'auto');

model.sol('sol1').feature.remove('e1');
model.sol('sol1').feature.remove('v2');
model.sol('sol1').feature.remove('st2');
model.sol('sol1').feature.remove('su1');
model.sol('sol1').feature.remove('s1');
model.sol('sol1').feature.remove('v1');
model.sol('sol1').feature.remove('st1');
model.sol('sol5').copySolution('sol2');
model.sol.remove('sol5');
model.sol('sol2').label('Solution Store 1');

model.result.dataset.remove('dset6');

model.sol('sol1').create('st1', 'StudyStep');
model.sol('sol1').feature('st1').set('study', 'std1');
model.sol('sol1').feature('st1').set('studystep', 'stat');
model.sol('sol1').create('v1', 'Variables');
model.sol('sol1').feature('v1').set('control', 'stat');
model.sol('sol1').create('s1', 'Stationary');
model.sol('sol1').feature('s1').feature('aDef').set('cachepattern', true);
model.sol('sol1').feature('s1').create('fc1', 'FullyCoupled');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'dDef');
model.sol('sol1').feature('s1').feature('fc1').set('termonres', 'auto');
model.sol('sol1').feature('s1').feature('fc1').set('reserrfact', 1000);
model.sol('sol1').feature('s1').feature.remove('fcDef');
model.sol('sol1').create('su1', 'StoreSolution');
model.sol('sol1').feature('su1').set('sol', 'sol2');
model.sol('sol1').feature('su1').label('Solution Store 1');
model.sol('sol1').create('st2', 'StudyStep');
model.sol('sol1').feature('st2').set('study', 'std1');
model.sol('sol1').feature('st2').set('studystep', 'eig');
model.sol('sol1').create('v2', 'Variables');
model.sol('sol1').feature('v2').set('initmethod', 'sol');
model.sol('sol1').feature('v2').set('initsol', 'sol1');
model.sol('sol1').feature('v2').set('initsoluse', 'su1');
model.sol('sol1').feature('v2').set('notsolmethod', 'sol');
model.sol('sol1').feature('v2').set('notsol', 'sol1');
model.sol('sol1').feature('v2').set('control', 'eig');
model.sol('sol1').create('e1', 'Eigenvalue');
model.sol('sol1').feature('e1').set('eigvfunscale', 'maximum');
model.sol('sol1').feature('e1').set('eigvfunscaleparam', '7.07E-9');
model.sol('sol1').feature('e1').set('storelinpoint', true);
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').set('linpmethod', 'sol');
model.sol('sol1').feature('e1').set('linpsol', 'sol1');
model.sol('sol1').feature('e1').set('linpsoluse', 'su1');
model.sol('sol1').feature('e1').set('control', 'eig');
model.sol('sol1').feature('e1').feature('aDef').set('cachepattern', true);

model.result.dataset('dset2').set('solution', 'sol2');

model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notsolvertype', 'solnum');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('notlistsolnum', {'1'});
model.sol('sol1').feature('v2').set('notsolnum', 'auto');
model.sol('sol1').feature('v2').set('control', 'eig');

model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolvertype', 'solnum');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notlistsolnum', {'1'});
model.study('std1').feature('eig').set('notsolnum', 'auto');
model.study('std1').feature('eig').set('notsolnumhide', 'off');
model.study('std1').feature('eig').set('notstudyhide', 'off');
model.study('std1').feature('eig').set('notsolhide', 'off');
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solvertype', 'solnum');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('listsolnum', {'1'});
model.study('std1').feature('eig').set('solnum', 'auto');
model.study('std1').feature('eig').set('solnumhide', 'off');
model.study('std1').feature('eig').set('initstudyhide', 'off');
model.study('std1').feature('eig').set('initsolhide', 'off');

model.sol('sol1').attach('std1');
model.sol('sol1').runAll;

model.label('square_membrane.mph');

model.component('comp1').geom('geom1').run('fin');

model.component('comp1').mesh('mesh1').run;
model.component('comp1').mesh('mesh1').run;
model.component('comp1').mesh('mesh1').run;
model.component('comp1').mesh('mesh1').run;

out = model;
