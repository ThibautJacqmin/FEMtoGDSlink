import core.*
import types.*
import primitives.*
import ops.*
import routing.*

% Example 5: routing showcase with visible triangular launch ports.
ctx = GeometrySession.with_shared_comsol(use_comsol=true, use_gds=true, ...
    comsol_api="mph", ...
    preview_klayout=true, preview_scope="final", preview_step_delay_s=0.08, ...
    snap_on_grid=false, gds_resolution_nm=1, warn_on_snap=true, ...
    reset_model=true, clean_on_reset=false);

ctx.add_layer("metal1", gds_layer=1, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="metal1", comsol_selection_state="all", emit_to_comsol=true);
ctx.add_layer("gap", gds_layer=2, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="gap", comsol_selection_state="all", emit_to_comsol=true);
ctx.add_layer("portmark", gds_layer=10, gds_datatype=0, comsol_workplane="wp1", ...
    comsol_selection="", comsol_selection_state="none", emit_to_comsol=false);

% Base unit helper (all geometry lengths in um).
p_um = Parameter(1, "u_ex5", unit="um");

% Common CPW-like cross sections.
cpw = PortSpec( ...
    widths={Parameter(14, "cpw_sig_w", unit="um"), Parameter(34, "cpw_gap_w", unit="um")}, ...
    offsets={0, 0}, ...
    layers=["metal1", "gap"], ...
    subnames=["sig", "gap"]);
cpw_masked = cpw.with_mask(layer="gap", gap=Parameter(8, "cpw_mask_gap", unit="um"), ...
    subname="mask");

%% Demo A: basic Manhattan auto bend + triangular launch markers.
pinA = PortRef(name="A_in", pos=Vertices([-320, -30], p_um), ori=[1, 0], spec=cpw);
poutA = PortRef(name="A_out", pos=Vertices([320, 50], p_um), ori=[-1, 0], spec=cpw);
pinA.draw_markers(ctx=ctx, layer="portmark");
poutA.draw_markers(ctx=ctx, layer="portmark");

cA = Cable(ctx, pinA, poutA, ...
    name="demoA", fillet=Parameter(24, "ex5_fillet_A", unit="um"), ...
    start_straight=Parameter(36, "ex5_straight_A", unit="um"), ...
    bend="auto", ends="straight", merge_per_layer=true);
fprintf("Demo A length: %.3f um\n", cA.length_nm() / 1000);

%% Demo B: explicit route points + circular end caps + no per-layer merge.
pinB = PortRef(name="B_in", pos=Vertices([-280, -230], p_um), ori=[1, 0], spec=cpw);
poutB = PortRef(name="B_out", pos=Vertices([280, -120], p_um), ori=[-1, 0], spec=cpw);
pinB.draw_markers(ctx=ctx, layer="portmark", tip_scale=0.4);
poutB.draw_markers(ctx=ctx, layer="portmark", tip_scale=0.4);

routeB = Route(points=[-280, -230; -80, -230; -80, -300; 180, -300; 180, -120; 280, -120], ...
    fillet=18);
cB = Cable(ctx, pinB, poutB, ...
    name="demoB", route=routeB, ends="circular", convexcorner="tangent", ...
    merge_per_layer=false);
fprintf("Demo B length: %.3f um\n", cB.length_nm() / 1000);

%% Demo C: split a two-track bus into two independent CPW ports and route both.
bus = PortSpec( ...
    widths={Parameter(16, "bus_w", unit="um"), Parameter(16, "bus_w2", unit="um")}, ...
    offsets={Parameter(-22, "bus_off_l", unit="um"), Parameter(22, "bus_off_r", unit="um")}, ...
    layers=["metal1", "metal1"], ...
    subnames=["left", "right"]);

pinC = PortRef(name="C_in", pos=Vertices([-330, 190], p_um), ori=[1, 0], spec=bus);
poutC = PortRef(name="C_out", pos=Vertices([330, 230], p_um), ori=[-1, 0], spec=bus);
pinC.draw_markers(ctx=ctx, layer="portmark");
poutC.draw_markers(ctx=ctx, layer="portmark");

split_in = pinC.split(gap=10, gap_layer="gap");
split_out = poutC.split(gap=10, gap_layer="gap");

cC_left = Cable(ctx, split_in{1}, split_out{1}, ...
    name="demoC_left", fillet=12, start_straight=24, bend="x_first");
