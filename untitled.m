function out = model
%
% untitled.m
%
% Model exported on Mar 21 2024, 15:51 by COMSOL 6.1.0.282.

import com.comsol.model.*
import com.comsol.model.util.*

model = ModelUtil.create('Model');

model.param.set('tether_length', '2000[nm]', 'length of tether');

model.component.create('Component', true);

model.component('Component').geom.create('Geometry', 2);

model.component('Component').mesh.create('mesh1');

model.component('Component').geom('Geometry').create('rect1', 'Rectangle');
model.component('Component').geom('Geometry').feature('rect1').set('pos', [-1782042.27757991 -999999.9999999999]);
model.component('Component').geom('Geometry').feature('rect1').set('size', [120000 1999999.9999999998]);
model.component('Component').geom('Geometry').create('pol1', 'Polygon');
model.component('Component').geom('Geometry').feature('pol1').set('x', '{-1607940,-1662042,-1662042,-1661247,-1660483,-1659750,-1659047,-1658373,-1657728,-1657110,-1656520,-1655955,-1655415,-1654899,-1654407,-1653938,-1653491,-1653065,-1652659,-1652272,-1651905,-1651555,-1651222,-1650905,-1650604,-1650317,-1650045,-1649785,-1649537,-1649301,-1649075,-1648859,-1648652,-1648453,-1648261,-1648076,-1647897,-1647722,-1647552,-1647384,-1647219,-1647056,-1646894,-1646731,-1646568,-1646403,-1646236,-1646065,-1645891,-1645711,-1645526,-1645334,-1645135,-1644928,-1644712,-1644487,-1644250,-1644003,-1643743,-1643470,-1643183,-1642882,-1642566,-1642233,-1641883,-1641515,-1641129,-1640723,-1640296,-1639849,-1639380,-1638888,-1638373,-1637833,-1637268,-1636677,-1636059,-1635414,-1634740,-1634037,-1633304,-1632541,-1631745,-1630917,-1630056,-1629161,-1628231,-1627265,-1626262,-1625223,-1624145,-1623028,-1621871,-1620674,-1619436,-1618155,-1616831,-1615464,-1614052,-1612594,-1611090,-1609539}');
model.component('Component').geom('Geometry').feature('pol1').set('y', '{-1000000,-1000000,-880000,-882682,-885328,-887939,-890514,-893054,-895558,-898028,-900463,-902864,-905230,-907562,-909860,-912124,-914354,-916551,-918715,-920845,-922943,-925008,-927040,-929040,-931007,-932943,-934847,-936719,-938559,-940368,-942147,-943894,-945610,-947296,-948951,-950576,-952171,-953736,-955272,-956778,-958254,-959702,-961120,-962510,-963871,-965203,-966508,-967784,-969032,-970253,-971446,-972611,-973750,-974862,-975946,-977004,-978036,-979041,-980020,-980974,-981901,-982803,-983680,-984531,-985358,-986159,-986936,-987689,-988417,-989121,-989801,-990457,-991090,-991699,-992285,-992849,-993389,-993906,-994401,-994874,-995325,-995753,-996160,-996545,-996909,-997252,-997573,-997874,-998154,-998413,-998652,-998871,-999070,-999249,-999409,-999549,-999670,-999771,-999854,-999918,-999964,-999991}');
model.component('Component').geom('Geometry').create('copy1', 'Copy');
model.component('Component').geom('Geometry').feature('copy1').selection('input').set({'pol1'});
model.component('Component').geom('Geometry').create('mir1', 'Mirror');
model.component('Component').geom('Geometry').feature('mir1').set('pos', [-1722042.27757991 0]);
model.component('Component').geom('Geometry').feature('mir1').set('axis', [1 0]);
model.component('Component').geom('Geometry').feature('mir1').selection('input').set({'copy1'});
model.component('Component').geom('Geometry').create('copy2', 'Copy');
model.component('Component').geom('Geometry').feature('copy2').selection('input').set({'pol1'});
model.component('Component').geom('Geometry').create('mir2', 'Mirror');
model.component('Component').geom('Geometry').feature('mir2').set('pos', [0 0]);
model.component('Component').geom('Geometry').feature('mir2').set('axis', [0 1]);
model.component('Component').geom('Geometry').feature('mir2').selection('input').set({'copy2'});
model.component('Component').geom('Geometry').create('copy3', 'Copy');
model.component('Component').geom('Geometry').feature('copy3').selection('input').set({'mir2'});
model.component('Component').geom('Geometry').create('mir3', 'Mirror');
model.component('Component').geom('Geometry').feature('mir3').set('pos', [-1722042.27757991 0]);
model.component('Component').geom('Geometry').feature('mir3').set('axis', [1 0]);
model.component('Component').geom('Geometry').feature('mir3').selection('input').set({'copy3'});
model.component('Component').geom('Geometry').run;
model.component('Component').geom('Geometry').run('fin');

model.component('Component').material.create('mat1', 'Common');
model.component('Component').material('mat1').propertyGroup.create('Enu', 'Young''s modulus and Poisson''s ratio');

model.component('Component').physics.create('solid', 'SolidMechanics', 'Geometry');
model.component('Component').physics('solid').field('displacement').field('u2');
model.component('Component').physics('solid').field('displacement').component({'u2' 'v2' 'w2'});
model.component('Component').physics('solid').create('fix1', 'Fixed', 1);
model.component('Component').physics('solid').feature('fix1').selection.set([2 4 204 207 209 214]);

model.component('Component').mesh('mesh1').create('ftri1', 'FreeTri');

model.component('Component').view('view1').axis.set('xmin', -2851229.5);
model.component('Component').view('view1').axis.set('xmax', -592854.75);
model.component('Component').view('view1').axis.set('ymin', -1100000);
model.component('Component').view('view1').axis.set('ymax', 1100000);

model.component('Component').material('mat1').label('Si3N4 - Silicon nitride');
model.component('Component').material('mat1').propertyGroup('def').set('density', '3200');
model.component('Component').material('mat1').propertyGroup('Enu').set('E', '2.5E11');
model.component('Component').material('mat1').propertyGroup('Enu').set('nu', '0.23');

model.component('Component').physics('solid').prop('d').set('d', '100[nm]');

model.component('Component').mesh('mesh1').run;

out = model;
