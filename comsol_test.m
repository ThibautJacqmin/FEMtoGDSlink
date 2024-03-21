c = ComsolModeler;
c.start_gui;
c.add_parameter('tether_length', 2000, 'nm', 'length of tether')


r = Box(left=0, right=2, top=5,bottom=0, comsol_modeler=comsol_modeler);


model.component("Component").geom("Geometry").create("pol1", "Polygon");

model.component("Component").geom("Geometry").create("pol1", "Polygon");
r= comsol_modeler.geometry.feature.create('rect2', 'Rectangle')
r.set('pos', [2.5, 7])  
r.set('size', [3, 8])



c.geometry.feature('rect1').set('base', 'center')
c.geometry.feature('rect1').set('size', [3, 2])   
r = c.geometry.feature('rect1');
r = comsol_modeler.geometry.create('rot33', 'Rotate')
c.geometry.run
mphgeom(c.model, 'Geometry')
model.component("Component").geom("Geometry").feature("pol1")
model.component("Component").geom("Geometry").feature("pol1")
model.component().create("Component");
model.geom().create("Geometry", 2);
model.component("Component").geom("Geometry").run();
model.component("Component").geom("Geometry").create("rect1", "Rectangle");
model.component("Component").geom("Geometry").feature("rect1").set("pos", new int[]{2, 7});
model.component("Component").geom("Geometry").feature("rect1").set("base", "center");
model.component("Component").geom("Geometry").feature("rect1").set("size", new int[]{3, 2});
model.component("Component").geom("Geometry").create("mov1", "Move");
model.component("Component").geom("Geometry").feature("mov1").setIndex("displx", "5", 0);
model.component("Component").geom("Geometry").feature("mov1").setIndex("disply", "8", 0);
model.component("Component").geom("Geometry").feature("mov1").selection("input").set("rect1");

