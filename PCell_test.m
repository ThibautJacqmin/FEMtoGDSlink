warning('off');
gds_modeler = GDSModeler;
layer = gds_modeler.create_layer(0);
layout = gds_modeler.pylayout;
cell = gds_modeler.pycell;
pya = gds_modeler.pya;


% Test RoundPolygon cell
layer_info = pya.LayerInfo(1, 0);
layer_index = layout.layer(layer_info);
lib = pya.Library.library_by_name("Basic");
pcell = lib.layout().pcell_declaration("ROUND_POLYGON"); 
path_points = {pya.Point(0, 0), pya.Point(0, 1), pya.Point(1, 1), pya.Point(1, 0)};
pcell_params = py.dict(r=5, n=64, layer=layer_info, pts=path_points);
pcell_variant=layout.add_pcell_variant(lib, pcell.id(), pcell_params);
pcell_inst=cell.insert(gds_modeler.pya.CellInstArray(pcell_variant, gds_modeler.pya.Trans()));

gds_modeler.write("pcell_test.gds")