cC_right = Cable(ctx, split_in{2}, split_out{2}, ...
    name="demoC_right", fillet=12, start_straight=24, bend="y_first");
fprintf("Demo C left length: %.3f um\n", cC_left.length_nm() / 1000);
fprintf("Demo C right length: %.3f um\n", cC_right.length_nm() / 1000);

%% Demo D: masked cross-section (signal + gap + outer mask track).
pinD = PortRef(name="D_in", pos=Vertices([-320, 120], p_um), ori=[1, 0], spec=cpw_masked);
poutD = PortRef(name="D_out", pos=Vertices([320, 120], p_um), ori=[-1, 0], spec=cpw_masked);
pinD.draw_markers(ctx=ctx, layer="portmark", tip_length=Parameter(8, "ex5_tip_D", unit="um"));
poutD.draw_markers(ctx=ctx, layer="portmark", tip_length=Parameter(8, "ex5_tip_D", unit="um"));

cD = Cable(ctx, pinD, poutD, ...
    name="demoD", fillet=20, start_straight=30, bend="auto", merge_per_layer=true);
fprintf("Demo D length: %.3f um\n", cD.length_nm() / 1000);

%% Demo E: meander-like route (explicit serpentine centerline points).
pinE = PortRef(name="E_in", pos=Vertices([-320, 330], p_um), ori=[1, 0], spec=cpw);
poutE = PortRef(name="E_out", pos=Vertices([320, 330], p_um), ori=[-1, 0], spec=cpw);
pinE.draw_markers(ctx=ctx, layer="portmark");
poutE.draw_markers(ctx=ctx, layer="portmark");

routeE = Route(points=[ ...
    -320, 330; -240, 330; ...
    -240, 255; -160, 255; ...
    -160, 405; -80, 405; ...
    -80, 255; 0, 255; ...
    0, 405; 80, 405; ...
    80, 255; 160, 255; ...
    160, 330; 320, 330], ...
    fillet=12);
cE = Cable(ctx, pinE, poutE, ...
    name="demoE_meander", route=routeE, ...
    ends="straight", convexcorner="tangent", merge_per_layer=true);
fprintf("Demo E (meander) length: %.3f um\n", cE.length_nm() / 1000);

%% Demo F: tapered CPW edge-launches + routed interconnect.
% Here tapers are explicit polygons from wide wirebond edge width to CPW width.
sig_narrow = cpw.width_value(1);
gap_narrow = cpw.width_value(2);
sig_wide = 95;
gap_wide = 160;

% Left edge taper (wide at x=-380 to narrow at x=-280).
draw_linear_taper(ctx, "metal1", -380, -280, -430, sig_wide, sig_narrow, p_um);
draw_linear_taper(ctx, "gap", -380, -280, -430, gap_wide, gap_narrow, p_um);

% Right edge taper (wide at x=380 to narrow at x=280).
draw_linear_taper(ctx, "metal1", 380, 280, -360, sig_wide, sig_narrow, p_um);
draw_linear_taper(ctx, "gap", 380, 280, -360, gap_wide, gap_narrow, p_um);

pinF = PortRef(name="F_in", pos=Vertices([-280, -430], p_um), ori=[1, 0], spec=cpw);
poutF = PortRef(name="F_out", pos=Vertices([280, -360], p_um), ori=[-1, 0], spec=cpw);
pinF.draw_markers(ctx=ctx, layer="portmark", tip_scale=0.5);
poutF.draw_markers(ctx=ctx, layer="portmark", tip_scale=0.5);

cF = Cable(ctx, pinF, poutF, ...
    name="demoF_tapered_launch", fillet=22, start_straight=28, bend="auto", ...
    ends="straight", merge_per_layer=true);
fprintf("Demo F (tapered launch) length: %.3f um\n", cF.length_nm() / 1000);

ctx.export_gds("example_5.gds");
ctx.build_comsol();
ctx.build_report();

function feat = draw_linear_taper(ctx, layer, x0, x1, yc, w0, w1, pref)
% Draw trapezoidal taper between widths w0 (at x0) and w1 (at x1).
verts = [
    x0, yc - 0.5 * w0;
    x0, yc + 0.5 * w0;
    x1, yc + 0.5 * w1;
    x1, yc - 0.5 * w1];
feat = primitives.Polygon(ctx, vertices=types.Vertices(verts, pref), layer=layer);
end
